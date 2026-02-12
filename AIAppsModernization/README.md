# AI Agent Code Modernizer

Un agente de IA que moderniza código de agentes creados con **Semantic Kernel** o **AutoGen** a **Microsoft Agent Framework**.

Este agente está expuesto como **MCP (Model Context Protocol) Server** para poder usarlo directamente desde **GitHub Copilot Chat** en Visual Studio Code.

## 🚀 Características

- **Análisis de código**: Detecta automáticamente si el código usa Semantic Kernel o AutoGen
- **Identificación de patrones**: Identifica patrones específicos de cada framework
- **Generación de código**: Genera código equivalente usando Microsoft Agent Framework
- **Guías de migración**: Proporciona documentación detallada de migración
- **Integración con GitHub Copilot**: Funciona como herramienta MCP en Copilot Chat

## 📋 Requisitos Previos

1. **Python 3.10+**
2. **Azure AI Foundry Project** con un modelo desplegado (ej. gpt-4o)
3. **Visual Studio Code** con GitHub Copilot
4. **AI Toolkit Extension** (opcional, para debugging)

## 🛠️ Instalación

### 1. Crear entorno virtual

```powershell
cd AIAppsModernization
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

### 2. Instalar dependencias

```powershell
pip install -r requirements.txt
```

### 3. Configurar credenciales

Copia `.env.example` a `.env` y configura tus credenciales:

```bash
cp .env.example .env
```

Edita `.env`:
```
FOUNDRY_PROJECT_ENDPOINT=https://tu-proyecto.cognitiveservices.azure.com/
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4o
```

### 4. Autenticación con Azure

```powershell
az login
```

## 🎮 Uso

### Opción 1: Como herramienta MCP en GitHub Copilot Chat (Recomendado)

1. **Configura el MCP Server** en VS Code:

   El archivo `.vscode/mcp.json` ya está configurado. Verifica que existe:

   ```json
   {
       "mcpServers": {
           "code-modernizer": {
               "command": "python",
               "args": ["main.py"],
               "cwd": "${workspaceFolder}/AIAppsModernization"
           }
       }
   }
   ```

2. **Abre GitHub Copilot Chat** (Ctrl+Shift+I o Cmd+Shift+I)

3. **Usa el agente** preguntando sobre modernización de código:
   
   ```
   @code-modernizer Analiza este código de Semantic Kernel y ayúdame a migrarlo:
   
   [pega tu código aquí]
   ```

### Opción 2: Modo CLI (para pruebas)

```powershell
python main.py --cli
```

Ejemplo de uso:
```
You: dame la guía de migración de semantic kernel
Assistant: [Genera la guía completa de migración]

You: analiza este código:
from semantic_kernel import Kernel
...
Assistant: [Analiza y detecta los patrones]
```

### Opción 3: HTTP Server (para debugging con Agent Inspector)

```powershell
python main.py --server
```

O usa F5 en VS Code con la configuración "Debug HTTP Server".

## 📁 Estructura del Proyecto

```
AIAppsModernization/
├── main.py                 # Entry point (MCP/HTTP/CLI)
├── modernizer_agent.py     # Definición del agente
├── tools.py                # Herramientas de análisis y modernización
├── requirements.txt        # Dependencias
├── .env.example            # Ejemplo de configuración
├── .env                    # Tu configuración (no commitear)
├── README.md               # Este archivo
└── .vscode/
    ├── launch.json         # Configuración de debugging
    ├── tasks.json          # Tareas de VS Code
    └── mcp.json            # Configuración MCP para Copilot
```

## 🔧 Herramientas Disponibles

El agente expone las siguientes herramientas:

### `analyze_code_patterns`
Analiza código fuente para identificar patrones de Semantic Kernel o AutoGen.

**Entrada**: Código fuente
**Salida**: Framework detectado, patrones encontrados, notas de modernización

### `generate_modernized_code`
Genera código equivalente usando Microsoft Agent Framework.

**Entrada**: Código original + framework fuente
**Salida**: Código modernizado con checklist de migración

### `get_migration_guide`
Proporciona guía completa de migración.

**Entrada**: Framework fuente ('semantic_kernel' o 'autogen')
**Salida**: Guía detallada con ejemplos de código

## 🔍 Ejemplos

### Migrar código de Semantic Kernel

```
Analiza y moderniza este código de Semantic Kernel:

from semantic_kernel import Kernel
from semantic_kernel.functions import kernel_function

kernel = Kernel()

@kernel_function(name="greet", description="Greet someone")
def greet(name: str) -> str:
    return f"Hello, {name}!"
```

### Migrar código de AutoGen

```
Ayúdame a migrar este código de AutoGen a Agent Framework:

from autogen import AssistantAgent, UserProxyAgent

assistant = AssistantAgent(
    name="assistant",
    system_message="You are a helpful assistant."
)

user_proxy = UserProxyAgent(
    name="user_proxy",
    human_input_mode="ALWAYS"
)

user_proxy.initiate_chat(assistant, message="Hello!")
```

## 🐛 Debugging

1. Presiona **F5** en VS Code
2. Selecciona "Debug HTTP Server (with Agent Inspector)"
3. Se abrirá el Agent Inspector automáticamente
4. Prueba el agente con diferentes códigos

## 📚 Recursos

- [Microsoft Agent Framework Documentation](https://github.com/microsoft/agent-framework)
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
- [GitHub Copilot Extensions](https://docs.github.com/en/copilot)
- [Azure AI Foundry](https://azure.microsoft.com/products/ai-foundry)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request.

## 📄 Licencia

MIT License - Copyright (c) Microsoft Corporation
