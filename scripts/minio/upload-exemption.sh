#!/bin/bash

# ACME Payments Inc. - MinIO Exemption File Uploader
# Uploads new exemption files to S3-compatible MinIO storage

set -e

# Check if file path is provided
if [ $# -lt 2 ]; then
    echo "🏦 ACME Payments Inc. - FinOps Exemption File Uploader"
    echo "======================================================"
    echo ""
    echo "Usage: $0 <local-file> <s3-path>"
    echo ""
    echo "Examples:"
    echo "  $0 new-exemptions.json loose-enforcement/exemptions.json"
    echo "  $0 emergency-exemptions.json strict-enforcement/emergency.json"
    echo ""
    echo "⚠️  WARNING: This tool is for FinOps team use only!"
    echo "   Unauthorized modification of exemptions violates ACME Payments compliance policies."
    exit 1
fi

LOCAL_FILE="$1"
S3_PATH="$2"

echo "🏦 ACME Payments Inc. - FinOps Exemption File Uploader"
echo "======================================================"
echo "Uploading exemption file to centralized storage"
echo ""

# Check if local file exists
if [ ! -f "$LOCAL_FILE" ]; then
    echo "❌ Local file not found: $LOCAL_FILE"
    exit 1
fi

# Check if MinIO is running
if ! kubectl get pods -n minio-system -l app=minio | grep -q Running; then
    echo "❌ MinIO is not running. Please run the enterprise demo setup first."
    exit 1
fi

echo "📋 Upload Details:"
echo "=================="
echo "Local file: $LOCAL_FILE"
echo "S3 path: acme-finops-exemptions/$S3_PATH"
echo "File size: $(du -h "$LOCAL_FILE" | cut -f1)"
echo ""

# Validate JSON format if it's a JSON file
if [[ "$LOCAL_FILE" == *.json ]]; then
    echo "🔍 Validating JSON format..."
    if ! python3 -m json.tool "$LOCAL_FILE" > /dev/null 2>&1; then
        echo "❌ Invalid JSON format in $LOCAL_FILE"
        echo "Please ensure the file contains valid JSON before uploading."
        exit 1
    fi
    echo "✅ JSON format is valid"
    echo ""
fi

echo "⚠️  COMPLIANCE WARNING:"
echo "======================="
echo "This action will modify centralized exemption policies for ACME Payments Inc."
echo "Ensure you have proper authorization and approval before proceeding."
echo ""
read -p "Do you have FinOps team authorization to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Upload cancelled. Contact finops-team@acmepayments.com for authorization."
    exit 1
fi

echo ""
echo "📤 Uploading file..."
echo "==================="

# Create a temporary pod to upload the file
kubectl run minio-uploader --image=minio/mc:RELEASE.2024-01-16T16-06-34Z --rm -it --restart=Never --overrides="
{
  \"spec\": {
    \"containers\": [{
      \"name\": \"minio-uploader\",
      \"image\": \"minio/mc:RELEASE.2024-01-16T16-06-34Z\",
      \"command\": [\"/bin/bash\", \"-c\"],
      \"args\": [\"
        echo '🔧 Configuring MinIO client...'
        mc alias set minio http://minio-api.minio-system.svc.cluster.local:9000 admin password123
        
        echo ''
        echo '📤 Uploading file to S3 storage...'
        if mc cp /tmp/upload-file minio/acme-finops-exemptions/$S3_PATH; then
            echo '✅ File uploaded successfully!'
            echo ''
            echo '📋 Upload confirmation:'
            mc stat minio/acme-finops-exemptions/$S3_PATH
            echo ''
            echo '📁 Updated bucket contents:'
            mc ls minio/acme-finops-exemptions/ --recursive
        else
            echo '❌ Upload failed!'
            exit 1
        fi
      \"],
      \"volumeMounts\": [{
        \"name\": \"upload-volume\",
        \"mountPath\": \"/tmp\"
      }]
    }],
    \"volumes\": [{
      \"name\": \"upload-volume\",
      \"configMap\": {
        \"name\": \"temp-upload-$(date +%s)\"
      }
    }],
    \"restartPolicy\": \"Never\"
  }
}" --dry-run=client -o yaml > /tmp/uploader-pod.yaml

# Create a temporary ConfigMap with the file content
TEMP_CM_NAME="temp-upload-$(date +%s)"
kubectl create configmap "$TEMP_CM_NAME" --from-file=upload-file="$LOCAL_FILE"

# Update the pod spec to use the correct ConfigMap name
sed -i "s/temp-upload-[0-9]*/${TEMP_CM_NAME}/g" /tmp/uploader-pod.yaml

# Apply the pod
kubectl apply -f /tmp/uploader-pod.yaml

# Wait for completion
kubectl wait --for=condition=Ready pod/minio-uploader --timeout=60s
kubectl logs -f minio-uploader

# Cleanup
kubectl delete pod minio-uploader --ignore-not-found
kubectl delete configmap "$TEMP_CM_NAME" --ignore-not-found
rm -f /tmp/uploader-pod.yaml

echo ""
echo "📊 Post-Upload Verification:"
echo "============================"
echo "• File uploaded to: acme-finops-exemptions/$S3_PATH"
echo "• Verify with: ./scripts/minio/read-exemption.sh $S3_PATH"
echo "• List all files: ./scripts/minio/list-exemptions.sh"
echo ""
echo "📝 Audit Trail:"
echo "==============="
echo "• Upload time: $(date)"
echo "• Uploaded by: $(whoami)"
echo "• Local file: $LOCAL_FILE"
echo "• S3 path: $S3_PATH"
echo ""
echo "📞 Support:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Emergency: finops-director@acmepayments.com"
