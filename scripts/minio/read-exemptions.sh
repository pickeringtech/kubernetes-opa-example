#!/bin/bash

# ACME Payments Inc. - Read Exemptions from S3 Storage

FILE_PATH="${1:-loose-enforcement/exemptions.json}"

echo "🏦 ACME Payments Inc. - Read Exemptions"
echo "======================================="
echo "Reading exemption file: $FILE_PATH"
echo ""

# Use the same approach we tested earlier
kubectl run minio-reader --image=curlimages/curl --rm -it --restart=Never -- curl -s http://minio-api.minio-system.svc.cluster.local:9000/acme-finops-exemptions/$FILE_PATH

echo ""
echo "✅ File content displayed above"
echo ""
echo "💡 This demonstrates the centralized exemption data format"
echo "📞 Contact: finops-team@acmepayments.com"
