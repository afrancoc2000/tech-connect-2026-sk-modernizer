# Quick Reference Guide - AI Apps Modernizer Infrastructure

## 📋 Files in This Directory

| File | Purpose |
|------|---------|
| `template.json` | Complete ARM template with all Azure resources |
| `parameters.json` | Default parameter values |
| `deploy.html` | Web-based deployment UI (open in browser) |
| `deploy-infrastructure.ps1` | PowerShell deployment script (Windows) |
| `deploy-summary.sh` | Bash script to view deployment status |
| `docker-compose.yml` | Local development environment |
| `Dockerfile` | Container image definition |
| `nginx.conf` | API Gateway configuration |
| `prometheus.yml` | Monitoring configuration |
| `DEPLOYMENT_GUIDE.md` | Detailed deployment documentation |
| `QUICK_REFERENCE.md` | This file |
| `TROUBLESHOOTING.md` | Common issues and solutions |

## 🚀 Quick Deploy (5 minutes)

### Option 1: Web UI (Easiest)
```
Open: deploy.html in your web browser
Click: Deploy to Azure button
```

### Option 2: PowerShell (Windows)
```powershell
.\deploy-infrastructure.ps1 -ProjectName "aiappsmod" -Environment "poc"
```

### Option 3: Bash (Linux/Mac)
```bash
bash ./deploy-infrastructure.sh
```

### Option 4: Azure CLI (Manual)
```bash
# Variables
PROJECT="aiappsmod"
ENV="poc"
LOCATION="eastus"
RG="rg-$PROJECT-$ENV"

# Create and deploy
az group create --name $RG --location $LOCATION
az deployment group create --resource-group $RG --template-file template.json --parameters parameters.json
```

## 🔧 Common Tasks

### View Deployment Status
```bash
az group list -o table
az deployment group list --resource-group $RG -o table
```

### Check Container Logs
```bash
az container logs --resource-group $RG --name aiappsmod-poc-container-0
```

### Push Image to Container Registry
```bash
# Build
docker build -t ai-modernizer:latest ../AIAppsModernization

# Get ACR name and login
ACR=$(az acr list --resource-group $RG --query "[0].name" -o tsv)
az acr login --name $ACR

# Tag and push
docker tag ai-modernizer:latest $ACR.azurecr.io/ai-modernizer:v1.0
docker push $ACR.azurecr.io/ai-modernizer:v1.0
```

### Update Container Image
```bash
az container create \
  --resource-group $RG \
  --name aiappsmod-poc-container-new \
  --image $ACR.azurecr.io/ai-modernizer:v1.0 \
  --cpu 2 --memory 1.5
```

### Get Resource Endpoints
```bash
# API Management endpoint
az apim show --resource-group $RG --name $APIM_NAME --query "*.URL"

# Azure OpenAI endpoint
az cognitiveservices account show --resource-group $RG --name $OAI_NAME --query "properties.endpoint"

# Container Registry login server
az acr show --resource-group $RG --name $ACR --query "loginServer"
```

### Access Key Vault Secrets
```bash
KV=$(az keyvault list --resource-group $RG --query "[0].name" -o tsv)

# List secrets
az keyvault secret list --vault-name $KV

# Get specific secret
az keyvault secret show --vault-name $KV --name my-secret
```

## 📊 Resource Naming Convention

All resources follow this pattern:
```
{projectName}-{environment}-{resourceType}[-suffix]
```

Examples with `projectName=aiappsmod` and `environment=poc`:
- Virtual Network: `aiappsmod-poc-vnet`
- Container Registry: `aiappmodpocacr1a2b3` (no hyphens)
- API Management: `aiappsmod-poc-apim`
- Key Vault: `aiappsmod-poc-kv-1a2b3`
- Container Group: `aiappsmod-poc-container-0`

## 🌐 Network Configuration

**VNet Address Space**: 10.0.0.0/16

| Subnet | CIDR | Purpose |
|--------|------|---------|
| AKS/Containers | 10.0.1.0/24 | Container instances |
| APIM | 10.0.2.0/24 | API Management |
| Database | 10.0.3.0/24 | Database services |

**Security Groups**:
- Inbound: HTTP (80), HTTPS (443), APIM Mgmt (3443)
- Outbound: All allowed (configurable)

## 💾 Backup & Restore

### Export Configuration
```bash
RG="rg-aiappsmod-poc"

# Export template and parameters
az group export --name $RG > backup-template.json
az deployment group show --resource-group $RG > backup-deployment.json
```

### Redeploy from Backup
```bash
az deployment group create \
  --resource-group $RG \
  --template-file backup-template.json
```

## 🧹 Cleanup

### Delete Resource Group (Everything)
```bash
az group delete --name $RG --yes --no-wait
```

### Delete Specific Resource
```bash
# Delete container
az container delete --resource-group $RG --name container-name --yes

# Delete storage account
az storage account delete --resource-group $RG --name storagename --yes
```

## 📈 Scale Up

### More Container Instances
Edit `parameters.json`:
```json
{
  "containerInstances": { "value": 5 }
}
```

### Upgrade API Management
Edit `parameters.json`:
```json
{
  "apiManagementSku": { "value": "Standard" }
}
```

### Increase Container Resources
Edit `parameters.json`:
```json
{
  "vmSize": { "value": "4" },
  "memoryInGb": { "value": "4.0" }
}
```

## 🔐 Security Checklist

- [ ] All secrets stored in Key Vault (not in code)
- [ ] Managed Identity configured for service access
- [ ] Network ACLs restrict access to resources
- [ ] HTTPS/TLS enabled for all endpoints
- [ ] API Management policies include rate limiting
- [ ] Firewall rules whitelist only required IPs
- [ ] Logging enabled for audit trail
- [ ] Regular backups taken
- [ ] Secrets rotated regularly
- [ ] RBAC roles assigned with least privilege

## 📞 Support Resources

- **Azure Documentation**: https://docs.microsoft.com/azure/
- **Container Instances**: https://docs.microsoft.com/azure/container-instances/
- **API Management**: https://docs.microsoft.com/azure/api-management/
- **Azure AI Foundry**: https://learn.microsoft.com/azure/ai-foundry/
- **GitHub Repository**: https://github.com/afrancoc2000/tech-connect-2026-sk-modernizer

## 🐛 Troubleshooting

Common issues? See: `TROUBLESHOOTING.md`

For detailed deployment information: `DEPLOYMENT_GUIDE.md`

---

**Version**: 1.0.0  
**Last Updated**: February 12, 2026
