#!/bin/bash

# ACME Payments Inc. - Push Deployment Demo
# Demonstrates deployment behavior in loose vs strict modes

set -e

# Check arguments
if [ $# -ne 2 ]; then
    echo "🏦 ACME Payments Inc. - Push Deployment Demo"
    echo "============================================"
    echo ""
    echo "Usage: $0 <deployment-type> <mode>"
    echo ""
    echo "Deployment Types:"
    echo "  compliant     - Deployment with proper assetUuid label"
    echo "  non-compliant - Deployment without assetUuid label"
    echo ""
    echo "Modes:"
    echo "  loose  - Test in loose enforcement mode"
    echo "  strict - Test in strict enforcement mode"
    echo ""
    echo "Examples:"
    echo "  $0 compliant loose"
    echo "  $0 non-compliant strict"
    echo "  $0 non-compliant loose"
    exit 1
fi

DEPLOYMENT_TYPE="$1"
MODE="$2"

# Validate arguments
if [[ "$DEPLOYMENT_TYPE" != "compliant" && "$DEPLOYMENT_TYPE" != "non-compliant" ]]; then
    echo "❌ Invalid deployment type: $DEPLOYMENT_TYPE"
    echo "   Must be 'compliant' or 'non-compliant'"
    exit 1
fi

if [[ "$MODE" != "loose" && "$MODE" != "strict" ]]; then
    echo "❌ Invalid mode: $MODE"
    echo "   Must be 'loose' or 'strict'"
    exit 1
fi

# Set namespace based on mode
if [ "$MODE" = "loose" ]; then
    NAMESPACE="opa-loose-demo"
    CONSTRAINT_NAME="deployment-asset-uuid-simple"
    CONSTRAINT_TYPE="assetuuidrequiredsimple"
else
    NAMESPACE="opa-strict-demo"
    CONSTRAINT_NAME="deployment-asset-uuid-strict-simple"
    CONSTRAINT_TYPE="assetuuidrequiredstrictsimple"
fi

echo "🏦 ACME Payments Inc. - Push Deployment Demo"
echo "============================================"
echo "Testing: $DEPLOYMENT_TYPE deployment in $MODE mode"
echo "Namespace: $NAMESPACE"
echo ""

# Check if environment is set up
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo "❌ Environment not set up for $MODE mode"
    echo "   Run: ./scripts/setup-$MODE.sh"
    exit 1
fi

if ! kubectl get "$CONSTRAINT_TYPE" "$CONSTRAINT_NAME" &>/dev/null; then
    echo "❌ Constraint not found for $MODE mode"
    echo "   Run: ./scripts/setup-$MODE.sh"
    exit 1
fi

# Generate unique deployment name
TIMESTAMP=$(date +%s)
DEPLOYMENT_NAME="demo-${DEPLOYMENT_TYPE}-${TIMESTAMP}"

echo "🚀 Attempting to create deployment: $DEPLOYMENT_NAME"
echo ""

# Create deployment based on type
if [ "$DEPLOYMENT_TYPE" = "compliant" ]; then
    echo "📋 Creating compliant deployment with assetUuid label..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
  labels:
    app: $DEPLOYMENT_NAME
    assetUuid: "asset-acme-demo-${TIMESTAMP}"
  annotations:
    description: "ACME Payments Inc. compliant demo deployment"
    finops-status: "compliant"
    cost-center: "demo-payments"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $DEPLOYMENT_NAME
  template:
    metadata:
      labels:
        app: $DEPLOYMENT_NAME
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
EOF

    if [ $? -eq 0 ]; then
        echo "✅ SUCCESS - Compliant deployment created successfully!"
        echo ""
        echo "📊 Deployment Details:"
        kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o wide
        echo ""
        echo "🏷️  Labels:"
        kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.metadata.labels}' | jq .
    else
        echo "❌ FAILED - Compliant deployment was rejected"
        echo "   This is unexpected - compliant deployments should always be allowed"
    fi

else
    echo "📋 Creating non-compliant deployment without assetUuid label..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
  namespace: $NAMESPACE
  labels:
    app: $DEPLOYMENT_NAME
    # Note: Missing assetUuid label - this violates FinOps policy
  annotations:
    description: "ACME Payments Inc. non-compliant demo deployment"
    finops-status: "non-compliant"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $DEPLOYMENT_NAME
  template:
    metadata:
      labels:
        app: $DEPLOYMENT_NAME
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "64Mi"
            cpu: "50m"
EOF

    if [ $? -eq 0 ]; then
        echo "⚠️  UNEXPECTED - Non-compliant deployment was allowed!"
        echo "   In $MODE mode, this should have been blocked"
        echo ""
        echo "📊 Deployment Details:"
        kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o wide
    else
        echo "✅ EXPECTED - Non-compliant deployment was blocked!"
        echo ""
        echo "📋 This demonstrates ACME Payments Inc. FinOps policy enforcement"
        echo "   Professional violation message was shown to the user"
    fi
fi

echo ""
echo "🎯 Mode-Specific Behavior:"
if [ "$MODE" = "loose" ]; then
    echo "LOOSE MODE:"
    echo "• ✅ Allows UPDATES to existing deployments (even if non-compliant)"
    echo "• ❌ Blocks CREATE of new deployments that are non-compliant"
    echo ""
    echo "💡 Try updating an existing deployment:"
    echo "   kubectl patch deployment test-non-compliant-app -n $NAMESPACE -p '{\"spec\":{\"replicas\":2}}'"
else
    echo "STRICT MODE:"
    echo "• ❌ Blocks CREATE of new deployments that are non-compliant"
    echo "• ❌ Blocks UPDATE of existing deployments that are non-compliant"
    echo ""
    echo "💡 Try updating an existing deployment (should fail):"
    echo "   kubectl patch deployment test-non-compliant-app -n $NAMESPACE -p '{\"spec\":{\"replicas\":3}}'"
fi

echo ""
echo "🧹 Cleanup:"
echo "   kubectl delete deployment $DEPLOYMENT_NAME -n $NAMESPACE"
