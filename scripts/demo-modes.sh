#!/bin/bash

# ACME Payments Inc. - Demonstrate Loose vs Strict Modes
# Shows the key differences between enforcement modes

set -e

echo "🏦 ACME Payments Inc. - Loose vs Strict Mode Demonstration"
echo "=========================================================="
echo "This script demonstrates the key differences between loose and strict enforcement"
echo ""

echo "📊 Current Environment Status:"
echo "=============================="

# Check loose mode
if kubectl get namespace opa-loose-demo &>/dev/null; then
    echo "✅ Loose mode environment: Ready"
    loose_deployments=$(kubectl get deployments -n opa-loose-demo --no-headers | wc -l)
    echo "   Deployments in loose namespace: $loose_deployments"
else
    echo "❌ Loose mode environment: Not set up"
    echo "   Run: ./scripts/setup-loose.sh"
fi

# Check strict mode
if kubectl get namespace opa-strict-demo &>/dev/null; then
    echo "✅ Strict mode environment: Ready"
    strict_deployments=$(kubectl get deployments -n opa-strict-demo --no-headers | wc -l)
    echo "   Deployments in strict namespace: $strict_deployments"
else
    echo "❌ Strict mode environment: Not set up"
    echo "   Run: ./scripts/setup-strict.sh"
fi

echo ""
echo "🔍 Compliance Status Analysis:"
echo "=============================="

if kubectl get namespace opa-loose-demo &>/dev/null; then
    echo "📋 Loose Mode Namespace (opa-loose-demo):"
    echo "----------------------------------------"
    kubectl get deployments -n opa-loose-demo -o custom-columns="NAME:.metadata.name,ASSET_UUID:.metadata.labels.assetUuid,REPLICAS:.spec.replicas" | sed 's/<none>/❌ MISSING/g' | sed 's/asset-/✅ /g'
    
    echo ""
    echo "🎯 Loose Mode Behavior:"
    echo "• ✅ UPDATE operations: ALLOWED (existing deployments can be maintained)"
    echo "• ❌ CREATE operations: BLOCKED if non-compliant"
    echo "• ⚠️  Warnings: Generated for non-compliant updates (logged)"
    echo ""
    
    echo "🧪 Test UPDATE in Loose Mode:"
    echo "Try: kubectl patch deployment test-non-compliant-app -n opa-loose-demo -p '{\"spec\":{\"replicas\":2}}'"
    echo "Expected: SUCCESS (update allowed)"
fi

echo ""

if kubectl get namespace opa-strict-demo &>/dev/null; then
    echo "📋 Strict Mode Namespace (opa-strict-demo):"
    echo "------------------------------------------"
    kubectl get deployments -n opa-strict-demo -o custom-columns="NAME:.metadata.name,ASSET_UUID:.metadata.labels.assetUuid,REPLICAS:.spec.replicas" | sed 's/<none>/❌ MISSING/g' | sed 's/asset-/✅ /g'
    
    echo ""
    echo "🎯 Strict Mode Behavior:"
    echo "• ❌ UPDATE operations: BLOCKED if non-compliant"
    echo "• ❌ CREATE operations: BLOCKED if non-compliant"
    echo "• 🚫 No exceptions: Full compliance required"
    echo ""
    
    echo "🧪 Test UPDATE in Strict Mode:"
    echo "Try: kubectl patch deployment test-non-compliant-app -n opa-strict-demo -p '{\"spec\":{\"replicas\":2}}'"
    echo "Expected: FAILURE (update blocked with professional ACME FinOps message)"
fi

echo ""
echo "🎭 Interactive Demo Commands:"
echo "============================="
echo ""
echo "1. Test Loose Mode Updates (should succeed):"
echo "   ./scripts/update-deployment.sh scale loose"
echo "   ./scripts/update-deployment.sh image loose"
echo ""
echo "2. Test Strict Mode Updates (should fail):"
echo "   ./scripts/update-deployment.sh scale strict"
echo "   ./scripts/update-deployment.sh image strict"
echo ""
echo "3. Test New Deployments (both should fail):"
echo "   ./scripts/push-deployment.sh non-compliant loose"
echo "   ./scripts/push-deployment.sh non-compliant strict"
echo ""
echo "4. View Policy Status:"
echo "   ./scripts/view-warnings.sh loose"
echo "   ./scripts/view-warnings.sh strict"
echo ""
echo "5. View Centralized Exemptions:"
echo "   ./scripts/minio/read-exemptions.sh loose-enforcement/exemptions.json"
echo "   ./scripts/minio/read-exemptions.sh strict-enforcement/exemptions.json"

echo ""
echo "🏢 Enterprise Value Proposition:"
echo "==============================="
echo ""
echo "🎯 LOOSE MODE (Rolling Deployment Strategy):"
echo "• Prevents NEW technical debt (blocks non-compliant CREATE operations)"
echo "• Allows existing workload maintenance (permits UPDATE operations)"
echo "• Provides migration time for teams to add compliance"
echo "• Generates warnings for audit and tracking purposes"
echo ""
echo "🎯 STRICT MODE (Full Compliance):"
echo "• Enforces complete policy compliance"
echo "• Blocks ALL non-compliant operations (CREATE and UPDATE)"
echo "• Suitable after migration period is complete"
echo "• Ensures zero tolerance for policy violations"
echo ""
echo "📊 BUSINESS BENEFITS:"
echo "• Zero downtime during policy rollout"
echo "• Gradual migration reduces operational risk"
echo "• Professional ACME Payments Inc. messaging guides developers"
echo "• Centralized exemption management prevents self-exemption"
echo "• Complete audit trails for compliance and reporting"

echo ""
echo "📞 ACME Payments Inc. Support:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Migration Support: migration-team@acmepayments.com"
echo "• Emergency Escalation: finops-director@acmepayments.com"
