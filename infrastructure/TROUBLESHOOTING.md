# Troubleshooting Guide - AI Apps Modernizer Infrastructure

## 🔍 Common Issues & Solutions

### Deployment Issues

#### ❌ Error: "Deployment provisioning failed"

**Symptoms**: Deployment failed with no clear error message

**Solutions**:
1. Check resource group deployment history:
   ```bash
   az deployment group operation list --resource-group $RG --name deployment-name
   ```

2. Look for specific resource failures:
   ```bash
   az deployment group operation list --resource-group $RG --name deployment-name --query "[?properties.statusCode != '200' && properties.statusCode != '201']"
   ```

3. Verify quota limits:
   ```bash
   az vm usage list --location $LOCATION -o table
   ```

4. Check Azure status: https://status.azure.com/

---

#### ❌ Error: "Invalid template format"

**Symptoms**: "InvalidTemplate" error during deployment

**Solutions**:
1. Validate template syntax:
   ```bash
   az deployment group validate --template-file template.json --parameters parameters.json
   ```

2. Check JSON formatting:
   ```bash
   jq empty template.json  # If jq installed
   ```

3. Ensure all required parameters are provided:
   ```bash
   # Check parameter defaults in template.json
   ```

---

#### ❌ Error: "Insufficient quota"

**Symptoms**: "QuotaExceeded" or "ResourceQuotaExceeded"

**Solutions**:
1. Check current quota usage:
   ```bash
   az compute vm usage list --location $LOCATION -o table
   ```

2. Request quota increase:
   - Azure Portal → Subscriptions → Usage + quotas
   - Select resource type and request increase

3. Reduce resource count in parameters.json:
   ```json
   {
     "containerInstances": { "value": 2 },
     "apiManagementSku": { "value": "Developer" }
   }
   ```

---

#### ❌ Error: "Resource name already exists"

**Symptoms**: "NameAlreadyInUse" or similar error

**Solutions**:
1. Use unique project name:
   ```bash
   projectName="aiappsmod$(date +%s | tail -c 4)"
   ```

2. Check existing resources:
   ```bash
   az resource list --query "[].name" -o table | grep aiappsmod
   ```

3. Delete conflicting resources:
   ```bash
   az group delete --name rg-aiappsmod-old --yes --no-wait
   ```

---

### Container Issues

#### ❌ Container stuck in "Creating" state

**Symptoms**: Container remains in "Creating" state for >5 minutes

**Solutions**:
1. Check container logs:
   ```bash
   az container logs --resource-group $RG --name container-name
   ```

2. Verify container image exists:
   ```bash
   az acr repository list --name $ACR_NAME -o table
   ```

3. Delete and recreate container:
   ```bash
   az container delete --resource-group $RG --name container-name --yes
   az container create --resource-group $RG --name container-name \
     --image mcr.microsoft.com/azuredocs/aci-helloworld:latest
   ```

---

#### ❌ Container failed to start

**Symptoms**: Container state is "Failed" or "Terminated"

**Solutions**:
1. Check container logs:
   ```bash
   az container logs --resource-group $RG --name container-name
   ```

2. Verify environment variables:
   ```bash
   az container show --resource-group $RG --name container-name \
     --query "containers[0].environmentVariables" -o json
   ```

3. Check container image:
   ```bash
   docker run -it your-image:latest /bin/bash
   ```

4. Increase resource allocation:
   ```bash
   # Edit parameters.json
   "vmSize": { "value": "4" },
   "memoryInGb": { "value": "2.0" }
   ```

---

#### ❌ Container cannot access Key Vault

**Symptoms**: "AuthenticationFailed" or "AccessDenied" errors in logs

**Solutions**:
1. Verify Managed Identity exists:
   ```bash
   az identity show --resource-group $RG --name aiappsmod-poc-msi
   ```

2. Check Key Vault access policies:
   ```bash
   az keyvault show --resource-group $RG --name $KV_NAME \
     --query "properties.accessPolicies" -o json
   ```

3. Grant MSI access to Key Vault:
   ```bash
   MSI_ID=$(az identity show --resource-group $RG --name aiappsmod-poc-msi \
     --query id -o tsv)
   az keyvault set-policy --name $KV_NAME --secret-permissions get list \
     --object-id $MSI_ID
   ```

---

### Azure OpenAI Issues

#### ❌ "Invalid API key" errors

**Symptoms**: 401 Unauthorized when calling Azure OpenAI

**Solutions**:
1. Verify API key is set correctly:
   ```bash
   az cognitiveservices account keys list --resource-group $RG \
     --name $OPENAI_NAME
   ```

2. Generate new key if needed:
   ```bash
   az cognitiveservices account keys regenerate --resource-group $RG \
     --name $OPENAI_NAME --key-name key1
   ```

3. Update Key Vault secret:
   ```bash
   AZURE_OPENAI_KEY=$(az cognitiveservices account keys list \
     --resource-group $RG --name $OPENAI_NAME --query "key1" -o tsv)
   
   az keyvault secret set --vault-name $KV_NAME \
     --name "azure-openai-key" --value "$AZURE_OPENAI_KEY"
   ```

4. Verify model deployment exists:
   ```bash
   az cognitiveservices account deployment list --resource-group $RG \
     --name $OPENAI_NAME
   ```

---

#### ❌ Model deployment not found

**Symptoms**: "DeploymentNotFound" errors

**Solutions**:
1. Check available deployments:
   ```bash
   az cognitiveservices account deployment list --resource-group $RG \
     --name $OPENAI_NAME -o table
   ```

2. Create deployment in Azure Portal:
   - Resource: Azure OpenAI
   - Deployments → Create new deployment
   - Select gpt-4o model
   - Confirm deployment name matches FOUNDRY_MODEL_DEPLOYMENT_NAME

3. Update environment variable:
   ```bash
   # In container environment variables
   FOUNDRY_MODEL_DEPLOYMENT_NAME=your-deployment-name
   ```

---

### API Management Issues

#### ❌ Cannot access APIM gateway

**Symptoms**: 503 Service Unavailable or timeout

**Solutions**:
1. Check APIM status:
   ```bash
   az apim show --resource-group $RG --name $APIM_NAME \
     --query "properties.provisioningState" -o tsv
   ```

2. Verify backend is configured:
   ```bash
   az apim backend list --resource-group $RG --service-name $APIM_NAME -o table
   ```

3. Check API policies:
   ```bash
   az apim api policy show --resource-group $RG \
     --service-name $APIM_NAME --api-id api-name
   ```

4. Wait for APIM provisioning to complete (can take 30-45 minutes):
   ```bash
   watch -n 5 'az apim show --resource-group $RG --name $APIM_NAME \
     --query "properties.provisioningState" -o tsv'
   ```

---

#### ❌ Backend connection errors

**Symptoms**: Backend return 502/503 errors

**Solutions**:
1. Verify backend endpoint is correct:
   ```bash
   az apim backend show --resource-group $RG \
     --service-name $APIM_NAME --backend-id backend-id
   ```

2. Test container endpoint directly:
   ```bash
   CONTAINER_IP=$(az container show --resource-group $RG \
     --name container-name --query "ipAddress.ip" -o tsv)
   curl http://$CONTAINER_IP:8000/health
   ```

3. Check container logs for errors:
   ```bash
   az container logs --resource-group $RG --name container-name --follow
   ```

4. Update backend URL if container restarted:
   ```bash
   az apim backend delete --resource-group $RG \
     --service-name $APIM_NAME --backend-id old-backend
   
   NEW_IP=$(az container show --resource-group $RG \
     --name container-name --query "ipAddress.ip" -o tsv)
   
   az apim backend create --resource-group $RG \
     --service-name $APIM_NAME \
     --url "http://$NEW_IP:8000"
   ```

---

### Monitoring Issues

#### ❌ No metrics appearing in Application Insights

**Symptoms**: Empty Application Insights dashboard

**Solutions**:
1. Verify Application Insights instrumentation:
   ```bash
   az monitor app-insights component show --resource-group $RG \
     --app $APPINSIGHTS_NAME --query "instrumentationKey" -o tsv
   ```

2. Check if container is sending metrics:
   ```bash
   az container logs --resource-group $RG --name container-name | grep -i "instrumentation\|exception"
   ```

3. Verify network connectivity:
   ```bash
   # Inside container
   curl -I https://dc.applicationinsights.azure.com/health
   ```

4. Wait for initial metrics (can take 5-10 minutes):
   - Azure Portal → Application Insights → Metrics
   - Select "Request duration" or "Request count"

---

#### ❌ Log Analytics queries show no data

**Symptoms**: Empty results when querying logs

**Solutions**:
1. Verify resources are sending logs:
   ```bash
   # In Log Analytics
   StorageBlobLogs
   | take 1000
   ```

2. Check diagnostic settings:
   ```bash
   az monitor diagnostic-settings list --resource $RESOURCE_ID
   ```

3. Enable diagnostic logging:
   ```bash
   az monitor diagnostic-settings create \
     --name logs-to-analytics \
     --resource $RESOURCE_ID \
     --workspace $LOG_ANALYTICS_ID \
     --logs "[{category: 'Requests', enabled: true}]"
   ```

---

### Network Issues

#### ❌ Container cannot reach Azure services

**Symptoms**: "Connection timeout" or "Connection refused"

**Solutions**:
1. Verify network configuration:
   ```bash
   az vnet show --resource-group $RG --name aiappsmod-poc-vnet \
     --query "properties.subnets" -o json
   ```

2. Check service endpoints are enabled:
   ```bash
   az network vnet subnet show --resource-group $RG \
     --vnet-name aiappsmod-poc-vnet \
     --name aiappsmod-poc-subnet-aks \
     --query "properties.serviceEndpoints" -o json
   ```

3. Verify NSG rules:
   ```bash
   az network nsg rule list --resource-group $RG \
     --nsg-name aiappsmod-poc-nsg -o table
   ```

4. Add service endpoints if missing:
   ```bash
   az network vnet subnet update --resource-group $RG \
     --vnet-name aiappsmod-poc-vnet \
     --name aiappsmod-poc-subnet-aks \
     --service-endpoints Microsoft.KeyVault Microsoft.Storage Microsoft.CognitiveServices
   ```

---

### Performance Issues

#### ❌ Slow responses from container

**Symptoms**: High latency or 504 timeouts

**Solutions**:
1. Check container resource usage:
   ```bash
   az container show --resource-group $RG --name container-name \
     --query "containers[0].resources.requests" -o json
   ```

2. Increase container resources:
   ```bash
   # Edit parameters.json
   "vmSize": { "value": "4" },
   "memoryInGb": { "value": "3.0" }
   ```

3. Enable horizontal scaling:
   ```json
   {
     "containerInstances": { "value": 5 }
   }
   ```

4. Check for resource contention:
   ```bash
   az monitor metrics list --resource $RESOURCE_ID \
     --metric "CpuUsage" --interval PT1M
   ```

---

## 📊 Diagnostic Commands

### View All Resources
```bash
az resource list --resource-group $RG -o table
```

### Check Deployment Status
```bash
az deployment group show --resource-group $RG --name $DEPLOYMENT_NAME \
  --query "properties.provisioningState" -o tsv
```

### View Resource Details
```bash
az $SERVICE show --resource-group $RG --name $RESOURCE_NAME -o json | jq
```

### Stream Container Logs
```bash
az container logs --resource-group $RG --name container-name --follow
```

### View Azure Activity Log
```bash
az monitor activity-log list --resource-group $RG \
  --correlation-id $CORRELATION_ID -o table
```

---

## 🆘 Getting Help

1. **Check logs first**:
   ```bash
   az container logs --resource-group $RG --name container-name
   az deployment group operation list --resource-group $RG --name deployment-name
   ```

2. **Review Azure Portal**:
   - Error details in Deployments section
   - Activity Log for error timestamps
   - Metrics for resource utilization

3. **Community Resources**:
   - Stack Overflow: Tag with `azure`, `arm-templates`
   - Microsoft Q&A: https://learn.microsoft.com/answers/
   - GitHub Issues: https://github.com/afrancoc2000/tech-connect-2026-sk-modernizer/issues

4. **Contact Support**:
   - Azure Support Portal
   - Select "Help + support"
   - Create new support request

---

## 📝 Collecting Diagnostics

To collect diagnostic information for support:

```bash
#!/bin/bash
RG="rg-aiappsmod-poc"
DIAGNOSIS_DIR="./diagnostics-$(date +%Y%m%d-%H%M%S)"

mkdir -p $DIAGNOSIS_DIR

# Collect information
az group show --name $RG > $DIAGNOSIS_DIR/resource-group.json
az resource list --resource-group $RG > $DIAGNOSIS_DIR/resources.json
az deployment group list --resource-group $RG > $DIAGNOSIS_DIR/deployments.json
az deployment group operation list --resource-group $RG --name deployment-name > $DIAGNOSIS_DIR/operations.json
az container list --resource-group $RG -o json > $DIAGNOSIS_DIR/containers.json
az container logs --resource-group $RG --name container-name > $DIAGNOSIS_DIR/container-logs.txt

echo "Diagnostics collected in $DIAGNOSIS_DIR"
```

---

**Last Updated**: February 12, 2026  
**Version**: 1.0.0
