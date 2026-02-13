#!/bin/bash
set -e

# ------------------------------------------------------------------
# postprovision.sh — Build image + deploy Container App al CAE
#
# Ejecutado automáticamente por azd como hook postprovision.
# Lee los outputs de Terraform para obtener todos los valores necesarios.
# ------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TF_DIR="$PROJECT_ROOT/infra/terraform"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; exit 1; }

# ------------------------------------------------------------------
# 1. Leer outputs de Terraform
# ------------------------------------------------------------------
log_info "Reading Terraform outputs..."

# azd sets Terraform outputs as env vars automatically in postprovision hooks.
# Fall back to terraform CLI only for standalone execution (deploy-infra.sh).
get_output() {
    local var_name="$1"
    local val="${!var_name}"
    if [ -n "$val" ]; then
        echo "$val"
    else
        terraform -chdir="$TF_DIR" output -raw "$var_name" 2>/dev/null || echo ""
    fi
}

# ACR
export AZURE_ACR_NAME=$(get_output "AZURE_ACR_NAME")
export AZURE_ACR_LOGIN_SERVER=$(get_output "AZURE_ACR_LOGIN_SERVER")

# AI Foundry (env vars for the container at runtime)
export AZURE_AI_PROJECT_ENDPOINT=$(get_output "AZURE_AI_PROJECT_ENDPOINT")
export AZURE_OPENAI_CHAT_DEPLOYMENT_NAME=$(get_output "AZURE_OPENAI_CHAT_DEPLOYMENT_NAME")

# Container App config
export AGENT_NAME=$(get_output "AGENT_NAME")
export AGENT_CPU=$(get_output "AGENT_CPU")
export AGENT_MEMORY=$(get_output "AGENT_MEMORY")

# Container Apps Environment
export CONTAINER_APPS_ENVIRONMENT_NAME=$(get_output "CONTAINER_APPS_ENVIRONMENT_NAME")

# User Assigned Managed Identity
export AGENT_IDENTITY_ID=$(get_output "AGENT_IDENTITY_ID")
export AGENT_IDENTITY_CLIENT_ID=$(get_output "AGENT_IDENTITY_CLIENT_ID")

# General
ENVIRONMENT_NAME=$(get_output "environment_name")
RESOURCE_GROUP=$(get_output "resource_group_name")

# Validar variables críticas
for var in AZURE_ACR_NAME AZURE_ACR_LOGIN_SERVER AZURE_AI_PROJECT_ENDPOINT AGENT_NAME CONTAINER_APPS_ENVIRONMENT_NAME AGENT_IDENTITY_ID AGENT_IDENTITY_CLIENT_ID; do
    if [ -z "${!var}" ]; then
        log_error "Terraform output '$var' is empty. Did you run 'terraform apply'?"
    fi
done

# ------------------------------------------------------------------
# 2. Build y push de la imagen al ACR (tag con timestamp)
# ------------------------------------------------------------------
BUILD_TIMESTAMP=$(date +%Y%m%d%H%M%S)
IMAGE_TAG="${ENVIRONMENT_NAME:-dev}-${BUILD_TIMESTAMP}"
CONTAINER_IMAGE="${AZURE_ACR_LOGIN_SERVER}/agent-flow:${IMAGE_TAG}"
LATEST_TAG="${ENVIRONMENT_NAME:-dev}-latest"

log_info "Building container image: $CONTAINER_IMAGE"

az acr build \
    --registry "$AZURE_ACR_NAME" \
    --image "agent-flow:${IMAGE_TAG}" \
    --image "agent-flow:${LATEST_TAG}" \
    --file "$PROJECT_ROOT/AIAppsModernization/Dockerfile" \
    --resource-group "$RESOURCE_GROUP" \
    "$PROJECT_ROOT/AIAppsModernization"

log_info "Container built and pushed to ACR (tag: $IMAGE_TAG)"

# ------------------------------------------------------------------
# 3. Deploy Container App (create or update)
# ------------------------------------------------------------------
log_info "Deploying Container App: $AGENT_NAME"

# Check if the Container App already exists
APP_EXISTS=$(az containerapp show \
    --name "$AGENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [ -z "$APP_EXISTS" ]; then
    log_info "Creating new Container App..."

    az containerapp create \
        --name "$AGENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --environment "$CONTAINER_APPS_ENVIRONMENT_NAME" \
        --image "$CONTAINER_IMAGE" \
        --registry-server "$AZURE_ACR_LOGIN_SERVER" \
        --registry-identity "$AGENT_IDENTITY_ID" \
        --user-assigned "$AGENT_IDENTITY_ID" \
        --cpu "$AGENT_CPU" \
        --memory "$AGENT_MEMORY" \
        --min-replicas 1 \
        --max-replicas 3 \
        --ingress external \
        --target-port 8088 \
        --env-vars \
            "FOUNDRY_PROJECT_ENDPOINT=$AZURE_AI_PROJECT_ENDPOINT" \
            "FOUNDRY_MODEL_DEPLOYMENT_NAME=$AZURE_OPENAI_CHAT_DEPLOYMENT_NAME" \
            "AZURE_CLIENT_ID=$AGENT_IDENTITY_CLIENT_ID"

    log_info "Container App created successfully"
else
    log_info "Updating existing Container App..."

    az containerapp update \
        --name "$AGENT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --image "$CONTAINER_IMAGE" \
        --set-env-vars \
            "FOUNDRY_PROJECT_ENDPOINT=$AZURE_AI_PROJECT_ENDPOINT" \
            "FOUNDRY_MODEL_DEPLOYMENT_NAME=$AZURE_OPENAI_CHAT_DEPLOYMENT_NAME" \
            "AZURE_CLIENT_ID=$AGENT_IDENTITY_CLIENT_ID"

    log_info "Container App updated successfully"
fi

# ------------------------------------------------------------------
# 4. Obtener FQDN y resumen
# ------------------------------------------------------------------
APP_FQDN=$(az containerapp show \
    --name "$AGENT_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "pending...")

# Persist the agent URL as an azd environment variable so it appears in azd outputs
AGENT_BASE_URL="https://$APP_FQDN"
azd env set AGENT_BASE_URL "$AGENT_BASE_URL" 2>/dev/null || true

echo ""
log_info "Deployment complete!"
echo ""
echo "  App:         $AGENT_NAME"
echo "  Image:       $CONTAINER_IMAGE"
echo "  CPU/Memory:  $AGENT_CPU / $AGENT_MEMORY"
echo "  FQDN:        https://$APP_FQDN"
echo "  Identity:    $AGENT_IDENTITY_ID"
echo ""
echo "  Test endpoints:"
echo "    curl https://$APP_FQDN/liveness"
echo "    curl https://$APP_FQDN/readiness"
echo ""
echo "  Test agent:"
echo "    curl -X POST https://$APP_FQDN/runs \\"
echo "      -H 'Content-Type: application/json' \\"
echo "      -d '{\"input\":[{\"role\":\"user\",\"content\":\"Analiza este codigo: print(hello)\"}]}'"
echo ""
