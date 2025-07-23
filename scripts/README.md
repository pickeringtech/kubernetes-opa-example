# ACME Payments Inc. - Enterprise FinOps Demo Scripts

Focused demo scripts for showcasing OPA Gatekeeper with centralized exemption management.

## 🚀 Demo Walkthrough

### 1. Setup Loose Environment
```bash
./scripts/setup-loose.sh
```

Sets up loose enforcement mode for rolling deployment strategy.

### 2. Setup Strict Environment
```bash
./scripts/setup-strict.sh
```

Sets up strict enforcement mode for full compliance.

### 3. Push Deployments
```bash
./scripts/push-deployment.sh compliant loose
./scripts/push-deployment.sh non-compliant loose
./scripts/push-deployment.sh compliant strict
./scripts/push-deployment.sh non-compliant strict
```

Test different deployment scenarios in each mode.

## 📁 Directory Structure

```
scripts/
├── setup-loose.sh        # Setup loose enforcement environment
├── setup-strict.sh       # Setup strict enforcement environment
├── push-deployment.sh    # Test deployments (compliant/non-compliant)
└── minio/                # MinIO S3 storage demos
    ├── list-exemptions.sh # Browse exemption storage
    ├── read-exemptions.sh # Read exemption files
    └── README.md          # MinIO scripts documentation
```

## 🎯 Demo Flow

1. **Setup Loose**: `./scripts/setup-loose.sh`
2. **Demo Loose**: `./scripts/push-deployment.sh non-compliant loose`
3. **Setup Strict**: `./scripts/setup-strict.sh`
4. **Demo Strict**: `./scripts/push-deployment.sh non-compliant strict`
5. **Show Exemptions**: `./scripts/minio/read-exemptions.sh loose-enforcement/exemptions.json`

## 🏦 Enterprise Features Demonstrated

- **Centralized Control**: No developer self-exemption via S3 storage
- **Rolling Deployment**: Loose mode allows existing workload updates
- **Full Enforcement**: Strict mode blocks all non-compliant operations
- **Professional Messaging**: ACME Payments Inc. FinOps branding
- **Audit Trails**: Complete compliance tracking and exemption management

## 📞 Support

- **FinOps Team**: finops-team@acmepayments.com
- **Documentation**: https://wiki.acmepayments.com/finops
- **Emergency**: finops-director@acmepayments.com
