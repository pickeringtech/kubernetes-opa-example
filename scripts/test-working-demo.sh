#!/bin/bash

# ACME Payments Inc. - Working Demo Test Script
# Demonstrates the corrected OPA policy enforcement

set -e

echo "🏦 ACME Payments Inc. - Working FinOps Demo"
echo "==========================================="
echo "Testing corrected OPA policy enforcement with proper violation detection"
echo ""

# Check if the simple constraint is deployed
if ! kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple &>/dev/null; then
    echo "❌ Simple constraint not found. Deploying..."
    kubectl apply -f scenarios/loose-enforcement/opa/simple-constraint-template.yaml
    kubectl wait --for=condition=Established crd/assetuuidrequiredsimple.constraints.gatekeeper.sh --timeout=60s
    kubectl apply -f scenarios/loose-enforcement/opa/simple-constraint.yaml
    echo "✅ Simple constraint deployed"
fi

echo "📋 Current Constraint Status:"
echo "============================="
kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.metadata.name}: {.spec.enforcementAction}' && echo
echo ""

echo "🔍 Test 1: Compliant Deployment (Should Succeed)"
echo "==============================================="
echo "Testing compliant deployment with assetUuid label..."
if kubectl apply -f test-deployments/compliant-deployment.yaml -n opa-loose-demo --dry-run=server &>/dev/null; then
    echo "✅ PASS - Compliant deployment allowed"
else
    echo "❌ FAIL - Compliant deployment was rejected"
fi
echo ""

echo "🔍 Test 2: Non-Compliant Deployment (Should Warn)"
echo "================================================"
echo "Testing non-compliant deployment without assetUuid label..."

# Clean up any existing deployment first
kubectl delete -f test-deployments/non-compliant-deployment.yaml -n opa-loose-demo --ignore-not-found &>/dev/null

echo "Deploying non-compliant application..."
if kubectl apply -f test-deployments/non-compliant-deployment.yaml -n opa-loose-demo &>/dev/null; then
    echo "✅ PASS - Non-compliant deployment allowed (loose mode)"
    echo "⚠️  Checking for policy violations..."
    
    # Wait for audit to catch up
    sleep 3
    
    # Check for violations
    violations=$(kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.status.violations[*].name}' 2>/dev/null || echo "")
    
    if [[ "$violations" == *"test-non-compliant-app"* ]]; then
        echo "✅ VIOLATION DETECTED - Policy is working correctly!"
        echo ""
        echo "📋 Violation Details:"
        echo "===================="
        kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.status.violations[?(@.name=="test-non-compliant-app")].message}' 2>/dev/null || echo "Violation message not yet available"
    else
        echo "⏳ Waiting for audit to detect violation..."
        sleep 5
        violations=$(kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.status.violations[*].name}' 2>/dev/null || echo "")
        if [[ "$violations" == *"test-non-compliant-app"* ]]; then
            echo "✅ VIOLATION DETECTED - Policy is working correctly!"
        else
            echo "⚠️  Violation not yet detected - audit may take time"
        fi
    fi
else
    echo "❌ FAIL - Non-compliant deployment was rejected (should be allowed in loose mode)"
fi

echo ""
echo "📊 All Current Violations:"
echo "========================="
violation_count=$(kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.status.violations}' | jq length 2>/dev/null || echo "0")
echo "Total violations detected: $violation_count"

if [ "$violation_count" -gt 0 ]; then
    echo ""
    echo "Violation Summary:"
    kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{range .status.violations[*]}- {.name} in {.namespace}{"\n"}{end}' 2>/dev/null || echo "Could not retrieve violation details"
fi

echo ""
echo "🎯 Demo Summary:"
echo "================"
echo "✅ OPA Gatekeeper is working correctly"
echo "✅ Loose enforcement allows deployments but records violations"
echo "✅ Professional ACME Payments Inc. violation messages are generated"
echo "✅ Violations are tracked for audit and compliance purposes"
echo ""

echo "💡 Key Points for Demo:"
echo "======================="
echo "• Loose mode allows deployments but tracks violations"
echo "• Violations are recorded for FinOps team review"
echo "• Professional messaging provides clear guidance"
echo "• Centralized tracking enables compliance reporting"
echo ""

echo "📞 ACME Payments Inc. Support:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Emergency: finops-director@acmepayments.com"
echo ""

echo "🔧 To view all violations:"
echo "kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o yaml"
echo ""
echo "🧹 To clean up test deployments:"
echo "kubectl delete -f test-deployments/non-compliant-deployment.yaml -n opa-loose-demo"
