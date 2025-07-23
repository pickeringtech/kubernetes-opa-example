#!/bin/bash

# ACME Payments Inc. - Interactive Exemption Demo
# Comprehensive demonstration of centralized exemption management

set -e

echo "🏦 ACME Payments Inc. - Interactive Exemption Management Demo"
echo "============================================================="
echo "Demonstrating enterprise-grade centralized exemption control"
echo ""

# Check if MinIO is running
if ! kubectl get pods -n minio-system -l app=minio | grep -q Running; then
    echo "❌ MinIO is not running. Please run the enterprise demo setup first."
    echo "   Run: ./scripts/test-enterprise-demo.sh"
    exit 1
fi

echo "🎯 Demo Overview:"
echo "================="
echo "This demo showcases how ACME Payments Inc. manages FinOps exemptions"
echo "through centralized S3-compatible storage, eliminating self-exemption"
echo "and ensuring proper governance and audit trails."
echo ""

echo "📋 Step 1: Browse Current Exemption Storage"
echo "==========================================="
echo "Let's see what's currently stored in our S3-compatible MinIO storage:"
echo ""

./scripts/minio/list-exemptions.sh

echo ""
echo "📄 Step 2: Examine Loose Enforcement Exemptions"
echo "==============================================="
echo "Let's look at the detailed exemption data for loose enforcement:"
echo ""

./scripts/minio/read-exemption.sh loose-enforcement/exemptions.json

echo ""
echo "📄 Step 3: Examine Strict Enforcement Exemptions"
echo "================================================"
echo "Now let's see the more restrictive exemptions for strict enforcement:"
echo ""

./scripts/minio/read-exemption.sh strict-enforcement/exemptions.json

echo ""
echo "🔍 Step 4: Demonstrate File Format and Structure"
echo "==============================================="
echo "Here's what makes our exemption system enterprise-grade:"
echo ""

echo "✅ Key Features Demonstrated:"
echo "• JSON-structured exemption data with full metadata"
echo "• Approval workflows with responsible parties"
echo "• Time-based exemptions with expiration dates"
echo "• Audit trails with tickets and review dates"
echo "• Cost impact tracking for FinOps analysis"
echo "• Migration deadlines for existing deployments"
echo ""

echo "🚫 What Developers CAN'T Do (Security Features):"
echo "• Self-exempt through annotations or labels"
echo "• Modify exemption files directly"
echo "• Bypass centralized approval process"
echo "• Create permanent exemptions without review"
echo ""

echo "✅ What FinOps Team CAN Do (Governance Features):"
echo "• Centrally manage all exemptions"
echo "• Set expiration dates and review cycles"
echo "• Track cost impact and business justification"
echo "• Maintain audit trails for compliance"
echo "• Coordinate migration timelines"
echo ""

echo "📊 Step 5: Real-World Usage Scenarios"
echo "====================================="
echo ""

echo "Scenario A: Emergency Deployment"
echo "--------------------------------"
echo "• Developer needs to deploy without assetUuid during incident"
echo "• Contacts FinOps team via emergency escalation"
echo "• FinOps team adds time-based exemption (24-48 hours)"
echo "• Exemption includes incident ticket and approval"
echo "• Automatic expiration forces compliance after emergency"
echo ""

echo "Scenario B: Legacy System Migration"
echo "-----------------------------------"
echo "• Existing deployment lacks proper asset tagging"
echo "• FinOps team grants existing deployment exemption"
echo "• Includes migration deadline and cost impact"
echo "• Regular review cycles ensure progress tracking"
echo "• Exemption removed once migration complete"
echo ""

echo "Scenario C: Critical Infrastructure"
echo "-----------------------------------"
echo "• Core payment processing system needs exemption"
echo "• Requires security team and FinOps approval"
echo "• Permanent exemption with quarterly reviews"
echo "• High-level justification and risk assessment"
echo "• Special handling for regulatory compliance"
echo ""

echo "🎉 Demo Summary"
echo "==============="
echo "This demonstration shows how ACME Payments Inc. achieves:"
echo ""
echo "🔒 Security & Governance:"
echo "• Centralized control over all policy exemptions"
echo "• No self-exemption capabilities for developers"
echo "• Proper approval workflows and authorization"
echo "• Comprehensive audit trails for compliance"
echo ""
echo "📊 FinOps Excellence:"
echo "• Cost impact tracking and analysis"
echo "• Business justification requirements"
echo "• Migration planning and deadlines"
echo "• Regular review and renewal cycles"
echo ""
echo "🏢 Enterprise Features:"
echo "• S3-compatible storage for reliability"
echo "• Professional violation messaging"
echo "• Integration with ticketing systems"
echo "• Escalation procedures for emergencies"
echo ""

echo "📞 Next Steps for Your Organization:"
echo "===================================="
echo "• Customize exemption categories for your needs"
echo "• Integrate with your ticketing/approval systems"
echo "• Set up automated review and expiration workflows"
echo "• Train teams on proper exemption request procedures"
echo "• Establish governance policies and approval matrices"
echo ""

echo "📧 ACME Payments Inc. Contacts:"
echo "• FinOps Team: finops-team@acmepayments.com"
echo "• Emergency Escalation: finops-director@acmepayments.com"
echo "• Documentation: https://wiki.acmepayments.com/finops"
echo "• Training: https://training.acmepayments.com/finops-exemptions"
