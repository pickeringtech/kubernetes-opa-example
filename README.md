# Kubernetes OPA Example: Asset UUID Enforcement

This project demonstrates two scenarios for enforcing asset UUID requirements in Kubernetes deployments using Open Policy Agent (OPA) Gatekeeper.

## Scenarios

### 1. Loose Enforcement (`scenarios/loose-enforcement/`)
- **Use Case**: Existing Kubernetes cluster with deployments that don't have `assetUuid` labels
- **Policy**: Only new deployments require `assetUuid` labels
- **Features**: 
  - Existing deployments are excluded from enforcement
  - Time-based exclusions supported
  - Gradual migration path

### 2. Strict Enforcement (`scenarios/strict-enforcement/`)
- **Use Case**: Clean slate or fully compliant environment
- **Policy**: All deployments (new and existing) must have `assetUuid` labels
- **Features**:
  - Immediate enforcement
  - No exceptions for existing deployments
  - Demonstrates full policy compliance

## 📁 Project Structure

```
├── opa/                       # Shared OPA Gatekeeper implementation
│   ├── templates/             # Unified constraint templates
│   └── constraints/           # Mode-specific constraint configurations
├── scenarios/                 # Demo scenario configurations
│   ├── loose-enforcement/     # Gradual rollout scenario
│   └── strict-enforcement/    # Full compliance scenario
├── test-deployments/          # Sample deployments for testing
├── scripts/                   # Demo and setup scripts
└── infrastructure/            # Supporting infrastructure (MinIO, etc.)
```

## 🔧 Shared OPA Implementation

The `opa/` directory contains a unified OPA Gatekeeper implementation that works across both scenarios:

- **Single Policy Logic**: One Rego policy handles both loose and strict modes
- **Configuration-Driven**: Behavior changes based on `enforcementMode` parameter
- **Consistent Messaging**: Professional ACME Payments Inc. violation messages
- **Maintainable**: Single source of truth for policy logic

This demonstrates enterprise-grade policy management where the same logic works regardless of deployment scenario.

## Quick Start

### Prerequisites
- Kubernetes cluster (minikube, kind, or cloud provider)
- kubectl configured
- kustomize (built into kubectl 1.14+)

### Setup Loose Enforcement
```bash
./scripts/setup-loose.sh
```

### Setup Strict Enforcement
```bash
./scripts/setup-strict.sh
```

### Test Deployments
```bash
./scripts/push-deployment.sh compliant loose
./scripts/push-deployment.sh non-compliant loose
./scripts/push-deployment.sh non-compliant strict
```

### Validate Configurations
```bash
./scripts/validate-configs.sh
```

### Cleanup
```bash
./scripts/cleanup.sh
```

## Architecture

Both scenarios use:
- **OPA Gatekeeper** for policy enforcement
- **ConstraintTemplate** defining the asset UUID validation logic
- **Constraint** applying the policy to specific resources
- **NGINX deployments** demonstrating compliant and non-compliant resources
- **Kustomize** for configuration management

## Key Features

### Asset UUID Validation
- Validates presence of `assetUuid` label on deployments
- Supports exclusion annotations for gradual migration
- Time-based exclusions for temporary exemptions

### Exclusion Mechanisms
1. **Annotation-based**: `opa.example.com/exclude: "true"`
2. **Time-based**: `opa.example.com/exclude-until: "2024-12-31T23:59:59Z"`
3. **Scenario-specific**: Different enforcement levels per scenario

## Testing

Each scenario includes test deployments to demonstrate:
- ✅ Compliant deployments (with `assetUuid`)
- ❌ Non-compliant deployments (without `assetUuid`)
- 🔄 Excluded deployments (with exclusion annotations)

## Documentation

- [Loose Scenario Details](docs/loose-scenario.md)
- [Strict Scenario Details](docs/strict-scenario.md)

## Project Structure

```
├── scenarios/
│   ├── loose-enforcement/     # Gradual enforcement scenario
│   └── strict-enforcement/    # Immediate enforcement scenario
├── scripts/                   # Setup and utility scripts
└── docs/                     # Detailed documentation
```
