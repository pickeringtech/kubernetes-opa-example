#!/bin/bash

# ACME Payments Inc. - Enterprise FinOps Demo Script
# Demonstrates centralized exemption management and professional policy enforcement

set -e

echo "🏦 ACME Payments Inc. - Enterprise FinOps Policy Demo"
echo "===================================================="
echo "Demonstrating centralized exemption management and professional compliance messaging"
echo ""

# Function to test deployment with detailed output
test_deployment() {
    local file=$1
    local namespace=$2
    local expected_result=$3
    local description=$4
    
    echo "🔍 Testing: $description"
    echo "   File: $file"
    echo "   Namespace: $namespace"
    echo "   Expected: $expected_result"
    echo ""
    
    # Capture both stdout and stderr
    if output=$(kubectl apply -f "$file" -n "$namespace" --dry-run=server 2>&1); then
        if [ "$expected_result" = "success" ]; then
            echo "   ✅ PASS - Deployment allowed as expected"
            echo "   📋 Output: Deployment would be created successfully"
        else
            echo "   ❌ UNEXPECTED - Deployment was allowed but should have been rejected"
            echo "   📋 Output: $output"
        fi
    else
        if [ "$expected_result" = "failure" ]; then
            echo "   ✅ PASS - Deployment rejected as expected"
            echo "   📋 Professional FinOps Violation Message:"
            echo "   ================================================"
            echo "$output" | grep -A 30 "admission webhook" || echo "$output"
            echo "   ================================================"
        else
            echo "   ❌ UNEXPECTED - Deployment was rejected but should have been allowed"
            echo "   📋 Error: $output"
        fi
    fi
    echo ""
    echo "---"
    echo ""
}

echo "📊 Current Infrastructure Status:"
echo "================================="

# Check MinIO
if kubectl get pods -n minio-system -l app=minio | grep -q Running; then
    echo "✅ MinIO S3-compatible storage: Running"
else
    echo "⚠️  MinIO S3-compatible storage: Not running"
fi

# Check Gatekeeper
if kubectl get pods -n gatekeeper-system -l control-plane=controller-manager | grep -q Running; then
    echo "✅ OPA Gatekeeper: Running"
else
    echo "⚠️  OPA Gatekeeper: Not running"
fi

# Check constraints
if kubectl get assetuuidrequiredloose deployment-asset-uuid-loose &>/dev/null; then
    echo "✅ Loose enforcement constraint: Deployed"
else
    echo "⚠️  Loose enforcement constraint: Not deployed"
fi

if kubectl get assetuuidrequiredstrict deployment-asset-uuid-strict &>/dev/null; then
    echo "✅ Strict enforcement constraint: Deployed"
else
    echo "⚠️  Strict enforcement constraint: Not deployed"
fi

# Check exemption ConfigMap
if kubectl get configmap acme-finops-exemptions -n gatekeeper-system &>/dev/null; then
    echo "✅ Centralized exemption ConfigMap: Deployed"
else
    echo "⚠️  Centralized exemption ConfigMap: Not deployed"
fi

echo ""
echo "🎯 Demo Scenarios:"
echo "=================="

echo "Scenario 1: Compliant Deployment (Should Always Work)"
echo "----------------------------------------------------"
test_deployment "test-deployments/compliant-deployment.yaml" "acme-loose-demo" "success" "Compliant deployment with proper assetUuid label"
test_deployment "test-deployments/compliant-deployment.yaml" "acme-strict-demo" "success" "Compliant deployment in strict mode"

echo "Scenario 2: Non-Compliant Deployment - Strict Mode (Should Be Blocked)"
echo "---------------------------------------------------------------------"
test_deployment "test-deployments/non-compliant-deployment.yaml" "acme-strict-demo" "failure" "Non-compliant deployment in strict mode - should show professional ACME FinOps message"

echo "Scenario 3: Non-Compliant Deployment - Loose Mode (Should Show Warning)"
echo "----------------------------------------------------------------------"
test_deployment "test-deployments/non-compliant-deployment.yaml" "acme-loose-demo" "success" "Non-compliant deployment in loose mode - should allow with warning"

echo "🏗️  Infrastructure Highlights:"
echo "=============================="
echo "• MinIO S3-compatible storage for centralized exemption management"
echo "• Professional ACME Payments Inc. FinOps compliance messaging"
echo "• Centralized exemption control (no self-exemption via annotations)"
echo "• Enterprise-grade policy templates with proper metadata"
echo "• Separate loose and strict enforcement scenarios"
echo ""

echo "📋 Exemption Management:"
echo "========================"
echo "• Permanent exemptions: Controlled via centralized ConfigMap"
echo "• Time-based exemptions: Managed by FinOps team with expiration dates"
echo "• Existing deployments: Grandfathered with migration deadlines"
echo "• All exemptions require approval and have audit trails"
echo ""

echo "🌐 Access Points:"
echo "================="
echo "• MinIO Console: kubectl port-forward -n minio-system svc/minio-console 9001:9001"
echo "• Then visit: http://localhost:9001 (admin/password123)"
echo "• View exemptions: kubectl get configmap acme-finops-exemptions -n gatekeeper-system -o yaml"
echo ""

echo "📞 Enterprise Support:"
echo "======================"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Emergency Escalation: finops-director@acmepayments.com"
echo "• Documentation: https://wiki.acmepayments.com/finops/asset-tagging"
echo "• Ticket System: https://jira.acmepayments.com/finops"
echo ""

echo "🎉 Enterprise Demo Completed!"
echo "============================="
echo "This demo showcases how OPA Gatekeeper can be integrated with enterprise"
echo "FinOps practices for ACME Payments Inc., providing centralized control"
echo "over policy exemptions while maintaining professional compliance messaging."
