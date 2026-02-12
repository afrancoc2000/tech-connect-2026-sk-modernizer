# AI Apps Modernizer Infrastructure Deployment Script
# PowerShell Script for Azure Deployment
# Usage: .\deploy-infrastructure.ps1 -ProjectName "aiappsmod" -Environment "poc" -Location "eastus"

param(
    [string]$ProjectName = "aiappsmod",
    [string]$Environment = "poc",
    [string]$Location = "eastus",
    [string]$ContainerImage = "",
    [int]$ContainerInstances = 2,
    [string]$ApiSku = "Developer",
    [switch]$Validate,
    [switch]$WhatIf
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Color functions
function Write-Header {
    param([string]$Message)
    Write-Host "`n" -ForegroundColor Green
    Write-Host "╔" + ("═" * ($Message.Length + 2)) + "╗" -ForegroundColor Cyan
    Write-Host "║ $Message ║" -ForegroundColor Cyan
    Write-Host "╚" + ("═" * ($Message.Length + 2)) + "╝" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

# Main script
Write-Header "AI Apps Modernizer - Infrastructure Deployment"

# Validate parameters
Write-Host "`nValidating parameters..."
if ($ProjectName.Length -lt 3 -or $ProjectName.Length -gt 11) {
    Write-Error-Custom "ProjectName must be between 3 and 11 characters"
    exit 1
}

$ValidEnvironments = @("poc", "dev", "staging", "prod")
if ($ValidEnvironments -notcontains $Environment) {
    Write-Error-Custom "Environment must be one of: $($ValidEnvironments -join ', ')"
    exit 1
}

Write-Success "Parameters validated"

# Check Azure CLI
Write-Info "Checking Azure CLI installation..."
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error-Custom "Azure CLI is not installed. Please install it from https://aka.ms/installazurecliwindows"
    exit 1
}
Write-Success "Azure CLI found"

# Check Azure connection
Write-Info "Checking Azure connection..."
try {
    $account = az account show --query name -o tsv
    Write-Success "Connected to Azure subscription: $account"
} catch {
    Write-Warning-Custom "Not connected to Azure. Running 'az login'..."
    az login
}

# Create resource group name
$ResourceGroupName = "rg-$ProjectName-$Environment"
Write-Info "Resource Group: $ResourceGroupName"
Write-Info "Location: $Location"
Write-Info "Container Instances: $ContainerInstances"
Write-Info "API Management SKU: $ApiSku"

# Check if resource group exists
$exists = az group exists --name $ResourceGroupName -o tsv
if ($exists -eq "true") {
    Write-Warning-Custom "Resource group '$ResourceGroupName' already exists"
    $response = Read-Host "Do you want to redeploy? (yes/no)"
    if ($response -ne "yes") {
        Write-Info "Deployment cancelled"
        exit 0
    }
} else {
    Write-Info "Creating resource group '$ResourceGroupName'..."
    az group create `
        --name $ResourceGroupName `
        --location $Location
    Write-Success "Resource group created"
}

# Prepare deployment parameters
Write-Info "Preparing deployment parameters..."
$DeploymentName = "deploy-$(Get-Date -Format 'yyyyMMddHHmmss')"

$Parameters = @{
    projectName = $ProjectName
    environment = $Environment
    location = $Location
    containerInstances = $ContainerInstances
    apiManagementSku = $ApiSku
}

if ($ContainerImage) {
    $Parameters["containerImageUri"] = $ContainerImage
}

# Convert to JSON
$ParametersJson = $Parameters | ConvertTo-Json

# Save parameters to file for reference
$ParametersJson | Out-File -FilePath "./deployment-params-$DeploymentName.json"
Write-Success "Parameters saved to deployment-params-$DeploymentName.json"

# Validate template
if ($Validate) {
    Write-Info "Validating ARM template..."
    $validation = az deployment group validate `
        --resource-group $ResourceGroupName `
        --template-file template.json `
        --parameters $Parameters | ConvertFrom-Json

    if ($validation.error) {
        Write-Error-Custom "Template validation failed:"
        Write-Host $validation.error -ForegroundColor Red
        exit 1
    }
    Write-Success "Template validation passed"
}

# Deploy infrastructure
Write-Info "Deploying infrastructure..."
Write-Host "Deployment name: $DeploymentName" -ForegroundColor Cyan

if ($WhatIf) {
    Write-Warning-Custom "Running in WhatIf mode"
    $result = az deployment group create `
        --resource-group $ResourceGroupName `
        --name $DeploymentName `
        --template-file template.json `
        --parameters $Parameters `
        --what-if
    
    Write-Host $result
    exit 0
}

# Execute deployment
$result = az deployment group create `
    --resource-group $ResourceGroupName `
    --name $DeploymentName `
    --template-file template.json `
    --parameters $Parameters `
    --output json | ConvertFrom-Json

# Check deployment result
if ($LASTEXITCODE -eq 0) {
    Write-Success "Infrastructure deployment completed successfully!"
    
    # Extract outputs
    Write-Header "Deployment Outputs"
    
    $outputs = $result.properties.outputs
    if ($outputs) {
        foreach ($key in $outputs.PSObject.Properties.Name) {
            $value = $outputs.$key.value
            Write-Info "$key`: $value"
        }
    }
    
    # Show next steps
    Write-Header "Next Steps"
    Write-Host "
1. Build and push container image:
   docker build -t ai-modernizer:latest ../AIAppsModernization
   docker tag ai-modernizer:latest <acr-name>.azurecr.io/ai-modernizer:latest
   docker push <acr-name>.azurecr.io/ai-modernizer:latest

2. Update container instances with your image
3. Configure API Management backend
4. Set environment variables in Key Vault
5. Monitor deployment in Azure Portal

Resource Group: $ResourceGroupName
Portal URL: https://portal.azure.com/#resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$ResourceGroupName
" -ForegroundColor Cyan
    
    Write-Success "Deployment complete!"
} else {
    Write-Error-Custom "Deployment failed"
    exit 1
}
