#!/bin/bash

# ACME Payments Inc. - Strict Environment Setup
# Sets up strict enforcement mode for full compliance

set -e

echo "🏦 ACME Payments Inc. - Strict Environment Setup"
echo "================================================"
echo "Setting up strict enforcement mode for full compliance demonstration"
echo ""

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✅ Kubernetes cluster is accessible"

# Install Gatekeeper if not already installed
echo ""
echo "📦 Checking OPA Gatekeeper..."
if ! kubectl get namespace gatekeeper-system &> /dev/null; then
    echo "Installing OPA Gatekeeper..."
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
    
    echo "⏳ Waiting for Gatekeeper to be ready..."
    kubectl wait --for=condition=Ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s
    kubectl wait --for=condition=Ready pod -l control-plane=audit-controller -n gatekeeper-system --timeout=300s
else
    echo "✅ OPA Gatekeeper is already installed"
fi

# Deploy MinIO if not already deployed
echo ""
echo "📦 Checking MinIO S3-compatible storage..."
if ! kubectl get namespace minio-system &> /dev/null; then
    echo "Deploying MinIO..."
    kubectl apply -f infrastructure/minio/minio-deployment.yaml
    kubectl wait --for=condition=Available deployment/minio -n minio-system --timeout=300s
    
    echo "Setting up exemption data..."
    kubectl apply -f infrastructure/minio/minio-setup-job.yaml
    kubectl wait --for=condition=Complete job/minio-setup -n minio-system --timeout=300s
else
    echo "✅ MinIO is already deployed"
fi

# Create strict demo namespace
echo ""
echo "🏗️  Setting up strict demo namespace..."
kubectl create namespace opa-strict-demo --dry-run=client -o yaml | kubectl apply -f -

# Deploy shared constraint template
echo ""
echo "📋 Deploying shared OPA constraint template..."
kubectl apply -f opa/templates/asset-uuid-required.yaml

echo "⏳ Waiting for constraint template to be established..."
kubectl wait --for=condition=Established crd/assetuuidrequired.constraints.gatekeeper.sh --timeout=60s

# Create an existing non-compliant deployment (before constraint is active)
echo ""
echo "🚀 Creating existing deployment (before constraint activation)..."
kubectl apply -f test-deployments/non-compliant-deployment.yaml -n opa-strict-demo

# Now deploy the constraint
echo ""
echo "📋 Activating strict enforcement constraint..."
kubectl apply -f opa/constraints/strict-enforcement.yaml

echo ""
echo "🎉 Strict Environment Setup Complete!"
echo "====================================="
echo ""
echo "📊 Environment Status:"
echo "• ✅ OPA Gatekeeper: Running"
echo "• ✅ MinIO S3 storage: Running with exemption data"
echo "• ✅ Shared OPA template: Deployed (asset-uuid-required)"
echo "• ✅ Strict constraint: Active in opa-strict-demo namespace"
echo "• ✅ Existing deployment: test-non-compliant-app (cannot be updated)"
echo ""
echo "🎯 Strict Mode Behavior:"
echo "• ❌ Blocks CREATE of new deployments that are non-compliant"
echo "• ❌ Blocks UPDATE of existing deployments that are non-compliant"
echo ""
echo "🎭 Ready for demo! Use:"
echo "  ./scripts/push-deployment.sh compliant strict"
echo "  ./scripts/push-deployment.sh non-compliant strict"
echo ""
echo "📁 View exemptions:"
echo "  ./scripts/minio/list-exemptions.sh"
echo "  ./scripts/minio/read-exemptions.sh strict-enforcement/exemptions.json"
