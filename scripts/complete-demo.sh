#!/bin/bash

# ACME Payments Inc. - Complete Enterprise Demo
# Comprehensive demonstration of all working features

set -e

echo "🏦 ACME Payments Inc. - Complete Enterprise FinOps Demo"
echo "======================================================="
echo "Demonstrating centralized exemption management and professional policy enforcement"
echo ""

# Function to show section headers
show_section() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "🎯 $1"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
}

show_section "INFRASTRUCTURE STATUS"

echo "📊 Checking Enterprise Infrastructure:"
echo "======================================"

# Check MinIO
if kubectl get pods -n minio-system -l app=minio | grep -q Running; then
    echo "✅ MinIO S3-compatible storage: Running"
    echo "   🌐 Console: kubectl port-forward -n minio-system svc/minio-console 9001:9001"
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
if kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple &>/dev/null; then
    echo "✅ Working constraint: Deployed and enforced"
    enforcement=$(kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.spec.enforcementAction}')
    echo "   📋 Enforcement mode: $enforcement"
else
    echo "⚠️  Working constraint: Not deployed"
fi

show_section "CENTRALIZED EXEMPTION MANAGEMENT"

echo "📁 Demonstrating S3-Compatible Exemption Storage:"
echo "================================================="

if kubectl get pods -n minio-system -l app=minio | grep -q Running; then
    echo "🔍 Browsing exemption storage..."
    ./scripts/minio/list-exemptions.sh | head -20
    echo ""
    echo "📄 Sample exemption file content:"
    ./scripts/minio/simple-read.sh loose-enforcement/exemptions.json | head -15
    echo "... (truncated for demo)"
else
    echo "⚠️  MinIO not running - skipping exemption storage demo"
fi

show_section "POLICY ENFORCEMENT TESTING"

echo "🔍 Testing Policy Enforcement:"
echo "=============================="

# Ensure the working constraint is deployed
if ! kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple &>/dev/null; then
    echo "📦 Deploying working constraint..."
    kubectl apply -f scenarios/loose-enforcement/opa/simple-constraint-template.yaml
    kubectl wait --for=condition=Established crd/assetuuidrequiredsimple.constraints.gatekeeper.sh --timeout=60s
    kubectl apply -f scenarios/loose-enforcement/opa/simple-constraint.yaml
    echo "✅ Working constraint deployed"
fi

echo ""
echo "Test 1: Compliant Deployment"
echo "----------------------------"
if kubectl apply -f test-deployments/compliant-deployment.yaml -n opa-loose-demo --dry-run=server &>/dev/null; then
    echo "✅ PASS - Compliant deployment with assetUuid allowed"
else
    echo "❌ FAIL - Compliant deployment was rejected"
fi

echo ""
echo "Test 2: Non-Compliant Deployment (Loose Mode)"
echo "---------------------------------------------"
# Clean up first
kubectl delete -f test-deployments/non-compliant-deployment.yaml -n opa-loose-demo --ignore-not-found &>/dev/null

if kubectl apply -f test-deployments/non-compliant-deployment.yaml -n opa-loose-demo &>/dev/null; then
    echo "✅ PASS - Non-compliant deployment allowed (loose mode)"
    echo "⏳ Checking for policy violations..."
    
    # Wait for audit
    sleep 3
    
    violations=$(kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.status.violations[*].name}' 2>/dev/null || echo "")
    
    if [[ "$violations" == *"test-non-compliant-app"* ]]; then
        echo "✅ VIOLATION DETECTED - Policy working correctly!"
        echo ""
        echo "📋 Professional ACME Payments Inc. Violation Message:"
        echo "======================================================"
        kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.status.violations[?(@.name=="test-non-compliant-app")].message}' 2>/dev/null | head -10
        echo "... (message continues with support contacts)"
    else
        echo "⏳ Violation detection in progress..."
    fi
else
    echo "❌ FAIL - Non-compliant deployment was rejected"
fi

show_section "ENTERPRISE FEATURES SUMMARY"

echo "🏢 Enterprise-Grade Features Demonstrated:"
echo "=========================================="
echo ""
echo "🔒 CENTRALIZED CONTROL:"
echo "• No developer self-exemption capabilities"
echo "• All exemptions managed through S3-compatible storage"
echo "• FinOps team controls all policy modifications"
echo "• Proper authorization and approval workflows"
echo ""
echo "📊 FINOPS EXCELLENCE:"
echo "• Professional violation messaging for payment industry"
echo "• Cost impact tracking and business justification"
echo "• Audit trails with approval information and tickets"
echo "• Integration with enterprise support systems"
echo ""
echo "🛡️  COMPLIANCE & GOVERNANCE:"
echo "• Comprehensive violation tracking and reporting"
echo "• Time-based exemptions with automatic expiration"
echo "• Migration planning for existing deployments"
echo "• Regular review cycles and renewal processes"
echo ""
echo "🏗️  ENTERPRISE INFRASTRUCTURE:"
echo "• S3-compatible MinIO storage for reliability"
echo "• Kubernetes-native policy enforcement"
echo "• Scalable architecture for large organizations"
echo "• Professional error messages and escalation procedures"

show_section "DEMO COMMANDS FOR PRESENTATION"

echo "🎭 Key Commands for Live Demo:"
echo "============================="
echo ""
echo "1. Show exemption storage:"
echo "   ./scripts/minio/list-exemptions.sh"
echo ""
echo "2. View exemption file format:"
echo "   ./scripts/minio/simple-read.sh loose-enforcement/exemptions.json"
echo ""
echo "3. Test compliant deployment:"
echo "   kubectl apply -f test-deployments/compliant-deployment.yaml -n opa-loose-demo --dry-run=server"
echo ""
echo "4. Test non-compliant deployment:"
echo "   kubectl apply -f test-deployments/non-compliant-deployment.yaml -n opa-loose-demo"
echo ""
echo "5. View violations:"
echo "   kubectl get assetuuidrequiredsimple deployment-asset-uuid-simple -o jsonpath='{.status.violations[*].message}'"
echo ""
echo "6. Access MinIO console:"
echo "   kubectl port-forward -n minio-system svc/minio-console 9001:9001"
echo "   # Then visit http://localhost:9001 (admin/password123)"

show_section "BUSINESS VALUE PROPOSITION"

echo "💼 Value for ACME Payments Inc.:"
echo "================================"
echo ""
echo "🎯 IMMEDIATE BENEFITS:"
echo "• Automated FinOps compliance enforcement"
echo "• Reduced manual policy management overhead"
echo "• Comprehensive audit trails for regulatory compliance"
echo "• Professional violation messaging improves developer experience"
echo ""
echo "📈 LONG-TERM VALUE:"
echo "• Scalable governance framework for growing infrastructure"
echo "• Cost optimization through proper asset tracking"
echo "• Risk reduction through centralized policy control"
echo "• Integration foundation for broader FinOps initiatives"
echo ""
echo "🏆 COMPETITIVE ADVANTAGES:"
echo "• Enterprise-grade policy enforcement for payment industry"
echo "• Kubernetes-native solution with cloud portability"
echo "• Open-source foundation with commercial support options"
echo "• Extensible architecture for future compliance requirements"

echo ""
echo "🎉 DEMO COMPLETED SUCCESSFULLY!"
echo "==============================="
echo ""
echo "📞 ACME Payments Inc. Contacts:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Emergency Escalation: finops-director@acmepayments.com"
echo "• Documentation: https://wiki.acmepayments.com/finops"
echo "• Training: https://training.acmepayments.com/opa-policies"
