#!/bin/bash

# Cleanup script for OPA Example scenarios
# This script removes all resources created by the demo scenarios

set -e

echo "🧹 Cleaning up OPA Example scenarios"
echo "===================================="

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

# Function to safely delete resources
safe_delete() {
    local resource=$1
    if kubectl get $resource &> /dev/null; then
        echo "🗑️  Deleting $resource..."
        kubectl delete $resource --ignore-not-found=true
    else
        echo "ℹ️  $resource not found, skipping..."
    fi
}

# Delete scenario namespaces and their resources
echo "🗑️  Removing scenario resources..."
safe_delete "namespace opa-loose-demo"
safe_delete "namespace opa-strict-demo"

# Delete constraints
echo "🗑️  Removing OPA constraints..."
safe_delete "assetuuidrequired deployment-asset-uuid-loose"
safe_delete "assetuuidrequired deployment-asset-uuid-strict"

# Delete constraint templates
echo "🗑️  Removing constraint templates..."
safe_delete "constrainttemplate assetuuidrequired"

# Ask about Gatekeeper removal
echo ""
read -p "🤔 Do you want to remove OPA Gatekeeper entirely? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing OPA Gatekeeper..."
    kubectl delete -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml --ignore-not-found=true
    
    # Wait for namespace deletion
    echo "⏳ Waiting for gatekeeper-system namespace to be deleted..."
    kubectl wait --for=delete namespace/gatekeeper-system --timeout=120s || true
else
    echo "ℹ️  Keeping OPA Gatekeeper installed"
fi

echo ""
echo "✅ Cleanup completed!"
echo "==================="
echo ""
echo "📋 What was cleaned up:"
echo "  • opa-loose-demo namespace and all resources"
echo "  • opa-strict-demo namespace and all resources"
echo "  • AssetUuidRequired constraints"
echo "  • AssetUuidRequired constraint template"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  • OPA Gatekeeper (complete removal)"
else
    echo "  • OPA Gatekeeper (kept installed)"
fi
echo ""
echo "🔄 To redeploy scenarios:"
echo "  • Loose enforcement: ./scripts/setup-loose.sh"
echo "  • Strict enforcement: ./scripts/setup-strict.sh"
