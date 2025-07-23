# Loose Enforcement Scenario

## Overview

The loose enforcement scenario demonstrates a **gradual migration approach** to implementing asset UUID requirements in a Kubernetes cluster that already has existing deployments without the required labels.

## Use Case

This scenario is ideal for:
- **Existing production clusters** with deployments that don't have `assetUuid` labels
- **Gradual compliance migration** where you want to enforce policies on new deployments while allowing existing ones to continue running
- **Risk-averse environments** where immediate strict enforcement could cause service disruptions

## Policy Configuration

### Enforcement Mode
- **Mode**: `loose`
- **Action**: `warn` (logs violations but allows deployment)
- **Scope**: New deployments only

### Key Features

1. **Existing Deployment Protection**
   - Deployments with `opa.example.com/existing: "true"` annotation are exempt
   - Allows legacy systems to continue operating

2. **New Deployment Requirements**
   - All new deployments must include `assetUuid` label
   - Violations generate warnings in Gatekeeper logs

3. **Flexible Exclusions**
   - Manual exclusions via `opa.example.com/exclude: "true"`
   - Time-based exclusions via `opa.example.com/exclude-until: "2024-12-31T23:59:59Z"`

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Loose Enforcement                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │  Existing App   │    │   New App       │                │
│  │  (No assetUuid) │    │  (assetUuid)    │                │
│  │  ✅ ALLOWED     │    │  ✅ REQUIRED    │                │
│  └─────────────────┘    └─────────────────┘                │
│           │                       │                        │
│           └───────────┬───────────┘                        │
│                       │                                    │
│              ┌─────────▼─────────┐                         │
│              │  OPA Gatekeeper   │                         │
│              │  (Loose Policy)   │                         │
│              └───────────────────┘                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Examples

### Compliant New Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: new-compliant-app
  labels:
    assetUuid: "asset-12345-abcde"  # Required for new deployments
spec:
  # ... deployment specification
```

### Existing Legacy Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app
  annotations:
    opa.example.com/existing: "true"  # Marks as existing deployment
  # Note: No assetUuid label - this is allowed
spec:
  # ... deployment specification
```

### Temporarily Excluded Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maintenance-app
  labels:
    assetUuid: "asset-maintenance-123"
  annotations:
    opa.example.com/exclude-until: "2024-01-15T10:00:00Z"
spec:
  # ... deployment specification
```

## Testing the Policy

### 1. Deploy Compliant Application
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: compliant-test
  namespace: opa-loose-demo
  labels:
    assetUuid: "asset-test-12345"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: compliant-test
  template:
    metadata:
      labels:
        app: compliant-test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF
```

### 2. Deploy Non-Compliant Application (Will Generate Warning)
```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: non-compliant-test
  namespace: opa-loose-demo
  # Note: No assetUuid label
spec:
  replicas: 1
  selector:
    matchLabels:
      app: non-compliant-test
  template:
    metadata:
      labels:
        app: non-compliant-test
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
EOF
```

### 3. Check Policy Violations
```bash
# Check constraint status
kubectl get assetuuidrequired deployment-asset-uuid-loose -o yaml

# Check Gatekeeper logs for warnings
kubectl logs -l control-plane=controller-manager -n gatekeeper-system

# Check events for violations
kubectl get events --field-selector reason=ConstraintViolation -n opa-loose-demo
```

## Migration Strategy

### Phase 1: Assessment
1. Deploy loose enforcement policy
2. Monitor warnings for non-compliant deployments
3. Identify all deployments that need `assetUuid` labels

### Phase 2: Gradual Compliance
1. Add `assetUuid` labels to existing deployments during maintenance windows
2. Remove `opa.example.com/existing` annotations as deployments become compliant
3. Monitor compliance metrics

### Phase 3: Transition to Strict
1. Once all deployments are compliant, switch to strict enforcement
2. Change `enforcementAction` from `warn` to `deny`
3. Update `enforcementMode` from `loose` to `strict`

## Monitoring and Observability

### Key Metrics to Track
- Number of compliant vs non-compliant deployments
- Warning frequency in Gatekeeper logs
- Time to compliance for new deployments

### Useful Commands
```bash
# List all deployments with assetUuid
kubectl get deployments -A -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.metadata.labels.assetUuid}{"\n"}{end}'

# Count compliant deployments
kubectl get deployments -A -o json | jq '[.items[] | select(.metadata.labels.assetUuid != null)] | length'

# Check constraint violations
kubectl get events --field-selector reason=ConstraintViolation -A --sort-by='.lastTimestamp'
```

## Troubleshooting

### Common Issues

1. **Policy Not Enforcing**
   - Check if Gatekeeper is running: `kubectl get pods -n gatekeeper-system`
   - Verify constraint template is installed: `kubectl get constrainttemplate`
   - Check constraint status: `kubectl get assetuuidrequired -A`

2. **Unexpected Violations**
   - Verify exclusion annotations are correctly formatted
   - Check if time-based exclusions have expired
   - Ensure namespace is not in exempt list

3. **Missing Warnings**
   - Check Gatekeeper controller logs
   - Verify audit is enabled and running
   - Confirm constraint `enforcementAction` is set to `warn`

### Debug Commands
```bash
# Check Gatekeeper status
kubectl get pods -n gatekeeper-system
kubectl logs -l control-plane=controller-manager -n gatekeeper-system

# Validate constraint template
kubectl get constrainttemplate assetuuidrequired -o yaml

# Check constraint details
kubectl describe assetuuidrequired deployment-asset-uuid-loose
```
