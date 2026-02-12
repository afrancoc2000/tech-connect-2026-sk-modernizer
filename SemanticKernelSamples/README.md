# 🎭 Agentes de Chistes - Semantic Kernel y AutoGen

Ejemplos de agentes simples que cuentan chistes usando **Semantic Kernel** y **AutoGen**.

## 📋 Requisitos

- Python 3.10+
- Cuenta de Azure con Azure OpenAI configurado

## 🚀 Instalación

```bash
# Crear y activar entorno virtual
python -m venv .venv
.venv\Scripts\activate  # Windows
# source .venv/bin/activate  # Linux/Mac

# Instalar dependencias
pip install -r requirements.txt
```

## ⚙️ Configuración

Crea un archivo `.env` en esta carpeta con las siguientes variables:

```env
AZURE_OPENAI_ENDPOINT=https://tu-recurso.openai.azure.com/
AZURE_OPENAI_API_KEY=tu-api-key
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4o
```

## 🎤 Agente con Semantic Kernel

El agente de Semantic Kernel usa plugins con funciones que el modelo puede llamar:

```bash
python joke_agent_sk.py
```

**Características:**
- Plugin `JokePlugin` con funciones para obtener temas y calificar chistes
- Historial de conversación
- Function calling automático

**Ejemplo de uso:**
```
Tú: Cuéntame un chiste
🤖 Agente: [Obtiene un tema aleatorio y cuenta un chiste]
```

## 🤖 Agente con AutoGen

El agente de AutoGen usa un sistema multi-agente con un comediante y un crítico:

```bash
python joke_agent_autogen.py
```

**Características:**
- **Comediante**: Cuenta chistes usando un tema aleatorio
- **Crítico**: Evalúa y califica los chistes
- Chat round-robin entre agentes
- Herramientas para generar temas y calificar

**Ejemplo de uso:**
```
Tú: Cuéntame un chiste de programación
---------- Comediante ----------
[Cuenta un chiste]
---------- Critico ----------
[Califica el chiste]
```

## 📁 Estructura

```
SemanticKernelSamples/
├── joke_agent_sk.py      # Agente con Semantic Kernel
├── joke_agent_autogen.py # Agente con AutoGen
├── requirements.txt      # Dependencias
└── README.md            # Este archivo
```

## 🔑 Diferencias clave

| Aspecto | Semantic Kernel | AutoGen |
|---------|-----------------|---------|
| Enfoque | Plugins y funciones | Multi-agente |
| Llamada a funciones | `FunctionChoiceBehavior` | `FunctionTool` |
| Conversación | `ChatHistory` | `RoundRobinGroupChat` |
| Terminación | Manual | `TextMentionTermination` |

## 📝 Notas

- Ambos agentes usan Azure OpenAI, pero pueden adaptarse para usar OpenAI directamente
- Los chistes se generan en español
- Los temas se seleccionan aleatoriamente de una lista predefinida
