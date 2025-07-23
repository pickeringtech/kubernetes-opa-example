#!/bin/bash

# Validation script for Kustomize configurations
# This script validates that all Kustomize configurations are syntactically correct

set -e

echo "🔍 Validating Kustomize Configurations"
echo "======================================"

# Function to validate kustomize configuration
validate_kustomize() {
    local path=$1
    local description=$2
    
    echo "📋 Validating: $description"
    echo "   Path: $path"
    
    if kubectl kustomize "$path" > /dev/null 2>&1; then
        echo "   ✅ VALID - Kustomize configuration is correct"
    else
        echo "   ❌ INVALID - Kustomize configuration has errors"
        echo "   Error details:"
        kubectl kustomize "$path" 2>&1 | sed 's/^/      /'
        return 1
    fi
    echo ""
}

# Validate loose enforcement scenario
echo "🛡️ Loose Enforcement Scenario"
echo "=============================="

validate_kustomize "scenarios/loose-enforcement" "Complete loose enforcement scenario"
validate_kustomize "scenarios/loose-enforcement/base" "Loose enforcement base resources"
validate_kustomize "scenarios/loose-enforcement/opa" "Loose enforcement OPA policies"
validate_kustomize "scenarios/loose-enforcement/overlays/existing-deployment" "Existing deployment overlay"

# Validate strict enforcement scenario
echo "🔒 Strict Enforcement Scenario"
echo "==============================="

validate_kustomize "scenarios/strict-enforcement" "Complete strict enforcement scenario"
validate_kustomize "scenarios/strict-enforcement/base" "Strict enforcement base resources"
validate_kustomize "scenarios/strict-enforcement/opa" "Strict enforcement OPA policies"

# Validate test deployments
echo "🧪 Test Deployments"
echo "==================="

echo "📋 Validating test deployment files"
for file in test-deployments/*.yaml; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo "   Checking: $filename"
        if kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1; then
            echo "   ✅ VALID - $filename"
        else
            echo "   ❌ INVALID - $filename has syntax errors"
            kubectl apply --dry-run=client -f "$file" 2>&1 | sed 's/^/      /'
        fi
    fi
done

echo ""
echo "🎉 Configuration validation completed!"
echo ""
echo "💡 Next steps:"
echo "   • Deploy loose scenario: ./scripts/setup-loose.sh"
echo "   • Deploy strict scenario: ./scripts/setup-strict.sh"
echo "   • Test policies: ./scripts/test-policies.sh"
