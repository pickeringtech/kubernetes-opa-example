# Strict Enforcement Scenario

## Overview

The strict enforcement scenario demonstrates **zero-tolerance asset UUID requirements** in a Kubernetes cluster where all deployments, both new and existing, must comply with the policy immediately.

## Use Case

This scenario is ideal for:
- **New Kubernetes clusters** starting with clean slate
- **Highly regulated environments** requiring immediate compliance
- **Security-first organizations** where policy violations cannot be tolerated
- **Greenfield projects** where all applications can be designed to be compliant from day one

## Policy Configuration

### Enforcement Mode
- **Mode**: `strict`
- **Action**: `deny` (blocks non-compliant deployments)
- **Scope**: All deployments (new and existing)

### Key Features

1. **Zero Tolerance**
   - ALL deployments must have `assetUuid` label
   - No exceptions for existing deployments
   - Immediate enforcement upon policy deployment

2. **Admission Control**
   - Non-compliant deployments are rejected at admission time
   - Clear error messages guide developers to compliance
   - Prevents non-compliant resources from entering the cluster

3. **Limited Exclusions**
   - Emergency exclusions via `opa.example.com/exclude: "true"`
   - Maintenance windows via time-based exclusions
   - Should be used sparingly and with proper justification

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Strict Enforcement                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │  Any App        │    │   Compliant App │                │
│  │  (No assetUuid) │    │  (assetUuid)    │                │
│  │  ❌ REJECTED    │    │  ✅ ALLOWED     │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           └───────────┬───────────┘                        │
│                       │                                    │
│              ┌─────────▼─────────┐                         │
│              │  OPA Gatekeeper   │                         │
│              │  (Strict Policy)  │                         │
│              └───────────────────┘                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Examples

### Compliant Deployment (Allowed)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliant-app
  labels:
    assetUuid: "asset-12345-abcde"  # REQUIRED!
spec:
  replicas: 1
  selector:
    matchLabels:
      app: compliant-app
  template:
    metadata:
      labels:
        app: compliant-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

### Non-Compliant Deployment (Rejected)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: non-compliant-app
  # Missing assetUuid label - will be REJECTED
spec:
  replicas: 1
  selector:
    matchLabels:
      app: non-compliant-app
  template:
    metadata:
      labels:
        app: non-compliant-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
```

**Result**: 
```
Error from server: admission webhook "validation.gatekeeper.sh" denied the request: 
[deployment-asset-uuid-strict] Deployment 'non-compliant-app' in namespace 'default' must have an 'assetUuid' label
```

### Emergency Exclusion (Use Sparingly)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: emergency-app
  annotations:
    opa.example.com/exclude: "true"  # Emergency bypass
    justification: "Critical security patch deployment - ticket #SEC-2024-001"
  # Note: Still recommended to include assetUuid even with exclusion
spec:
  # ... deployment specification
```

### Maintenance Window Exclusion
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maintenance-app
  annotations:
    opa.example.com/exclude-until: "2024-01-15T10:00:00Z"
    justification: "Scheduled maintenance window for legacy system migration"
  labels:
    assetUuid: "asset-maintenance-123"  # Will be required after exclusion expires
spec:
  # ... deployment specification
```

## Testing the Policy

### 1. Test Compliant Deployment (Should Succeed)
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-compliant
  namespace: opa-strict-demo
  labels:
    assetUuid: "asset-test-compliant-123"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-compliant
  template:
    metadata:
      labels:
        app: test-compliant
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF
```

### 2. Test Non-Compliant Deployment (Should Fail)
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-non-compliant
  namespace: opa-strict-demo
  # Note: Missing assetUuid label
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-non-compliant
  template:
    metadata:
      labels:
        app: test-non-compliant
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF
```

**Expected Error**:
```
Error from server: admission webhook "validation.gatekeeper.sh" denied the request: 
[deployment-asset-uuid-strict] Deployment 'test-non-compliant' in namespace 'opa-strict-demo' must have an 'assetUuid' label
```

### 3. Test Emergency Exclusion (Should Succeed)
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-emergency
  namespace: opa-strict-demo
  annotations:
    opa.example.com/exclude: "true"
    justification: "Testing emergency exclusion mechanism"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: test-emergency
  template:
    metadata:
      labels:
        app: test-emergency
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF
```

## Monitoring and Compliance

### Compliance Verification
```bash
# Check all deployments for assetUuid compliance
kubectl get deployments -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.metadata.labels.assetUuid}{"\n"}{end}' | grep -E '\t\t$' || echo "All deployments are compliant!"

# List deployments with exclusions
kubectl get deployments -A -o json | jq -r '.items[] | select(.metadata.annotations["opa.example.com/exclude"] == "true" or .metadata.annotations["opa.example.com/exclude-until"] != null) | "\(.metadata.namespace)\t\(.metadata.name)\tEXCLUDED"'

# Check constraint status
kubectl get assetuuidrequired deployment-asset-uuid-strict -o yaml
```

### Audit and Reporting
```bash
# Generate compliance report
echo "=== Asset UUID Compliance Report ==="
echo "Total Deployments: $(kubectl get deployments -A --no-headers | wc -l)"
echo "Compliant Deployments: $(kubectl get deployments -A -o json | jq '[.items[] | select(.metadata.labels.assetUuid != null)] | length')"
echo "Excluded Deployments: $(kubectl get deployments -A -o json | jq '[.items[] | select(.metadata.annotations["opa.example.com/exclude"] == "true" or .metadata.annotations["opa.example.com/exclude-until"] != null)] | length')"

# Check recent admission denials
kubectl get events --field-selector reason=ConstraintViolation -A --sort-by='.lastTimestamp' | tail -10
```

## Best Practices

### 1. Asset UUID Generation
- Use consistent UUID format across organization
- Include meaningful prefixes (e.g., `asset-prod-`, `asset-dev-`)
- Maintain asset registry for tracking and auditing

### 2. Emergency Procedures
- Document clear procedures for emergency exclusions
- Require approval workflow for exclusion annotations
- Set up monitoring alerts for exclusion usage

### 3. Developer Guidelines
```yaml
# Template for compliant deployments
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  labels:
    assetUuid: "${ASSET_UUID}"  # Required: Get from asset management system
    app: ${APP_NAME}
    version: ${APP_VERSION}
  annotations:
    description: "${APP_DESCRIPTION}"
spec:
  # ... rest of deployment
```

## Troubleshooting

### Common Issues

1. **Deployment Rejected Unexpectedly**
   - Verify `assetUuid` label is present and not empty
   - Check label syntax and formatting
   - Ensure namespace is not in exempt list

2. **Policy Not Enforcing**
   - Check Gatekeeper webhook configuration
   - Verify constraint is in `deny` mode
   - Confirm constraint template is properly installed

3. **Exclusions Not Working**
   - Verify annotation syntax is correct
   - Check time-based exclusions haven't expired
   - Ensure exclusion annotations are in metadata.annotations, not labels

### Debug Commands
```bash
# Check webhook configuration
kubectl get validatingadmissionwebhooks

# Verify constraint enforcement
kubectl describe assetuuidrequired deployment-asset-uuid-strict

# Check Gatekeeper logs for admission decisions
kubectl logs -l control-plane=controller-manager -n gatekeeper-system --tail=50

# Test policy with dry-run
kubectl apply --dry-run=server -f non-compliant-deployment.yaml
```

## Migration from Loose to Strict

If transitioning from loose to strict enforcement:

1. **Ensure 100% Compliance**
   ```bash
   # Verify no deployments lack assetUuid
   kubectl get deployments -A -o json | jq '.items[] | select(.metadata.labels.assetUuid == null) | "\(.metadata.namespace)/\(.metadata.name)"'
   ```

2. **Update Constraint**
   ```bash
   # Change enforcement mode and action
   kubectl patch assetuuidrequired deployment-asset-uuid-loose --type='merge' -p='{"spec":{"enforcementAction":"deny","parameters":{"enforcementMode":"strict"}}}'
   ```

3. **Monitor for Issues**
   ```bash
   # Watch for admission denials
   kubectl get events --field-selector reason=ConstraintViolation -A -w
   ```
