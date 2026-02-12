# Phase 1: Environment & Dependency Setup

**Prerequisite**: None

---

## Task 1.1: Update Dependencies

**File(s)**: `SemanticKernelSamples/requirements.txt`
**Action**: Modify

### Current State

The requirements file includes Semantic Kernel and AutoGen packages that will be replaced by the Agent Framework package.

```
# Semantic Kernel
semantic-kernel>=1.0.0

# AutoGen
autogen-agentchat>=0.4.0
autogen-ext[openai]>=0.4.0

# Azure OpenAI
openai>=1.0.0
azure-identity>=1.15.0

# Environment variables
python-dotenv>=1.0.0
```

### Target State

```
# Microsoft Agent Framework
agent-framework --pre

# Azure Identity
azure-identity>=1.15.0

# Environment variables
python-dotenv>=1.0.0
```

### Step-by-Step Instructions

1. Open `SemanticKernelSamples/requirements.txt`.
2. Remove the line `semantic-kernel>=1.0.0` and its comment `# Semantic Kernel`.
3. Remove the lines `autogen-agentchat>=0.4.0` and `autogen-ext[openai]>=0.4.0` and the comment `# AutoGen`.
4. Remove the line `openai>=1.0.0` and its comment `# Azure OpenAI`.
5. Add a comment `# Microsoft Agent Framework` followed by the line `agent-framework --pre`.
6. Keep `azure-identity>=1.15.0` (update comment to `# Azure Identity`).
7. Keep `python-dotenv>=1.0.0` and its comment unchanged.

### Verification

- [ ] `requirements.txt` contains only `agent-framework --pre`, `azure-identity>=1.15.0`, and `python-dotenv>=1.0.0`
- [ ] No references to `semantic-kernel`, `autogen-agentchat`, `autogen-ext`, or `openai` remain
- [ ] `pip install -r requirements.txt` succeeds in a clean virtual environment

---

## Task 1.2: Update Environment Configuration

**File(s)**: `SemanticKernelSamples/.env.example`
**Action**: Modify

### Current State

The `.env.example` uses Azure OpenAI-specific variable names with an API key.

```env
# Azure OpenAI Configuration
AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key-here
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4o
```

### Target State

The target uses Azure AI Foundry variable names. `DefaultAzureCredential` replaces the API key (Azure CLI login or managed identity). Legacy variables are documented as fallbacks.

```env
# Azure AI Foundry Configuration (preferred)
FOUNDRY_PROJECT_ENDPOINT=https://your-project.services.ai.azure.com/
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-4o

# Legacy Azure OpenAI fallback (optional — used if Foundry vars are not set)
# AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/
# AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4o

# Authentication: Uses DefaultAzureCredential (Azure CLI, Managed Identity, etc.)
# No API key needed — run `az login` for local development
```

### Step-by-Step Instructions

1. Open `SemanticKernelSamples/.env.example`.
2. Replace the entire content with the target state above.
3. Remove the `AZURE_OPENAI_API_KEY` variable — MAF uses `DefaultAzureCredential` instead.
4. Add `FOUNDRY_PROJECT_ENDPOINT` and `FOUNDRY_MODEL_DEPLOYMENT_NAME` as the primary variables.
5. Comment out the legacy `AZURE_OPENAI_ENDPOINT` and `AZURE_OPENAI_DEPLOYMENT_NAME` as optional fallbacks.
6. Add a comment explaining that authentication uses `DefaultAzureCredential`.

### Verification

- [ ] `.env.example` contains `FOUNDRY_PROJECT_ENDPOINT` and `FOUNDRY_MODEL_DEPLOYMENT_NAME` as uncommented primary variables
- [ ] `AZURE_OPENAI_API_KEY` is no longer present (neither commented nor uncommented)
- [ ] Legacy Azure OpenAI variables are present but commented out as fallbacks
- [ ] A comment explains `DefaultAzureCredential` usage
