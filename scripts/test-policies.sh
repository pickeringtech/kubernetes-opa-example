#!/bin/bash

# Test script for OPA policies
# This script tests both loose and strict enforcement scenarios

set -e

echo "🧪 Testing OPA Asset UUID Policies"
echo "=================================="

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Function to test deployment
test_deployment() {
    local file=$1
    local namespace=$2
    local expected_result=$3
    local description=$4
    
    echo "🔍 Testing: $description"
    echo "   File: $file"
    echo "   Namespace: $namespace"
    echo "   Expected: $expected_result"
    
    if kubectl apply -f "$file" -n "$namespace" --dry-run=server &> /dev/null; then
        if [ "$expected_result" = "success" ]; then
            echo "   ✅ PASS - Deployment allowed as expected"
        else
            echo "   ❌ FAIL - Deployment should have been rejected"
        fi
    else
        if [ "$expected_result" = "failure" ]; then
            echo "   ✅ PASS - Deployment rejected as expected"
        else
            echo "   ❌ FAIL - Deployment should have been allowed"
        fi
    fi
    echo ""
}

# Test loose enforcement scenario
echo "📋 Testing Loose Enforcement Scenario"
echo "======================================"

if kubectl get namespace opa-loose-demo &> /dev/null; then
    echo "✅ Loose enforcement namespace exists"
    
    # Test compliant deployment (should succeed)
    test_deployment "test-deployments/compliant-deployment.yaml" "opa-loose-demo" "success" "Compliant deployment with assetUuid"
    
    # Test non-compliant deployment (should succeed with warning in loose mode)
    test_deployment "test-deployments/non-compliant-deployment.yaml" "opa-loose-demo" "success" "Non-compliant deployment (loose mode allows with warning)"
    
    # Test excluded deployment (should succeed)
    test_deployment "test-deployments/excluded-deployment.yaml" "opa-loose-demo" "success" "Excluded deployment"
    
else
    echo "⚠️  Loose enforcement scenario not deployed. Run ./scripts/setup-loose.sh first"
fi

echo ""

# Test strict enforcement scenario
echo "📋 Testing Strict Enforcement Scenario"
echo "======================================="

if kubectl get namespace opa-strict-demo &> /dev/null; then
    echo "✅ Strict enforcement namespace exists"
    
    # Test compliant deployment (should succeed)
    test_deployment "test-deployments/compliant-deployment.yaml" "opa-strict-demo" "success" "Compliant deployment with assetUuid"
    
    # Test non-compliant deployment (should fail in strict mode)
    test_deployment "test-deployments/non-compliant-deployment.yaml" "opa-strict-demo" "failure" "Non-compliant deployment (strict mode rejects)"
    
    # Test excluded deployment (should succeed)
    test_deployment "test-deployments/excluded-deployment.yaml" "opa-strict-demo" "success" "Excluded deployment"
    
else
    echo "⚠️  Strict enforcement scenario not deployed. Run ./scripts/setup-strict.sh first"
fi

echo ""

# Check constraint status
echo "📊 Constraint Status"
echo "===================="

if kubectl get constrainttemplate assetuuidrequired &> /dev/null; then
    echo "✅ AssetUuidRequired constraint template exists"
    
    # Check loose constraint
    if kubectl get assetuuidrequired deployment-asset-uuid-loose &> /dev/null; then
        echo "✅ Loose enforcement constraint exists"
        LOOSE_VIOLATIONS=$(kubectl get assetuuidrequired deployment-asset-uuid-loose -o jsonpath='{.status.totalViolations}' 2>/dev/null || echo "0")
        echo "   Violations: $LOOSE_VIOLATIONS"
    else
        echo "⚠️  Loose enforcement constraint not found"
    fi
    
    # Check strict constraint
    if kubectl get assetuuidrequired deployment-asset-uuid-strict &> /dev/null; then
        echo "✅ Strict enforcement constraint exists"
        STRICT_VIOLATIONS=$(kubectl get assetuuidrequired deployment-asset-uuid-strict -o jsonpath='{.status.totalViolations}' 2>/dev/null || echo "0")
        echo "   Violations: $STRICT_VIOLATIONS"
    else
        echo "⚠️  Strict enforcement constraint not found"
    fi
    
else
    echo "❌ AssetUuidRequired constraint template not found"
    echo "   Please ensure OPA Gatekeeper is installed and constraints are deployed"
fi

echo ""

# Check Gatekeeper status
echo "🔧 Gatekeeper Status"
echo "===================="

if kubectl get namespace gatekeeper-system &> /dev/null; then
    echo "✅ Gatekeeper namespace exists"
    
    CONTROLLER_READY=$(kubectl get pods -n gatekeeper-system -l control-plane=controller-manager --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    AUDIT_READY=$(kubectl get pods -n gatekeeper-system -l control-plane=audit-controller --no-headers 2>/dev/null | grep -c "Running" || echo "0")
    
    echo "   Controller pods running: $CONTROLLER_READY"
    echo "   Audit pods running: $AUDIT_READY"
    
    if [ "$CONTROLLER_READY" -gt 0 ] && [ "$AUDIT_READY" -gt 0 ]; then
        echo "   ✅ Gatekeeper is healthy"
    else
        echo "   ⚠️  Gatekeeper may not be fully ready"
    fi
else
    echo "❌ Gatekeeper not installed"
    echo "   Run one of the setup scripts to install Gatekeeper"
fi

echo ""
echo "🎉 Policy testing completed!"
echo ""
echo "💡 Tips:"
echo "   • Check Gatekeeper logs: kubectl logs -l control-plane=controller-manager -n gatekeeper-system"
echo "   • View constraint violations: kubectl get events --field-selector reason=ConstraintViolation -A"
echo "   • Test actual deployments: kubectl apply -f test-deployments/compliant-deployment.yaml -n <namespace>"
