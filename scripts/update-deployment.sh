#!/bin/bash

# ACME Payments Inc. - Update Existing Deployment Demo
# Demonstrates update behavior in loose vs strict modes

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "🏦 ACME Payments Inc. - Update Existing Deployment Demo"
    echo "======================================================"
    echo ""
    echo "Usage: $0 <update-type> <mode>"
    echo ""
    echo "Update Types:"
    echo "  scale       - Scale deployment replicas (simple update)"
    echo "  image       - Update container image (more complex update)"
    echo "  annotation  - Add/update annotation (metadata update)"
    echo ""
    echo "Modes:"
    echo "  loose  - Test update in loose enforcement mode"
    echo "  strict - Test update in strict enforcement mode"
    echo ""
    echo "Examples:"
    echo "  $0 scale loose"
    echo "  $0 image strict"
    echo "  $0 annotation loose"
    echo ""
    echo "💡 Note: This tests updates to the existing 'test-non-compliant-app' deployment"
    echo "   which lacks the required assetUuid label."
    exit 1
fi

UPDATE_TYPE="$1"
MODE="$2"

# Validate arguments
if [[ "$UPDATE_TYPE" != "scale" && "$UPDATE_TYPE" != "image" && "$UPDATE_TYPE" != "annotation" ]]; then
    echo "❌ Invalid update type: $UPDATE_TYPE"
    echo "   Must be 'scale', 'image', or 'annotation'"
    exit 1
fi

if [[ "$MODE" != "loose" && "$MODE" != "strict" ]]; then
    echo "❌ Invalid mode: $MODE"
    echo "   Must be 'loose' or 'strict'"
    exit 1
fi

# Set namespace and constraint based on mode
if [ "$MODE" = "loose" ]; then
    NAMESPACE="opa-loose-demo"
    CONSTRAINT_NAME="asset-uuid-loose-enforcement"
else
    NAMESPACE="opa-strict-demo"
    CONSTRAINT_NAME="asset-uuid-strict-enforcement"
fi

DEPLOYMENT_NAME="test-non-compliant-app"

echo "🏦 ACME Payments Inc. - Update Existing Deployment Demo"
echo "======================================================"
echo "Testing: $UPDATE_TYPE update in $MODE mode"
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

# Show current deployment status
echo "📊 Current Deployment Status:"
echo "============================="
kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o wide
echo ""

# Show current labels (to confirm it's non-compliant)
echo "🏷️  Current Labels:"
kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.labels}' | jq .
echo ""

# Perform the update based on type
echo "🔄 Attempting $UPDATE_TYPE update..."
echo ""

case "$UPDATE_TYPE" in
    "scale")
        # Get current replica count and increment it
        current_replicas=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
        new_replicas=$((current_replicas + 1))
        
        echo "📈 Scaling deployment from $current_replicas to $new_replicas replicas..."
        
        if kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -p "{\"spec\":{\"replicas\":$new_replicas}}"; then
            echo "✅ SUCCESS - Scale update completed!"
            echo ""
            echo "📊 Updated Deployment:"
            kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o wide
        else
            echo "❌ BLOCKED - Scale update was denied by OPA policy"
            echo ""
            echo "📋 This demonstrates $MODE mode enforcement on existing deployments"
        fi
        ;;
        
    "image")
        echo "🖼️  Updating container image to nginx:1.21-alpine..."
        
        if kubectl patch deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.21-alpine"}]}}}}'; then
            echo "✅ SUCCESS - Image update completed!"
            echo ""
            echo "📊 Updated Deployment:"
            kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].image}'
            echo ""
        else
            echo "❌ BLOCKED - Image update was denied by OPA policy"
            echo ""
            echo "📋 This demonstrates $MODE mode enforcement on existing deployments"
        fi
        ;;
        
    "annotation")
        # Add a timestamp annotation
        timestamp=$(date +%s)
        
        echo "📝 Adding annotation: last-updated=$timestamp..."
        
        if kubectl annotate deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" "last-updated=$timestamp" --overwrite; then
            echo "✅ SUCCESS - Annotation update completed!"
            echo ""
            echo "📊 Updated Annotations:"
            kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.annotations}' | jq .
        else
            echo "❌ BLOCKED - Annotation update was denied by OPA policy"
            echo ""
            echo "📋 This demonstrates $MODE mode enforcement on existing deployments"
        fi
        ;;
esac

echo ""
echo "🎯 Mode-Specific Behavior Explanation:"
echo "======================================"

if [ "$MODE" = "loose" ]; then
    echo "LOOSE MODE BEHAVIOR:"
    echo "• ✅ Allows UPDATES to existing deployments (even if non-compliant)"
    echo "• ❌ Blocks CREATE of new deployments that are non-compliant"
    echo "• 💡 Purpose: Enables operations teams to maintain existing workloads"
    echo "           during the migration period to add assetUuid labels"
    echo ""
    echo "📈 Expected Result: UPDATE should SUCCEED"
    echo "   Existing deployments can be maintained while teams add compliance"
else
    echo "STRICT MODE BEHAVIOR:"
    echo "• ❌ Blocks CREATE of new deployments that are non-compliant"
    echo "• ❌ Blocks UPDATE of existing deployments that are non-compliant"
    echo "• 💡 Purpose: Full enforcement after migration period is complete"
    echo ""
    echo "📈 Expected Result: UPDATE should FAIL"
    echo "   All operations require compliance - no exceptions"
fi

echo ""
echo "🔧 Exemption Testing:"
echo "===================="
echo "To test exemption behavior:"
echo "1. Add this deployment to the exemption list in MinIO"
echo "2. View current exemptions: ./scripts/minio/read-exemptions.sh $MODE-enforcement/exemptions.json"
echo "3. Updates should then succeed (with possible warnings)"
echo ""
echo "📞 ACME Payments Inc. Support:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Migration Support: migration-team@acmepayments.com"
