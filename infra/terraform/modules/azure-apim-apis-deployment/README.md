# Azure API Management - APIs Deployment Module

Este módulo Terraform despliega automáticamente APIs en Azure API Management desde contratos OpenAPI con validación JWT de Entra ID.

## Características

- ✅ **Importación automática** desde archivos OpenAPI (YAML/JSON)
- ✅ **Validación JWT** con Azure AD/Entra ID
- ✅ **Rate limiting** configurable por API
- ✅ **Backends dinámicos** apuntando a Container Apps
- ✅ **Políticas personalizadas** por API
- ✅ **Sin subscription keys** - autenticación únicamente por JWT

## Uso

```hcl
module "apim_apis" {
  source = "./modules/azure-apim-apis-deployment"

  resource_group_name = "rg-demo"
  apim_name           = "apim-demo"
  tenant_id           = "00000000-0000-0000-0000-000000000000"

  backend_apis = {
    claims = {
      name             = "claims-api"
      display_name     = "Claims Backend API"
      path             = "claims/v1"
      protocols        = ["https"]
      openapi_format   = "openapi+json"
      openapi_content  = file("../claims-backend/claims-backend.yaml")
      
      jwt_enabled      = true
      jwt_audience     = "api://my-app"
      jwt_issuer       = "https://sts.windows.net/{tenant}/"
      jwt_required_claims = {}
      
      backend_url      = "https://my-app.azurecontainerapps.io"
      backend_protocol = "http"
      
      rate_limit_calls  = 50
      rate_limit_period = 60
      
      subscription_required   = false
      subscription_key_header = "Ocp-Apim-Subscription-Key"
      subscription_key_query  = "subscription-key"
    }
  }
}
```

## Políticas XML

Las políticas se encuentran en `policies/{api-key}-api.xml` y soportan templating de Terraform.

Variables disponibles en templates:
- `${tenant_id}` - Tenant ID de Azure AD
- `${backend_id}` - ID del backend APIM
- `${jwt_enabled}` - Habilitar/deshabilitar JWT
- `${jwt_audience}` - Audience del token
- `${jwt_issuer}` - Issuer del token
- `${rate_limit_calls}` - Límite de llamadas
- `${rate_limit_period}` - Período de rate limit
- `${required_claims}` - Claims requeridos (map)

## Outputs

- `api_ids` - IDs de las APIs creadas
- `api_urls` - URLs gateway de las APIs
- `backend_ids` - IDs de los backends
- `deployment_summary` - Resumen del despliegue

## Requisitos

- Terraform >= 1.3
- Azure Provider >= 3.0
- API Management existente
- App Registration en Entra ID (para JWT)
