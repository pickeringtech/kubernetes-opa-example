#!/bin/bash

# ACME Payments Inc. - Correct Loose vs Strict Mode Demo
# Demonstrates the proper rolling deployment strategy

set -e

echo "🏦 ACME Payments Inc. - Correct Loose vs Strict Mode Demo"
echo "========================================================="
echo "Demonstrating proper rolling deployment strategy for FinOps policies"
echo ""

# Function to show section headers
show_section() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "🎯 $1"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
}

show_section "LOOSE MODE: Rolling Deployment Strategy"

echo "📋 Loose Mode Behavior:"
echo "======================="
echo "✅ Allows UPDATES to existing deployments (even if non-compliant)"
echo "❌ Blocks CREATE of new deployments that are non-compliant"
echo "💡 Purpose: Enables gradual rollout without breaking existing workloads"
echo ""

echo "🔧 Setting up loose mode test..."

# Ensure loose constraint is deployed
if ! kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple &>/dev/null; then
    kubectl apply -f scenarios/loose-enforcement/opa/simple-constraint-template.yaml
    kubectl wait --for=condition=Established crd/assetuuidrequiredsimple.constraints.gatekeeper.sh --timeout=60s
    kubectl apply -f scenarios/loose-enforcement/opa/simple-constraint.yaml
fi

echo "✅ Loose mode constraint active"
echo ""

echo "Test 1: CREATE new compliant deployment (should succeed)"
echo "-------------------------------------------------------"
if kubectl apply -f test-deployments/compliant-deployment.yaml -n opa-loose-demo --dry-run=server &>/dev/null; then
    echo "✅ PASS - New compliant deployment allowed"
else
    echo "❌ FAIL - New compliant deployment blocked"
fi

echo ""
echo "Test 2: CREATE new non-compliant deployment (should fail)"
echo "--------------------------------------------------------"
if kubectl create deployment loose-test-bad --image=nginx -n opa-loose-demo --dry-run=server &>/dev/null; then
    echo "❌ FAIL - New non-compliant deployment was allowed"
else
    echo "✅ PASS - New non-compliant deployment blocked"
    echo "📋 This prevents new technical debt from being introduced"
fi

echo ""
echo "Test 3: UPDATE existing non-compliant deployment (should succeed)"
echo "----------------------------------------------------------------"
current_replicas=$(kubectl get deployment test-non-compliant-app -n opa-loose-demo -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
new_replicas=$((current_replicas + 1))

if kubectl patch deployment test-non-compliant-app -n opa-loose-demo -p "{\"spec\":{\"replicas\":$new_replicas}}" &>/dev/null; then
    echo "✅ PASS - Existing non-compliant deployment can be updated"
    echo "📋 This allows operations teams to maintain existing workloads"
else
    echo "❌ FAIL - Existing non-compliant deployment update blocked"
fi

show_section "STRICT MODE: Full Enforcement"

echo "📋 Strict Mode Behavior:"
echo "========================"
echo "❌ Blocks CREATE of new deployments that are non-compliant"
echo "❌ Blocks UPDATE of existing deployments that are non-compliant"
echo "💡 Purpose: Full enforcement after migration period is complete"
echo ""

echo "🔧 Setting up strict mode test..."

# Ensure strict constraint is deployed
if ! kubectl get assetuuidrequiredstrictsimple deployment-asset-uuid-strict-simple &>/dev/null; then
    kubectl apply -f scenarios/strict-enforcement/opa/simple-constraint-template.yaml
    kubectl wait --for=condition=Established crd/assetuuidrequiredstrictsimple.constraints.gatekeeper.sh --timeout=60s
    kubectl apply -f scenarios/strict-enforcement/opa/simple-constraint.yaml
fi

echo "✅ Strict mode constraint active"
echo ""

echo "Test 4: CREATE new compliant deployment in strict mode (should succeed)"
echo "----------------------------------------------------------------------"
if kubectl apply -f test-deployments/compliant-deployment.yaml -n opa-strict-demo --dry-run=server &>/dev/null; then
    echo "✅ PASS - New compliant deployment allowed in strict mode"
else
    echo "❌ FAIL - New compliant deployment blocked in strict mode"
fi

echo ""
echo "Test 5: CREATE new non-compliant deployment in strict mode (should fail)"
echo "-----------------------------------------------------------------------"
if kubectl create deployment strict-test-bad --image=nginx -n opa-strict-demo --dry-run=server &>/dev/null; then
    echo "❌ FAIL - New non-compliant deployment was allowed in strict mode"
else
    echo "✅ PASS - New non-compliant deployment blocked in strict mode"
fi

echo ""
echo "Test 6: UPDATE existing non-compliant deployment in strict mode (should fail)"
echo "----------------------------------------------------------------------------"
current_replicas=$(kubectl get deployment test-non-compliant-app -n opa-strict-demo -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
new_replicas=$((current_replicas + 1))

if kubectl patch deployment test-non-compliant-app -n opa-strict-demo -p "{\"spec\":{\"replicas\":$new_replicas}}" --dry-run=server &>/dev/null; then
    echo "❌ FAIL - Existing non-compliant deployment update was allowed in strict mode"
else
    echo "✅ PASS - Existing non-compliant deployment update blocked in strict mode"
    echo "📋 This enforces full compliance on all operations"
fi

show_section "ENTERPRISE ROLLOUT STRATEGY"

echo "🎯 Recommended ACME Payments Inc. Rollout Strategy:"
echo "=================================================="
echo ""
echo "Phase 1: LOOSE MODE (Weeks 1-4)"
echo "-------------------------------"
echo "• Deploy loose mode constraints to all namespaces"
echo "• Existing workloads continue to operate normally"
echo "• New deployments must be compliant from day one"
echo "• Teams have time to update existing deployments"
echo "• Monitor violations and provide guidance"
echo ""
echo "Phase 2: MIGRATION PERIOD (Weeks 5-8)"
echo "-------------------------------------"
echo "• Teams update existing deployments to add assetUuid labels"
echo "• FinOps team provides support and tooling"
echo "• Regular compliance reports show progress"
echo "• Exemptions managed through centralized S3 storage"
echo ""
echo "Phase 3: STRICT MODE (Week 9+)"
echo "------------------------------"
echo "• Switch to strict mode constraints"
echo "• All operations require compliance"
echo "• Full FinOps governance in effect"
echo "• Continuous monitoring and reporting"
echo ""

echo "💼 Business Benefits:"
echo "===================="
echo "✅ Zero downtime during policy rollout"
echo "✅ Gradual migration reduces operational risk"
echo "✅ New technical debt prevention from day one"
echo "✅ Full compliance achieved within 8-9 weeks"
echo "✅ Professional messaging guides developers"
echo "✅ Centralized exemption management for special cases"

show_section "DEMO SUMMARY"

echo "🎉 Demo Results Summary:"
echo "========================"
echo ""
echo "LOOSE MODE (Rolling Deployment):"
echo "• ✅ New compliant deployments: ALLOWED"
echo "• ❌ New non-compliant deployments: BLOCKED"
echo "• ✅ Updates to existing non-compliant: ALLOWED"
echo ""
echo "STRICT MODE (Full Enforcement):"
echo "• ✅ New compliant deployments: ALLOWED"
echo "• ❌ New non-compliant deployments: BLOCKED"
echo "• ❌ Updates to existing non-compliant: BLOCKED"
echo ""
echo "📞 ACME Payments Inc. Support:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Migration Support: migration-team@acmepayments.com"
echo "• Emergency Escalation: finops-director@acmepayments.com"
echo ""
echo "🔧 Next Steps:"
echo "• Review current deployment compliance status"
echo "• Plan migration timeline for existing workloads"
echo "• Set up monitoring and reporting dashboards"
echo "• Train development teams on new requirements"
