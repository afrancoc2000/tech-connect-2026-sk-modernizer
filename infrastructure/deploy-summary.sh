#!/bin/bash
# AI Apps Modernizer Infrastructure Summary
# This script generates a summary of the deployed infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}┌──────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│   AI Apps Modernizer - Infrastructure Deployment Summary     │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Azure CLI is not installed. Please install it first.${NC}"
    echo "   Visit: https://docs.microsoft.com/cli/azure/"
    exit 1
fi

# Check if user is logged in
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  You are not logged in to Azure.${NC}"
    echo -e "${YELLOW}   Running: az login${NC}"
    az login
    echo ""
fi

# Get current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo -e "${GREEN}✓${NC} Subscription: ${BLUE}${SUBSCRIPTION}${NC}"
echo -e "${GREEN}✓${NC} Subscription ID: ${BLUE}${SUBSCRIPTION_ID}${NC}"
echo -e "${GREEN}✓${NC} Tenant ID: ${BLUE}${TENANT_ID}${NC}"
echo ""

# Get resource groups
echo -e "${BLUE}📦 Resource Groups:${NC}"
RESOURCE_GROUPS=$(az group list --query "[].{name:name, location:location, count:name}" -o tsv)
if [ -z "$RESOURCE_GROUPS" ]; then
    echo -e "${YELLOW}   No resource groups found${NC}"
else
    echo "$RESOURCE_GROUPS" | awk '{printf "   • %s (%s)\n", $1, $2}'
fi
echo ""

# Check for AI Apps Modernizer specific resources
PATTERN="*aiappsmod*"
RG_COUNT=$(az group list --query "length([])" -o json)

if [ "$RG_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  No resource groups found for deployment${NC}"
    echo ""
    echo -e "${BLUE}To deploy infrastructure:${NC}"
    echo "  1. Open deploy.html in your web browser"
    echo "  2. Configure parameters"
    echo "  3. Click 'Deploy to Azure'"
    echo ""
    echo -e "${BLUE}Or use CLI:${NC}"
    echo "  az deployment group create \\"
    echo "    --resource-group rg-aiappsmod-poc \\"
    echo "    --template-file template.json \\"
    echo "    --parameters parameters.json"
else
    echo -e "${BLUE}📊 Container Instances:${NC}"
    CONTAINERS=$(az container list --query "[].{name:name, resourceGroup:resourceGroup, state:instanceView.state, port:ports[0].port}" -o tsv 2>/dev/null || echo "")
    if [ -z "$CONTAINERS" ]; then
        echo -e "${YELLOW}   No container instances found${NC}"
    else
        echo "$CONTAINERS" | awk '{printf "   • %s (%s) - State: %s, Port: %s\n", $1, $2, $3, $4}'
    fi
    echo ""

    echo -e "${BLUE}🔐 Key Vaults:${NC}"
    VAULTS=$(az keyvault list --query "[].{name:name, resourceGroup:resourceGroup, location:location}" -o tsv 2>/dev/null || echo "")
    if [ -z "$VAULTS" ]; then
        echo -e "${YELLOW}   No Key Vaults found${NC}"
    else
        echo "$VAULTS" | awk '{printf "   • %s (%s) - %s\n", $1, $3, $2}'
    fi
    echo ""

    echo -e "${BLUE}🐳 Container Registries:${NC}"
    REGISTRIES=$(az acr list --query "[].{name:name, resourceGroup:resourceGroup, loginServer:loginServer}" -o tsv 2>/dev/null || echo "")
    if [ -z "$REGISTRIES" ]; then
        echo -e "${YELLOW}   No Container Registries found${NC}"
    else
        echo "$REGISTRIES" | awk '{printf "   • %s (%s) - %s\n", $1, $3, $2}'
    fi
    echo ""

    echo -e "${BLUE}⚙️  API Management Services:${NC}"
    APIMS=$(az apim list --query "[].{name:name, resourceGroup:resourceGroup, tier:sku.name}" -o tsv 2>/dev/null || echo "")
    if [ -z "$APIMS" ]; then
        echo -e "${YELLOW}   No API Management services found${NC}"
    else
        echo "$APIMS" | awk '{printf "   • %s (%s) - %s\n", $1, $3, $2}'
    fi
    echo ""

    echo -e "${BLUE}🤖 Cognitive Services:${NC}"
    COGNITIVE=$(az cognitiveservices account list --query "[].{name:name, resourceGroup:resourceGroup, kind:kind}" -o tsv 2>/dev/null || echo "")
    if [ -z "$COGNITIVE" ]; then
        echo -e "${YELLOW}   No Cognitive Services found${NC}"
    else
        echo "$COGNITIVE" | awk '{printf "   • %s (%s) - %s\n", $1, $3, $2}'
    fi
    echo ""
fi

echo -e "${BLUE}📚 Documentation:${NC}"
echo "   • Infrastructure Guide: DEPLOYMENT_GUIDE.md"
echo "   • Architecture Diagram: See README.md"
echo "   • Source Code: https://github.com/afrancoc2000/tech-connect-2026-sk-modernizer"
echo ""

echo -e "${BLUE}🔗 Useful Commands:${NC}"
echo "   # View container logs"
echo "   az container logs --name <container-name> --resource-group <rg-name>"
echo ""
echo "   # Get container details"
echo "   az container show --name <container-name> --resource-group <rg-name>"
echo ""
echo "   # Update container image"
echo "   az container create --resource-group <rg> --name <name> --image <image-uri>"
echo ""
echo "   # Delete resource group (WARNING: deletes all resources)"
echo "   az group delete --name <rg-name> --yes --no-wait"
echo ""

echo -e "${GREEN}✓${NC} Summary complete!"
echo ""
