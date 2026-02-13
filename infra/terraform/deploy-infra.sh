#!/bin/bash

# Deploy script for agent-flow Terraform infrastructure
# Usage: ./deploy-infra.sh <command> [vars_file]
# Commands: init-plan, apply, destroy, refresh

set -e

# Constantes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_VARS_FILE="environments/dev.tfvars.json"
PLAN_FILE="terraform.tfplan"
DESTROY_PLAN_FILE="terraform-destroy.tfplan"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funciones de logging
function log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

function log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

function log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Función de ayuda
function show_help() {
    cat << EOF
Uso: $0 <comando> [vars_file]

Comandos disponibles:
  init-plan   - Inicializa Terraform y crea un plan de ejecución
  apply       - Aplica el plan previamente creado
  refresh     - Refresca el state sin hacer cambios
  destroy     - Crea y aplica un plan de destrucción

Argumentos:
  vars_file   - Archivo de variables (opcional)
                Por defecto: $DEFAULT_VARS_FILE

Ejemplos:
  $0 init-plan
  $0 init-plan environments/stg.tfvars.json
  $0 apply
  $0 destroy environments/prd.tfvars.json

EOF
}

# Validar pre-requisitos
function validate_prerequisites() {
    if [ ! -d "$SCRIPT_DIR" ]; then
        log_error "El directorio de infraestructura no existe: $SCRIPT_DIR"
    fi

    if ! command -v terraform &> /dev/null; then
        log_error "Terraform no está instalado o no está en el PATH"
    fi

    cd "$SCRIPT_DIR" || log_error "No se puede acceder al directorio: $SCRIPT_DIR"
}

# Validar archivo de variables
function validate_vars_file() {
    local vars_file=$1

    if [ ! -f "$vars_file" ]; then
        log_error "El archivo de variables no existe: $vars_file"
    fi

    log_info "Usando archivo de variables: $vars_file"
}

# Init + Plan en un solo paso
function terraform_init_plan() {
    local vars_file=$1

    validate_vars_file "$vars_file"

    log_info "Inicializando Terraform..."
    terraform init -upgrade
    log_info "Inicialización completada exitosamente"

    log_info "Creando plan de ejecución..."
    terraform plan -var-file="$vars_file" -out="$PLAN_FILE"

    log_info "Plan creado exitosamente: $PLAN_FILE"
    log_warn "Para aplicar los cambios, ejecute: $0 apply"
}

# Aplicar plan de Terraform
function terraform_apply() {
    if [ ! -f "$PLAN_FILE" ]; then
        log_error "No se encontró el archivo de plan: $PLAN_FILE. Ejecute primero: $0 init-plan"
    fi

    log_info "Aplicando plan de ejecución: $PLAN_FILE"
    terraform apply "$PLAN_FILE"

    # Limpiar el plan después de aplicarlo
    rm -f "$PLAN_FILE"
    log_info "Plan aplicado exitosamente"
}

# Refrescar state
function terraform_refresh() {
    local vars_file=$1

    validate_vars_file "$vars_file"

    log_info "Refrescando el state de Terraform..."
    terraform apply -refresh-only -var-file="$vars_file" -auto-approve

    log_info "State refrescado exitosamente"
}

# Destruir infraestructura
function terraform_destroy() {
    local vars_file=$1

    validate_vars_file "$vars_file"

    log_warn "¡ADVERTENCIA! Esta operación destruirá la infraestructura"
    read -p "¿Está seguro de continuar? (escriba 'yes' para confirmar): " confirm

    if [ "$confirm" != "yes" ]; then
        log_info "Operación cancelada"
        exit 0
    fi

    log_info "Creando plan de destrucción..."
    terraform plan -destroy -var-file="$vars_file" -out="$DESTROY_PLAN_FILE"

    log_info "Aplicando destrucción..."
    terraform apply "$DESTROY_PLAN_FILE"

    # Limpiar el plan después de aplicarlo
    rm -f "$DESTROY_PLAN_FILE"
    log_info "Destrucción completada exitosamente"
}

# Script principal
function main() {
    local command=$1
    local vars_file=${2:-$DEFAULT_VARS_FILE}

    # Mostrar ayuda si no hay argumentos
    if [ -z "$command" ]; then
        show_help
        exit 1
    fi

    # Validar pre-requisitos
    validate_prerequisites

    # Ejecutar comando
    case "$command" in
        init-plan)
            terraform_init_plan "$vars_file"
            ;;
        apply)
            terraform_apply
            ;;
        refresh)
            terraform_refresh "$vars_file"
            ;;
        destroy)
            terraform_destroy "$vars_file"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Comando inválido: $command"
            show_help
            exit 1
            ;;
    esac
}

# Invocar la función principal
main "$@"
