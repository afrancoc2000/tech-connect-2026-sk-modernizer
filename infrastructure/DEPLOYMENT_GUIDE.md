# AI Apps Modernizer - Infrastructure Deployment Guide

## Overview

This guide provides instructions for deploying the complete infrastructure for the AI Agent Code Modernizer application on Azure.

## Architecture

The infrastructure includes the following Azure services:

### Network & Security
- **Virtual Network (VNet)**: 10.0.0.0/16
  - Subnet for AKS/Containers: 10.0.1.0/24
  - Subnet for API Management: 10.0.2.0/24
  - Subnet for Database: 10.0.3.0/24
- **Network Security Groups**: Configured firewall rules
- **Managed Identities**: For secure service-to-service authentication

### Compute & Containers
- **Azure Container Registry (ACR)**: Standard tier
  - For storing container images
  - Image retention policy: 30 days
- **Azure Container Instances (ACI)**: Scalable instances
  - CPU: 2 cores, Memory: 1.5 GB (configurable)
  - Number of instances: 2 (configurable)
  - Port: 8000 (HTTP)

### AI & Cognitive Services
- **Azure OpenAI Service**: S0 SKU
  - For running LLM models (gpt-4o)
  - Network isolation with service endpoints
- **Azure AI Foundry**: Hub and Project setup
  - Ready for AI model deployments
  - Integration with OpenAI service

### API & Integration
- **API Management (APIM)**: Developer/Standard SKU
  - Gateway endpoint for the application
  - Application Insights integration
  - Request/response logging
  - Rate limiting and policy enforcement

### Monitoring & Logging
- **Application Insights**: For application performance monitoring
  - 30-day retention
  - Request tracing
  - Exception tracking
- **Log Analytics Workspace**: Centralized logging
  - 30-day retention
  - Query and analytics capabilities

### Storage & Secrets
- **Azure Storage Account**: Standard LRS
  - Blob storage for application data
  - File shares for container volumes
  - Network service endpoints
- **Azure Key Vault**: For secrets management
  - Application credentials
  - API keys
  - Connection strings

## Deployment Options

### Option 1: Deploy via Azure Portal (Recommended for POC)

1. Open [deploy.html](./deploy.html) in a web browser
2. Configure deployment parameters:
   - **Project Name**: Unique identifier (3-11 chars, lowercase)
   - **Environment**: poc, dev, staging, or prod
   - **Azure Region**: Choose your preferred region
   - **Container Instances**: Number of replicas (1-5)
   - **API Management SKU**: Developer (recommended for POC)
3. Click "Deploy to Azure" button
4. You'll be redirected to Azure Portal with the template pre-filled
5. Review and customize parameters if needed
6. Click "Review + Create" → "Create"

### Option 2: Deploy via Azure CLI

```bash
# Set variables
PROJECT_NAME="aiappsmod"
ENVIRONMENT="poc"
LOCATION="eastus"
RESOURCE_GROUP="rg-${PROJECT_NAME}-${ENVIRONMENT}"

# Create resource group
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION

# Deploy template
az deployment group create \
  --name deployment-$(date +%s) \
  --resource-group $RESOURCE_GROUP \
  --template-file template.json \
  --parameters parameters.json \
  --parameters projectName=$PROJECT_NAME \
  --parameters environment=$ENVIRONMENT \
  --parameters location=$LOCATION
```

### Option 3: Deploy via PowerShell

```powershell
# Set variables
$projectName = "aiappsmod"
$environment = "poc"
$location = "eastus"
$resourceGroup = "rg-$projectName-$environment"

# Create resource group
New-AzResourceGroup `
  -Name $resourceGroup `
  -Location $location

# Deploy template
New-AzResourceGroupDeployment `
  -Name "deployment-$(Get-Date -Format 'yyyyMMddHHmmss')" `
  -ResourceGroupName $resourceGroup `
  -TemplateFile "template.json" `
  -TemplateParameterFile "parameters.json" `
  -projectName $projectName `
  -environment $environment `
  -location $location
```

### Option 4: Deploy via GitHub Actions (CI/CD)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths: [infrastructure/**]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Azure
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Template
        uses: azure/arm-deploy@v1
        with:
          subscriptionId: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          resourceGroupName: rg-aiappsmod-poc
          template: infrastructure/template.json
          parameters: infrastructure/parameters.json
```

## Post-Deployment Configuration

### 1. Build and Push Container Image

```bash
# Build Docker image
docker build -t ai-modernizer:latest .

# Tag image for ACR
ACR_LOGIN_SERVER=$(az acr show --resource-group $RESOURCE_GROUP --name acrname --query loginServer -o tsv)
docker tag ai-modernizer:latest $ACR_LOGIN_SERVER/ai-modernizer:latest

# Login to ACR
az acr login --name acrname

# Push image
docker push $ACR_LOGIN_SERVER/ai-modernizer:latest
```

### 2. Update Container Instances with Custom Image

```bash
# Get current container group name
CONTAINER_GROUP=$(az container list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)

# Update with new image (requires redeployment or new container group)
az container create \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_GROUP-new \
  --image $ACR_LOGIN_SERVER/ai-modernizer:latest \
  --cpu 2 \
  --memory 1.5
```

### 3. Configure API Management

#### Add Backend API
```bash
az apim backend create \
  --name apim-name \
  --resource-group $RESOURCE_GROUP \
  --url "http://container-instance:8000"
```

#### Create API in APIM
```bash
az apim api create \
  --name aimodernizer-api \
  --resource-group $RESOURCE_GROUP \
  --display-name "AI Modernizer API" \
  --path /api \
  --protocols http https
```

### 4. Set Azure Key Vault Secrets

```bash
KV_NAME=$(az keyvault list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)

# Store Azure OpenAI credentials
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "azure-openai-key" \
  --value "your-key-here"

az keyvault secret set \
  --vault-name $KV_NAME \
  --name "azure-openai-endpoint" \
  --value "https://your-openai.openai.azure.com/"

# Store ACR credentials
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "acr-username" \
  --value "username"

az keyvault secret set \
  --vault-name $KV_NAME \
  --name "acr-password" \
  --value "password"
```

### 5. Configure Environment Variables

Update the container instances with environment variables:

```bash
# Via environment file
cat > .env << EOF
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4o
AZURE_OPENAI_KEY=$(az keyvault secret show --vault-name $KV_NAME --name "azure-openai-key" --query value -o tsv)
AZURE_OPENAI_ENDPOINT=$(az keyvault secret show --vault-name $KV_NAME --name "azure-openai-endpoint" --query value -o tsv)
EOF
```

## Naming Conventions

The templates use the following naming convention:
```
{projectName}-{environment}-{resourceType}[-suffix]
```

Examples:
- `aiappsmod-poc-vnet` - Virtual Network
- `aiappmodpocacr12345` - Container Registry (no hyphens)
- `aiappsmod-poc-kv-12345` - Key Vault
- `aiappsmod-poc-apim` - API Management
- `aiappsmod-poc-container-0` - Container Instance 0

## Cost Estimation (POC Configuration)

| Resource | SKU | Estimated Cost/Month |
|----------|-----|----------------------|
| Virtual Network | Standard | Free |
| Container Registry | Standard | ~$0.10/day (~$3/month) |
| Container Instances | 2 x 2CPU x 1.5GB | ~$15-20 |
| Azure OpenAI | S0 | Pay-per-use (~$50-100) |
| API Management | Developer | ~$50 |
| Key Vault | Standard | ~$0.34/day (~$10) |
| Storage Account | LRS | ~$0.02/GB (~$5-10) |
| Log Analytics | Pay-as-you-go | Minimal for POC |
| Application Insights | Basic | ~$2/month |
| **Total Estimated** | | **~$140-200/month** |

*Note: Costs vary by region and actual usage. Use Azure Pricing Calculator for accurate estimates.*

## Monitoring & Troubleshooting

### Check Deployment Status

```bash
# View deployment status
az deployment group list \
  --resource-group $RESOURCE_GROUP \
  --query "[].{name:name, state:properties.provisioningState}" \
  -o table

# Get detailed deployment operations
az deployment group operation list \
  --resource-group $RESOURCE_GROUP \
  --name deployment-name
```

### View Container Logs

```bash
# Get container logs
az container logs \
  --resource-group $RESOURCE_GROUP \
  --name container-group-name

# Stream logs
az container logs \
  --resource-group $RESOURCE_GROUP \
  --name container-group-name \
  --follow
```

### Monitor Application Insights

1. Navigate to Application Insights resource in Azure Portal
2. View real-time metrics dashboard
3. Check failed requests and exceptions
4. Analyze performance counters

### Check Key Vault Access

```bash
# List secrets
az keyvault secret list \
  --vault-name $KV_NAME \
  --query "[].name" -o table

# Verify MSI permissions
az keyvault show \
  --vault-name $KV_NAME \
  --query properties.accessPolicies
```

## Security Best Practices

1. **Network Security**
   - VNet is configured with service endpoints
   - NSG rules restrict inbound traffic
   - Private endpoints recommended for production

2. **Secrets Management**
   - All secrets stored in Key Vault
   - Managed identity for authentication
   - No hardcoded credentials

3. **Access Control**
   - RBAC roles assigned to service principal
   - Least privilege principle applied
   - Audit logging enabled

4. **Encryption**
   - TLS 1.2+ enforced on storage
   - Data at rest encrypted
   - HTTPS for API Management

## Scaling & Customization

### Increase Container Instances

Update `parameters.json`:
```json
{
  "containerInstances": {
    "value": 5
  }
}
```

### Change API Management SKU

```json
{
  "apiManagementSku": {
    "value": "Standard"
  }
}
```

### Adjust Container Resources

```json
{
  "vmSize": {
    "value": "4"
  },
  "memoryInGb": {
    "value": "4.0"
  }
}
```

## Clean Up Resources

To delete all resources and avoid charges:

```bash
# Delete resource group (deletes all resources)
az group delete \
  --name $RESOURCE_GROUP \
  --yes \
  --no-wait

# Or delete individual resources
az acr delete --name acrname --resource-group $RESOURCE_GROUP --yes
az container delete --name container-name --resource-group $RESOURCE_GROUP --yes
az keyvault delete --name kvname --resource-group $RESOURCE_GROUP --yes
```

## Support & Resources

- [Azure ARM Templates Documentation](https://docs.microsoft.com/azure/azure-resource-manager/templates/)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)
- [Azure Portal](https://portal.azure.com)
- [GitHub Repository](https://github.com/afrancoc2000/tech-connect-2026-sk-modernizer)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Feb 2026 | Initial release with complete infrastructure |

---

**Last Updated**: February 12, 2026  
**Maintained By**: Cloud Architecture Team
