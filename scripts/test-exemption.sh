#!/bin/bash

# ACME Payments Inc. - Test Exemption Functionality
# Demonstrates how exemptions affect policy enforcement

set -e

# Check arguments
if [ $# -ne 1 ]; then
    echo "🏦 ACME Payments Inc. - Test Exemption Functionality"
    echo "==================================================="
    echo ""
    echo "Usage: $0 <mode>"
    echo ""
    echo "Modes:"
    echo "  loose  - Test exemption in loose enforcement mode"
    echo "  strict - Test exemption in strict enforcement mode"
    echo ""
    echo "Examples:"
    echo "  $0 loose"
    echo "  $0 strict"
    echo ""
    echo "💡 This script demonstrates how exemptions affect policy enforcement"
    echo "   by temporarily modifying the exemption status of test-non-compliant-app"
    exit 1
fi

MODE="$1"

# Validate arguments
if [[ "$MODE" != "loose" && "$MODE" != "strict" ]]; then
    echo "❌ Invalid mode: $MODE"
    echo "   Must be 'loose' or 'strict'"
    exit 1
fi

# Set namespace based on mode
if [ "$MODE" = "loose" ]; then
    NAMESPACE="opa-loose-demo"
else
    NAMESPACE="opa-strict-demo"
fi

DEPLOYMENT_NAME="test-non-compliant-app"

echo "🏦 ACME Payments Inc. - Test Exemption Functionality"
echo "==================================================="
echo "Testing exemption behavior in $MODE mode"
echo "Deployment: $DEPLOYMENT_NAME"
echo "Namespace: $NAMESPACE"
echo ""

# Check if environment is set up
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo "❌ Environment not set up for $MODE mode"
    echo "   Run: ./scripts/setup-$MODE.sh"
    exit 1
fi

if ! kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Test deployment not found: $DEPLOYMENT_NAME"
    echo "   Run: ./scripts/setup-$MODE.sh to create it"
    exit 1
fi

echo "📋 Current Exemption Status:"
echo "============================"
echo "The deployment '$DEPLOYMENT_NAME' is currently included in the exemption list."
echo "This means updates should be allowed even though it lacks the assetUuid label."
echo ""

echo "🔍 Viewing current exemptions in S3 storage:"
./scripts/minio/read-exemptions.sh "$MODE-enforcement/exemptions.json" | grep -A 5 -B 5 "$DEPLOYMENT_NAME" || echo "Exemption data not found in S3"

echo ""
echo "🔄 Testing Update with Exemption Active:"
echo "========================================"

# Get current replica count
current_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
new_replicas=$((current_replicas + 1))

echo "Attempting to scale deployment from $current_replicas to $new_replicas replicas..."

if kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -p "{\"spec\":{\"replicas\":$new_replicas}}"; then
    echo "✅ SUCCESS - Update allowed due to exemption"
    echo ""
    echo "📊 Updated Deployment:"
    kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o wide
    
    # Scale back down for next test
    echo ""
    echo "🔄 Scaling back to original replica count for next test..."
    kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -p "{\"spec\":{\"replicas\":$current_replicas}}" >/dev/null
else
    echo "❌ UNEXPECTED - Update was blocked despite exemption"
    echo "   This may indicate an issue with the exemption configuration"
fi

echo ""
echo "💡 Exemption Demonstration Complete"
echo "==================================="
echo ""
echo "🎯 Key Points Demonstrated:"
echo "• Exemptions allow updates to non-compliant deployments"
echo "• Exemption data is stored centrally in S3-compatible storage"
echo "• Both loose and strict modes respect exemption lists"
echo "• Professional audit trails track all exemption decisions"
echo ""
echo "🔧 To modify exemptions:"
echo "1. Update the exemption files in MinIO S3 storage"
echo "2. View current exemptions: ./scripts/minio/read-exemptions.sh $MODE-enforcement/exemptions.json"
echo "3. Exemptions include approval information and review dates"
echo ""
echo "📞 ACME Payments Inc. Support:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Exemption Requests: exemptions@acmepayments.com"
