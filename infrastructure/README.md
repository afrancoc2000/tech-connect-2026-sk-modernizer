# Infrastructure as Code - AI Apps Modernizer

This directory contains all the infrastructure definitions for deploying the AI Agent Code Modernizer application to Azure.

## � Deploy to Azure

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fafrancoc2000%2Ftech-connect-2026-sk-modernizer%2Fmain%2Finfrastructure%2Ftemplate.json)
[![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fafrancoc2000%2Ftech-connect-2026-sk-modernizer%2Fmain%2Finfrastructure%2Ftemplate.json)

## 📁 Files Overview

### Modular ARM Templates (Master + Child Templates)
| File | Purpose |
|------|----------|
| **master-template.json** | Master ARM template - orchestrates all child deployments |
| **master-parameters.json** | Parameters for master template deployment |
| **child-network.json** | VNet, NSG, and subnet resources |
| **child-storage.json** | Storage account resources |
| **child-acr.json** | Container Registry resources |
| **child-keyvault.json** | Key Vault resources |
| **child-monitoring.json** | Application Insights & Log Analytics |
| **child-ai-hub.json** | Azure AI Foundry Hub |
| **child-ai-project.json** | Azure AI Foundry Project |
| **child-apim.json** | API Management resources |

### Support & Configuration Files
| File | Purpose |
|------|----------|
| **Dockerfile** | Container image for the AI Modernizer app |
| **docker-compose.yml** | Local development environment setup |
| **DEPLOYMENT_GUIDE.md** | Comprehensive deployment instructions |
| **nginx.conf** | API Management gateway configuration (mock) |
| **prometheus.yml** | Monitoring configuration |

## 🚀 Quick Start

### Option 1: Deploy via Azure Portal (Easiest)

1. Click the **"Deploy to Azure"** button above
2. Configure your parameters in the Azure Portal:
   - Resource Group
   - Location
   - Project Name
   - Environment
3. Click **"Review + Create"**
4. Click **"Create"** to start deployment (~15-20 minutes)

### Option 2: Deploy via CLI

```bash
# Set your project configuration
export PROJECT_NAME="aiappsmod"
export ENVIRONMENT="poc"
export LOCATION="centralus"
export RESOURCE_GROUP="rg-$PROJECT_NAME-$ENVIRONMENT"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Deploy infrastructure using master template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file master-template.json \
  --parameters master-parameters.json \
  --parameters location=$LOCATION \
  --parameters projectName=$PROJECT_NAME environment=$ENVIRONMENT
```

### Option 3: Local Development with Docker Compose

```bash
# Set environment variables
export AZURE_OPENAI_KEY="your-key"
export AZURE_OPENAI_ENDPOINT="https://your-resource.openai.azure.com/"
export ACCOUNT_KEY="DefaultEndpointsProtocol=https;..."

# Start local environment
docker-compose up -d

# Access services:
# - App: http://localhost:8000
# - Registry: http://localhost:5000
# - Grafana: http://localhost:3000 (admin/admin)
# - Prometheus: http://localhost:9090
# - Vault: http://localhost:8200
# - Storage: http://localhost:10000
```

## 🏗️ Deployment Architecture

### Nested Template Structure
The infrastructure uses a **master template** that orchestrates **8 modular child templates**, allowing you to:
- Deploy the complete infrastructure in one command
- Test individual components independently
- Update specific services without redeploying everything
- Clearly see dependencies between services

```
master-template.json
├── child-network.json (VNet, NSG)
├── child-storage.json (Storage Account)
├── child-acr.json (Container Registry)
├── child-keyvault.json (Key Vault)
├── child-monitoring.json (App Insights, Log Analytics)
├── child-ai-hub.json (AI Hub - depends on storage, KV, monitoring)
├── child-ai-project.json (AI Project - depends on hub)
└── child-apim.json (API Management - depends on network)
```

### Resource Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Azure Cloud                           │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Virtual Network (10.0.0.0/16)                       │   │
│  │                                                       │   │
│  │  ┌─────────────────┐  ┌──────────────────────────┐  │   │
│  │  │  Containers     │  │  API Management (APIM)   │  │   │
│  │  │  - Instance 1   │  │                          │  │   │
│  │  │  - Instance 2   │  │  ├─ Gateway              │  │   │
│  │  │                 │  │  ├─ Backend API          │  │   │
│  │  └─────────────────┘  │  └─ Policies             │  │   │
│  │                        └──────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────┐  ┌────────────────┐                   │
│  │ Container        │  │ Azure AI       │                   │
│  │ Registry (ACR)   │  │ Foundry + LLM  │                   │
│  │                  │  │                │                   │
│  │ - Images         │  │ - gpt-4o Model │                   │
│  │ - Repos          │  │ - Deployments  │                   │
│  └──────────────────┘  └────────────────┘                   │
│                                                               │
│  ┌──────────────────┐  ┌────────────────┐                   │
│  │ Key Vault        │  │ Storage        │                   │
│  │                  │  │ Account        │                   │
│  │ - Secrets        │  │                │                   │
│  │ - API Keys       │  │ - Blobs        │                   │
│  │ - Credentials    │  │ - Files        │                   │
│  └──────────────────┘  └────────────────┘                   │
│                                                               │
│  ┌──────────────────┐  ┌────────────────────────────────┐   │
│  │ Monitoring       │  │ Logging                        │   │
│  │                  │  │                                │   │
│  │ - App Insights   │  │ - Log Analytics                │   │
│  │ - Metrics        │  │ - Diagnostic Settings          │   │
│  └──────────────────┘  └────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## 📊 Resource Deployment

### Compute Resources
- **Azure Container Instances**: 2 instances (configurable 1-5)
  - CPU: 2 cores per instance
  - Memory: 1.5 GB per instance
  - Port: 8000

### AI & Cognitive Services
- **Azure OpenAI Service**: S0 SKU
  - Model: gpt-4o
  - Custom subdomain for secure access
- **Azure AI Foundry**: Hub and Project
  - Integration with OpenAI models
  - Ready for additional AI services

### Networking
- **Virtual Network**: 10.0.0.0/16
  - Subnet for containers: 10.0.1.0/24
  - Subnet for APIM: 10.0.2.0/24
  - Subnet for databases: 10.0.3.0/24
- **Network Security Group**: Firewall rules
  - Inbound: HTTP (80), HTTPS (443), APIM management (3443)
  - Outbound: All (can be restricted)

### API Integration
- **API Management**: Developer tier (POC)
  - Gateway URL: `https://{apim-name}.azure-api.net`
  - Application Insights logging enabled
  - Rate limiting and policies configurable

### Storage & Security
- **Container Registry**: Standard tier
  - Private image repository
  - Image retention policy: 30 days
  - Authentication via Managed Identity
- **Key Vault**: Standard tier
  - Secrets management
  - Access policies for Managed Identity
  - Network ACLs configured
- **Storage Account**: Standard LRS
  - Blob storage for logs and data
  - Network service endpoints
  - 30-day retention policies

### Monitoring & Diagnostics
- **Application Insights**: 30-day retention
  - Request tracing
  - Exception tracking
  - Performance monitoring
- **Log Analytics**: 30-day retention
  - Query and analytics
  - Custom logs support
  - Integration with APIM

## 🔐 Security Features

- ✅ **Managed Identities**: No credentials hardcoded
- ✅ **Network Isolation**: VNet with service endpoints
- ✅ **Network Security**: NSG rules restrict traffic
- ✅ **Secrets Management**: Key Vault integration
- ✅ **Encryption**: TLS 1.2+ for all communications
- ✅ **Access Control**: RBAC and access policies
- ✅ **Audit Logging**: All operations logged
- ✅ **Network ACLs**: Firewall rules on resources

## 💰 Cost Estimation (POC)

**Monthly Estimate**: ~$140-200  
*Varies by region and usage patterns*

| Resource | Est. Cost |
|----------|-----------|
| Container Instances | $15-20 |
| API Management (Dev) | $50 |
| Azure OpenAI | $50-100 |
| Container Registry | ~$3 |
| Storage | ~$5-10 |
| Key Vault | ~$10 |
| Log Analytics | Minimal |
| App Insights | ~$2 |

## 📝 Parameters Configuration

### Required Parameters
- `projectName`: (3-11 chars) Unique project identifier
- `environment`: poc, dev, staging, or prod
- `location`: Azure region (eastus, westus2, etc.)

### Optional Parameters
- `containerInstances`: Number of replicas (1-5)
- `apiManagementSku`: Developer, Standard, or Premium
- `containerImageUri`: Custom container image URL
- `skuOpenAI`: Azure OpenAI SKU (S0, S1, etc.)

## 🔧 Customization

### Scaling
Modify `parameters.json`:
```json
{
  "containerInstances": { "value": 5 },
  "apiManagementSku": { "value": "Standard" }
}
```

### Resource Sizing
Update CPU and memory:
```json
{
  "vmSize": { "value": "4" },
  "memoryInGb": { "value": "4.0" }
}
```

### Network Configuration
Edit `template.json` variables:
- `vnetAddressPrefix`: Change VNet IP range
- `subnetAksPrefix`: Change container subnet
- `subnetApimPrefix`: Change APIM subnet

## 🛠️ Post-Deployment Steps

1. **Build & Push Container Image**
   ```bash
   docker build -t ai-modernizer:latest ../AIAppsModernization
   docker tag ai-modernizer:latest $ACR.azurecr.io/ai-modernizer:latest
   docker push $ACR.azurecr.io/ai-modernizer:latest
   ```

2. **Update Container Instances**
   - Update with custom image from ACR
   - Configure environment variables
   - Set Azure OpenAI credentials

3. **Configure API Management**
   - Add backend API endpoint
   - Create API operations
   - Set up rate limiting policies

4. **Test Connectivity**
   - Validate container health
   - Test APIM gateway endpoint
   - Verify Azure OpenAI connectivity

## 📚 Documentation

- See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for detailed deployment instructions
- See [../AIAppsModernization/README.md](../AIAppsModernization/README.md) for application setup
- Azure resources documentation links provided in DEPLOYMENT_GUIDE

## ⚙️ Health Checks

Monitor deployment health:

```bash
# Get container status
az container show --name aiappsmod-poc-container-0 --resource-group $RESOURCE_GROUP

# View container logs
az container logs --name aiappsmod-poc-container-0 --resource-group $RESOURCE_GROUP

# Check APIM status
az apim show --name apim-name --resource-group $RESOURCE_GROUP
```

## 🧹 Cleanup

To remove all resources:

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

## 📞 Support

For issues or questions:
1. Check [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) troubleshooting section
2. Review Azure Portal deployment logs
3. Check container logs: `az container logs --name ... --resource-group ...`
4. Open issue on [GitHub repository](https://github.com/afrancoc2000/tech-connect-2026-sk-modernizer)

## 📄 License

MIT License - Copyright (c) Microsoft Corporation

---

**Version**: 1.0.0  
**Last Updated**: February 12, 2026  
**Maintained By**: Cloud Architecture Team
