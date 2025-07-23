#!/bin/bash

# Setup script for OPA Strict Enforcement Scenario
# This script demonstrates zero-tolerance asset UUID requirements

set -e

echo "🔒 Setting up OPA Strict Enforcement Scenario"
echo "=============================================="

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

# Install Gatekeeper if not already installed
echo "📦 Checking for OPA Gatekeeper..."
if ! kubectl get namespace gatekeeper-system &> /dev/null; then
    echo "Installing OPA Gatekeeper..."
    kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml
    
    echo "⏳ Waiting for Gatekeeper to be ready..."
    kubectl wait --for=condition=Ready pod -l control-plane=controller-manager -n gatekeeper-system --timeout=300s
    kubectl wait --for=condition=Ready pod -l control-plane=audit-controller -n gatekeeper-system --timeout=300s
else
    echo "✅ OPA Gatekeeper is already installed"
fi

# Apply the strict enforcement scenario
echo "🚀 Deploying strict enforcement scenario..."
kubectl apply -k scenarios/strict-enforcement/

echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=Available deployment/nginx-strict-demo -n opa-strict-demo --timeout=120s

# Get service information
echo "📋 Getting service information..."
STRICT_SERVICE=$(kubectl get svc nginx-strict-demo -n opa-strict-demo -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo "🎉 Strict Enforcement Scenario Setup Complete!"
echo "=============================================="
echo ""
echo "📊 Scenario Details:"
echo "  • Policy Mode: STRICT (denies ALL deployments without assetUuid)"
echo "  • Existing deployments: MUST have assetUuid"
echo "  • New deployments: MUST have assetUuid"
echo "  • Enforcement Action: DENY (blocks non-compliant deployments)"
echo ""
echo "🌐 Access the demo:"
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    MINIKUBE_IP=$(minikube ip)
    echo "  • Strict Demo: http://${MINIKUBE_IP}:${STRICT_SERVICE}"
elif command -v kind &> /dev/null; then
    echo "  • Port-forward to access:"
    echo "    kubectl port-forward svc/nginx-strict-demo -n opa-strict-demo 8080:80"
else
    echo "  • NodePort service created on port ${STRICT_SERVICE}"
fi
echo ""
echo "🧪 Test the policy:"
echo "  • Try deploying without assetUuid (will be REJECTED):"
echo "    kubectl create deployment test-fail --image=nginx -n opa-strict-demo"
echo "  • Check constraint status: kubectl get assetuuidrequired -A"
echo ""
echo "⚠️  WARNING: This policy will BLOCK any deployment without assetUuid!"
echo ""
echo "📚 View logs:"
echo "  • Gatekeeper logs: kubectl logs -l control-plane=controller-manager -n gatekeeper-system"
echo "  • Constraint violations: kubectl get events --field-selector reason=ConstraintViolation -A"
