# ACME Payments Inc. - Shared OPA Implementation

This directory contains the shared OPA Gatekeeper implementation that works across both loose and strict enforcement scenarios.

## 🎯 Design Philosophy

**Single Policy, Multiple Configurations**: The same Rego logic handles both loose and strict enforcement modes, demonstrating that the policy implementation is consistent regardless of the deployment scenario.

## 📁 Directory Structure

```
opa/
├── templates/
│   └── asset-uuid-required.yaml    # Unified constraint template
├── constraints/
│   ├── loose-enforcement.yaml      # Loose mode configuration
│   └── strict-enforcement.yaml     # Strict mode configuration
└── README.md                       # This file
```

## 🔧 How It Works

### Unified Constraint Template
The `asset-uuid-required.yaml` template contains:
- **Single Rego Policy**: One policy that handles both modes
- **Mode-Aware Logic**: Behavior changes based on `enforcementMode` parameter
- **Professional Messaging**: Different messages for loose vs strict violations
- **Operation Detection**: Distinguishes between CREATE and UPDATE operations

### Mode-Specific Constraints
Each constraint file configures the same template differently:
- **Loose Mode**: `enforcementMode: "loose"` - blocks only CREATE operations
- **Strict Mode**: `enforcementMode: "strict"` - blocks CREATE and UPDATE operations

## 🎭 Demo Benefits

This shared implementation demonstrates:
- **Consistency**: Same policy logic across all scenarios
- **Flexibility**: Configuration-driven behavior changes
- **Maintainability**: Single source of truth for policy logic
- **Enterprise Architecture**: Proper separation of policy and configuration

## 🏦 ACME Payments Inc. Features

- **Professional Messaging**: Context-aware violation messages
- **FinOps Branding**: Consistent ACME Payments Inc. terminology
- **Business Context**: Cost allocation and compliance messaging
- **Support Integration**: Contact information and escalation procedures

## 🚀 Usage

The setup scripts automatically deploy the appropriate constraint:
- `setup-loose.sh` → deploys `loose-enforcement.yaml`
- `setup-strict.sh` → deploys `strict-enforcement.yaml`

Both use the same underlying template from `templates/asset-uuid-required.yaml`.

## 📞 Support

- **FinOps Team**: finops-team@acmepayments.com
- **Documentation**: https://wiki.acmepayments.com/finops/opa-policies
- **Emergency**: finops-director@acmepayments.com
