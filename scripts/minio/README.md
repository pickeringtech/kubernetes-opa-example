# ACME Payments Inc. - MinIO Exemption Management Scripts

This directory contains scripts for managing and demonstrating the centralized exemption system using S3-compatible MinIO storage.

## 🎯 Demo Scripts

### `demo-exemptions.sh`
**The main demo script** - Run this for a comprehensive demonstration of the exemption management system.

```bash
./scripts/minio/demo-exemptions.sh
```

This script provides:
- Complete overview of centralized exemption management
- File format demonstrations
- Real-world usage scenarios
- Security and governance explanations

### `list-exemptions.sh`
Browse all exemption files stored in MinIO S3-compatible storage.

```bash
./scripts/minio/list-exemptions.sh
```

Shows:
- Available buckets and directories
- File listings for loose and strict enforcement
- Storage usage summary

### `read-exemption.sh`
Read and analyze specific exemption files with detailed JSON structure analysis.

```bash
./scripts/minio/read-exemption.sh <file-path>

# Examples:
./scripts/minio/read-exemption.sh loose-enforcement/exemptions.json
./scripts/minio/read-exemption.sh strict-enforcement/exemptions.json
```

Features:
- Pretty-printed JSON content
- Automatic structure analysis
- Exemption category breakdown
- Deployment-specific details

### `upload-exemption.sh`
Upload new exemption files to MinIO storage (FinOps team use only).

```bash
./scripts/minio/upload-exemption.sh <local-file> <s3-path>

# Example:
./scripts/minio/upload-exemption.sh new-exemptions.json loose-enforcement/exemptions.json
```

Includes:
- JSON validation
- Authorization checks
- Audit trail logging
- Upload verification

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

1. **Ensure MinIO is running:**
   ```bash
   kubectl get pods -n minio-system
   ```

2. **Run the comprehensive demo:**
   ```bash
   ./scripts/minio/demo-exemptions.sh
   ```

3. **Browse exemption files:**
   ```bash
   ./scripts/minio/list-exemptions.sh
   ```

4. **Examine specific exemptions:**
   ```bash
   ./scripts/minio/read-exemption.sh loose-enforcement/exemptions.json
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

- Use `demo-exemptions.sh` for the main presentation
- Show file contents with `read-exemption.sh` to demonstrate structure
- Highlight the professional format and audit trails
- Emphasize centralized control vs. self-exemption
- Discuss real-world scenarios and governance benefits
