#!/bin/bash

# ACME Payments Inc. - MinIO Exemption File Reader
# Reads and displays exemption files from S3-compatible MinIO storage

set -e

# Check if file path is provided
if [ $# -eq 0 ]; then
    echo "🏦 ACME Payments Inc. - FinOps Exemption File Reader"
    echo "===================================================="
    echo ""
    echo "Usage: $0 <file-path>"
    echo ""
    echo "Examples:"
    echo "  $0 loose-enforcement/exemptions.json"
    echo "  $0 strict-enforcement/exemptions.json"
    echo ""
    echo "💡 To see available files, run: ./scripts/minio/list-exemptions.sh"
    exit 1
fi

FILE_PATH="$1"

echo "🏦 ACME Payments Inc. - FinOps Exemption File Reader"
echo "===================================================="
echo "Reading exemption file: $FILE_PATH"
echo ""

# Check if MinIO is running
if ! kubectl get pods -n minio-system -l app=minio | grep -q Running; then
    echo "❌ MinIO is not running. Please run the enterprise demo setup first."
    exit 1
fi

echo "📄 File Contents:"
echo "================="

# Create a temporary pod to read the file
kubectl run minio-reader --image=minio/mc:RELEASE.2024-01-16T16-06-34Z --rm -it --restart=Never -- sh -c "
echo '🔧 Configuring MinIO client...'
mc alias set minio http://minio-api.minio-system.svc.cluster.local:9000 admin password123

echo ''
echo '📋 Reading file: acme-finops-exemptions/$FILE_PATH'
echo '=================================================='

if mc cat minio/acme-finops-exemptions/$FILE_PATH 2>/dev/null; then
    echo ''
    echo '✅ File read successfully!'
else
    echo '❌ File not found or error reading file'
    echo ''
    echo '📁 Available files in bucket:'
    mc ls minio/acme-finops-exemptions/ --recursive
    exit 1
fi
"

echo ""
echo "📊 File Analysis:"
echo "================="

# Create another pod to analyze the JSON structure
kubectl run minio-analyzer --image=minio/mc:RELEASE.2024-01-16T16-06-34Z --rm -it --restart=Never -- /bin/bash -c "
mc alias set minio http://minio-api.minio-system.svc.cluster.local:9000 admin password123

echo '🔍 JSON Structure Analysis:'
echo '==========================='

if content=\$(mc cat minio/acme-finops-exemptions/$FILE_PATH 2>/dev/null); then
    echo \"\$content\" | python3 -c \"
import json
import sys

try:
    data = json.load(sys.stdin)
    
    print('📋 Exemption Categories Found:')
    for key in data.keys():
        if isinstance(data[key], dict):
            count = len(data[key])
            print(f'  • {key}: {count} entries')
        else:
            print(f'  • {key}: {data[key]}')
    
    print('')
    print('🏢 Deployment Exemptions:')
    if 'permanent_exemptions' in data:
        print('  Permanent Exemptions:')
        for deployment, details in data['permanent_exemptions'].items():
            if isinstance(details, dict):
                reason = details.get('reason', 'No reason provided')
                approved_by = details.get('approved_by', 'Unknown')
                print(f'    • {deployment}')
                print(f'      Reason: {reason}')
                print(f'      Approved by: {approved_by}')
            else:
                print(f'    • {deployment}: {details}')
    
    if 'time_based_exemptions' in data:
        print('  Time-based Exemptions:')
        for deployment, details in data['time_based_exemptions'].items():
            if isinstance(details, dict):
                expires = details.get('expires_at', 'No expiration')
                reason = details.get('reason', 'No reason provided')
                print(f'    • {deployment}')
                print(f'      Expires: {expires}')
                print(f'      Reason: {reason}')
            else:
                print(f'    • {deployment}: {details}')
    
    if 'existing_deployments' in data:
        print('  Existing Deployments:')
        for deployment, details in data['existing_deployments'].items():
            if isinstance(details, dict):
                reason = details.get('reason', 'No reason provided')
                deadline = details.get('migration_deadline', 'No deadline')
                print(f'    • {deployment}')
                print(f'      Reason: {reason}')
                print(f'      Migration deadline: {deadline}')
            else:
                print(f'    • {deployment}: {details}')

except json.JSONDecodeError as e:
    print(f'❌ Invalid JSON format: {e}')
except Exception as e:
    print(f'❌ Error analyzing file: {e}')
\" 2>/dev/null || echo '⚠️  Could not analyze JSON structure (python3 not available in container)'
else
    echo '❌ Could not read file for analysis'
fi
"

echo ""
echo "💡 Demo Tips:"
echo "============="
echo "• This file demonstrates centralized exemption management"
echo "• All exemptions require approval and have audit trails"
echo "• No self-exemption possible - only FinOps team can modify"
echo "• S3-compatible storage ensures enterprise-grade reliability"
echo ""
echo "📞 ACME Payments Inc. Contact:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Documentation: https://wiki.acmepayments.com/finops/exemptions"
