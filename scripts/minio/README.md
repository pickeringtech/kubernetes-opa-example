# ACME Payments Inc. - MinIO Exemption Management Scripts

This directory contains scripts for demonstrating the centralized exemption system using S3-compatible MinIO storage.

## 🎯 Demo Scripts

### `list-exemptions.sh`
Browse all exemption files stored in MinIO S3-compatible storage.

```bash
./scripts/minio/list-exemptions.sh
```

Shows:
- Available buckets and directories
- File listings for loose and strict enforcement
- Storage usage summary

### `read-exemptions.sh`
Read specific exemption files and display their contents.

```bash
./scripts/minio/read-exemptions.sh <file-path>

# Examples:
./scripts/minio/read-exemptions.sh loose-enforcement/exemptions.json
./scripts/minio/read-exemptions.sh strict-enforcement/exemptions.json
```

Features:
- Clean JSON content display
- Perfect for live demos
- Shows professional exemption format

## 🏦 Enterprise Features Demonstrated

### Centralized Control
- No self-exemption capabilities for developers
- All exemptions managed through centralized storage
- Proper approval workflows and authorization

### Audit & Compliance
- Complete audit trails with approval information
- Ticket references and responsible parties
- Review dates and expiration tracking
- Cost impact analysis

### Professional File Format
```json
{
  "permanent_exemptions": {
    "namespace/deployment-name": {
      "reason": "Business justification",
      "approved_by": "finops-team@acmepayments.com",
      "approval_date": "2025-01-15",
      "cost_impact": "medium",
      "review_date": "2025-04-15",
      "ticket": "FINOPS-1234"
    }
  },
  "time_based_exemptions": {
    "namespace/deployment-name": {
      "expires_at": "2025-02-15T10:00:00Z",
      "reason": "Temporary exemption reason",
      "approved_by": "team-lead@acmepayments.com",
      "ticket": "DEV-5678"
    }
  },
  "existing_deployments": {
    "namespace/deployment-name": {
      "reason": "Pre-existing deployment",
      "grandfathered_date": "2024-12-01",
      "migration_deadline": "2025-06-01",
      "cost_impact": "high"
    }
  }
}
```

## 🚀 Quick Start for Demo

1. **Run the main demo (includes MinIO demo):**
   ```bash
   ./scripts/demo.sh
   ```

2. **Browse exemption files:**
   ```bash
   ./scripts/minio/list-exemptions.sh
   ```

3. **Examine specific exemptions:**
   ```bash
   ./scripts/minio/read-exemptions.sh loose-enforcement/exemptions.json
   ```

## 📞 ACME Payments Inc. Support

- **FinOps Team:** finops-team@acmepayments.com
- **Emergency Escalation:** finops-director@acmepayments.com
- **Documentation:** https://wiki.acmepayments.com/finops/exemptions
- **Training:** https://training.acmepayments.com/finops-exemptions

## 🔧 Technical Requirements

- Kubernetes cluster with MinIO deployed
- kubectl access to the cluster
- MinIO client (mc) - automatically provided in container pods

## 🎭 Demo Tips

- Use the main `./scripts/demo.sh` for presentations
- Show file contents with `read-exemptions.sh` to demonstrate structure
- Highlight the professional format and audit trails
- Emphasize centralized control vs. self-exemption
- Discuss real-world scenarios and governance benefits
