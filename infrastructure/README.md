# Infraestructura

Este directorio contiene la plantilla ARM para desplegar los recursos de infraestructura necesarios:

- Azure Container Registry (ACR)
- Azure Container App (Linux, Python 3.3)
- Azure API Management (APIM)

Usa el botón siguiente para desplegar la plantilla en un *resource group* de Azure:

[![Deploy to Azure](https://azuredeploy.net/deploybutton.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https://raw.githubusercontent.com/afrancoc2000/tech-connect-2026-sk-modernizer/main/infrastructure/template.json)

Notas:

- Ajusta los parámetros (nombres, ubicación, imagen de contenedor) en el portal al desplegar.
- La plantilla crea los recursos en el *resource group* que selecciones en el desplegador del Portal.

---

¿Quieres que también añada un archivo `parameters.json` de ejemplo o un script para desplegar desde la CLI?
