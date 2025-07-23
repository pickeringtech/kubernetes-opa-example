#!/bin/bash

# Enterprise Demo Test Script for ACME Payments Inc.
# Tests OPA policies with S3-based exemption management

set -e

echo "🏦 ACME Payments Inc. - Enterprise FinOps Demo"
echo "=============================================="
echo "Testing OPA Gatekeeper with S3-based exemption management"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "Please ensure your kubeconfig is set up correctly"
    exit 1
fi

echo "✅ Kubernetes cluster is accessible"

# Function to wait for deployment to be ready
wait_for_deployment() {
    local namespace=$1
    local deployment=$2
    local timeout=${3:-300}
    
    echo "⏳ Waiting for deployment $deployment in namespace $namespace to be ready..."
    kubectl wait --for=condition=Available deployment/$deployment -n $namespace --timeout=${timeout}s
}

# Function to wait for job completion
wait_for_job() {
    local namespace=$1
    local job=$2
    local timeout=${3:-300}
    
    echo "⏳ Waiting for job $job in namespace $namespace to complete..."
    kubectl wait --for=condition=Complete job/$job -n $namespace --timeout=${timeout}s
}

# Step 1: Deploy MinIO Infrastructure
echo ""
echo "📦 Step 1: Deploying MinIO S3-Compatible Storage"
echo "================================================"

kubectl apply -f infrastructure/minio/minio-deployment.yaml
wait_for_deployment "minio-system" "minio" 300

echo "✅ MinIO deployed successfully"

# Step 2: Setup MinIO with exemption data
echo ""
echo "🔧 Step 2: Setting up MinIO with exemption data"
echo "==============================================="

kubectl apply -f infrastructure/minio/minio-setup-job.yaml
wait_for_job "minio-system" "minio-setup" 300

echo "✅ MinIO setup completed with exemption data"

# Step 3: Install Gatekeeper if not already installed
echo ""
echo "🔒 Step 3: Installing OPA Gatekeeper"
echo "===================================="

if ! kubectl get namespace gatekeeper-system &> /dev/null; then
    echo "Installing OPA Gatekeeper..."
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
    
    echo "⏳ Waiting for Gatekeeper to be ready..."
    kubectl wait --for=condition=Ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s
    kubectl wait --for=condition=Ready pod -l control-plane=audit-controller -n gatekeeper-system --timeout=300s
else
    echo "✅ OPA Gatekeeper is already installed"
fi

# Step 4: Deploy constraint templates and constraints
echo ""
echo "📋 Step 4: Deploying FinOps Policies"
echo "===================================="

echo "Deploying constraint templates..."
kubectl apply -f scenarios/loose-enforcement/opa/constraint-template.yaml
kubectl apply -f scenarios/strict-enforcement/opa/constraint-template.yaml

# Wait for constraint templates to be established
echo "⏳ Waiting for constraint templates to be established..."
kubectl wait --for=condition=Established crd/assetuuidrequired.constraints.gatekeeper.sh --timeout=60s

echo "Deploying constraints..."
kubectl apply -f scenarios/loose-enforcement/opa/constraint.yaml
kubectl apply -f scenarios/strict-enforcement/opa/constraint.yaml

echo "✅ FinOps policies deployed successfully"

# Step 5: Create test namespaces
echo ""
echo "🏗️  Step 5: Creating test namespaces"
echo "===================================="

kubectl create namespace acme-loose-demo --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace acme-strict-demo --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Test namespaces created"

# Function to test deployment with detailed output
test_deployment() {
    local file=$1
    local namespace=$2
    local expected_result=$3
    local description=$4
    
    echo ""
    echo "🔍 Testing: $description"
    echo "   File: $file"
    echo "   Namespace: $namespace"
    echo "   Expected: $expected_result"
    
    # Capture both stdout and stderr
    if output=$(kubectl apply -f "$file" -n "$namespace" --dry-run=server 2>&1); then
        if [ "$expected_result" = "success" ]; then
            echo "   ✅ PASS - Deployment allowed as expected"
        else
            echo "   ❌ FAIL - Deployment should have been rejected"
            echo "   Output: $output"
        fi
    else
        if [ "$expected_result" = "failure" ]; then
            echo "   ✅ PASS - Deployment rejected as expected"
            echo "   📋 Violation Message:"
            echo "$output" | grep -A 20 "admission webhook" || echo "$output"
        else
            echo "   ❌ FAIL - Deployment should have been allowed"
            echo "   Error: $output"
        fi
    fi
}

# Step 6: Test loose enforcement scenario
echo ""
echo "📋 Step 6: Testing Loose Enforcement Scenario"
echo "=============================================="

# Test compliant deployment (should succeed)
test_deployment "test-deployments/compliant-deployment.yaml" "acme-loose-demo" "success" "Compliant deployment with assetUuid"

# Test non-compliant deployment (should succeed with warning in loose mode)
test_deployment "test-deployments/non-compliant-deployment.yaml" "acme-loose-demo" "success" "Non-compliant deployment (loose mode allows with warning)"

# Step 7: Test strict enforcement scenario
echo ""
echo "📋 Step 7: Testing Strict Enforcement Scenario"
echo "==============================================="

# Test compliant deployment (should succeed)
test_deployment "test-deployments/compliant-deployment.yaml" "acme-strict-demo" "success" "Compliant deployment with assetUuid"

# Test non-compliant deployment (should fail in strict mode)
test_deployment "test-deployments/non-compliant-deployment.yaml" "acme-strict-demo" "failure" "Non-compliant deployment (strict mode rejects)"

echo ""
echo "🎉 Enterprise Demo Testing Completed!"
echo ""
echo "📊 Summary:"
echo "• MinIO S3-compatible storage deployed and configured"
echo "• Exemption data stored in S3 buckets"
echo "• OPA Gatekeeper policies deployed with enterprise messaging"
echo "• Both loose and strict enforcement scenarios tested"
echo ""
echo "🌐 Access Points:"
echo "• MinIO Console: kubectl port-forward -n minio-system svc/minio-console 9001:9001"
echo "• Then visit: http://localhost:9001 (admin/password123)"
echo ""
echo "📞 Support Information:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Documentation: https://wiki.acmepayments.com/finops/asset-tagging"
echo "• Emergency Escalation: finops-director@acmepayments.com"
