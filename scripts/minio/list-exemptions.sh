#!/bin/bash

# ACME Payments Inc. - MinIO Exemption Storage Browser
# Lists all exemption files stored in the S3-compatible MinIO storage

set -e

echo "🏦 ACME Payments Inc. - FinOps Exemption Storage Browser"
echo "========================================================"
echo "Browsing centralized exemption data in S3-compatible storage"
echo ""

# Check if MinIO is running
if ! kubectl get pods -n minio-system -l app=minio | grep -q Running; then
    echo "❌ MinIO is not running. Please run the enterprise demo setup first."
    exit 1
fi

echo "📦 MinIO Storage Status:"
echo "========================"

# Create a temporary pod to run MinIO client commands
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: minio-browser
spec:
  restartPolicy: Never
  containers:
  - name: mc
    image: minio/mc:RELEASE.2024-01-16T16-06-34Z
    command: ["/bin/sh"]
    args:
    - -c
    - |
      echo "🔧 Configuring MinIO client..."
      mc alias set minio http://minio-api.minio-system.svc.cluster.local:9000 admin password123

      echo ""
      echo "📋 Available Buckets:"
      echo "===================="
      mc ls minio/

      echo ""
      echo "📁 ACME FinOps Exemptions Bucket Contents:"
      echo "=========================================="
      mc ls minio/acme-finops-exemptions/

      echo ""
      echo "📂 Loose Enforcement Exemptions:"
      echo "================================"
      if mc ls minio/acme-finops-exemptions/loose-enforcement/ 2>/dev/null; then
          mc ls minio/acme-finops-exemptions/loose-enforcement/
      else
          echo "No loose enforcement exemptions found"
      fi

      echo ""
      echo "📂 Strict Enforcement Exemptions:"
      echo "================================="
      if mc ls minio/acme-finops-exemptions/strict-enforcement/ 2>/dev/null; then
          mc ls minio/acme-finops-exemptions/strict-enforcement/
      else
          echo "No strict enforcement exemptions found"
      fi

      echo ""
      echo "📊 Storage Summary:"
      echo "=================="
      mc du minio/acme-finops-exemptions/

      echo ""
      echo "✅ Exemption storage browsing completed!"
      echo ""
      echo "💡 To view specific exemption files, use:"
      echo "   ./scripts/minio/read-exemption.sh <path>"
      echo "   Example: ./scripts/minio/read-exemption.sh loose-enforcement/exemptions.json"
EOF

# Wait for pod to complete and show logs
kubectl wait --for=condition=Ready pod/minio-browser --timeout=60s 2>/dev/null || true
sleep 2
kubectl logs minio-browser 2>/dev/null || echo "⚠️  Could not retrieve logs"

# Cleanup
kubectl delete pod minio-browser --ignore-not-found >/dev/null 2>&1
