#!/bin/bash

# Setup script for OPA Loose Enforcement Scenario
# This script demonstrates gradual migration to asset UUID requirements

set -e

echo "🛡️ Setting up OPA Loose Enforcement Scenario"
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

# Apply the loose enforcement scenario
echo "🚀 Deploying loose enforcement scenario..."
kubectl apply -k scenarios/loose-enforcement/

echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=Available deployment/nginx-loose-demo -n opa-loose-demo --timeout=120s
kubectl wait --for=condition=Available deployment/nginx-existing-legacy -n opa-loose-demo --timeout=120s

# Get service information
echo "📋 Getting service information..."
LOOSE_SERVICE=$(kubectl get svc nginx-loose-demo -n opa-loose-demo -o jsonpath='{.spec.ports[0].nodePort}')
LEGACY_SERVICE=$(kubectl get svc nginx-existing-legacy -n opa-loose-demo -o jsonpath='{.spec.ports[0].nodePort}')

echo ""
echo "🎉 Loose Enforcement Scenario Setup Complete!"
echo "=============================================="
echo ""
echo "📊 Scenario Details:"
echo "  • Policy Mode: LOOSE (warns on new deployments without assetUuid)"
echo "  • Existing deployments: ALLOWED without assetUuid"
echo "  • New deployments: REQUIRE assetUuid"
echo ""
echo "🌐 Access the demos:"
if command -v minikube &> /dev/null && minikube status &> /dev/null; then
    MINIKUBE_IP=$(minikube ip)
    echo "  • Compliant Demo: http://${MINIKUBE_IP}:${LOOSE_SERVICE}"
    echo "  • Legacy Demo: http://${MINIKUBE_IP}:${LEGACY_SERVICE}"
elif command -v kind &> /dev/null; then
    echo "  • Port-forward to access:"
    echo "    kubectl port-forward svc/nginx-loose-demo -n opa-loose-demo 8080:80"
    echo "    kubectl port-forward svc/nginx-existing-legacy -n opa-loose-demo 8081:80"
else
    echo "  • NodePort services created on ports ${LOOSE_SERVICE} and ${LEGACY_SERVICE}"
fi
echo ""
echo "🧪 Test the policy:"
echo "  • Try deploying without assetUuid: kubectl apply -f test-deployments/non-compliant-deployment.yaml"
echo "  • Check constraint status: kubectl get assetuuidrequired -A"
echo ""
echo "📚 View logs:"
echo "  • Gatekeeper logs: kubectl logs -l control-plane=controller-manager -n gatekeeper-system"
echo "  • Constraint violations: kubectl get events --field-selector reason=ConstraintViolation -A"
