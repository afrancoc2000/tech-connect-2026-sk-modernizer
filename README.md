# 🧠 AI Agent Code Modernizer

**Track:** Reasoning Agents with Microsoft Foundry — [Agents League @ TechConnect 2026](https://github.com/microsoft/agentsleague-techconnect)  
**Starter Kit:** [2-reasoning-agents](https://github.com/microsoft/agentsleague-techconnect/tree/main/starter-kits/2-reasoning-agents)

An MCP-exposed AI agent that analyzes code written with **Semantic Kernel** or **AutoGen** and modernizes it to **Microsoft Agent Framework (MAF)**. Built to integrate with the [Agent Portal](https://github.com/misantibanez/AI-MAF-AGENT-CREATION) as an MCP tool, or used standalone via CLI/MCP in VS Code.

> This project was built with AI assistance using GitHub Copilot.

## 👥 Team

| Name | Alias |
|------|-------|
| Michelle Santibañez | michelle.santibanez@microsoft.com |
| Valentina G. | valentinag@microsoft.com |
| Emilio Raggi | emilioraggi@microsoft.com |
| Ana Franco | anafranco@microsoft.com |
| Jesus Sanchez | jesussan@microsoft.com |

## 🏗️ Architecture

![Architecture Diagram](docs/architecture.png)

The modernizer can be consumed in two ways:

1. **Via Agent Factory Portal** — The portal discovers and invokes the modernizer as a remote MCP tool, enabling no-code agent creation that includes code migration capabilities.
2. **Directly from VS Code** — Developers configure the MCP server in `.vscode/mcp.json` and use it through GitHub Copilot Chat or the CLI.

### Infrastructure

| Resource | Purpose |
|----------|---------|
| Azure AI Foundry | Hosts the reasoning model (GPT-5.1) powering the agent |
| Azure Container Apps | Hosts the modernizer MCP server (port 8088) |
| Azure API Management | Exposes and secures the MCP endpoint with Streamable HTTP transport |
| Azure Container Registry | Stores container images (multi-stage Docker build) |
| Virtual Network + NSG | Network isolation per environment with dedicated subnets for CAE and APIM |
| User-Assigned Managed Identity | Keyless authentication between Container App, ACR, and AI Foundry |

## 🔌 Agent Portal Integration

The [Agent Portal](https://github.com/misantibanez/AI-MAF-AGENT-CREATION) is a web platform for creating and managing AI agents in Microsoft Foundry. The modernizer will be registered as an available MCP tool so agents created through the portal can leverage code migration capabilities.

![Agent Portal Frontend](docs/agent-portal.png)

## 🤖 ModernMint Agents

Custom GitHub Copilot agents with built-in memory, domain rules, and step-by-step instructions for performing modernizations. They encode the knowledge of how to analyze SK/AutoGen codebases and produce structured modernization artifacts:

| Agent | Purpose |
|-------|--------|
| `@modernmint-spec` | Scans the codebase and produces a modernization specification — defines **what** needs to change |
| `@modernmint-planner` | Reads the spec and generates a phased implementation plan — defines **how** to modernize step-by-step |

Each agent follows embedded instruction files (`.github/instructions/`) that define pattern recognition rules, migration mappings, and quality checklists. This enables consistent, repeatable modernizations across projects of any complexity.

Example outputs are included under `docs/specs/` and `plans/` (5-phase plan with quality checklists). Multi-AI support files (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `SKILL.md`) ensure the agents work across GitHub Copilot, Claude, and Gemini.

## 🛠️ Tools

The agent exposes three tools via MCP:

| Tool | Description |
|------|-------------|
| `analyze_code_patterns` | Detects SK or AutoGen patterns in source code (imports, plugins, planners, group chat, etc.) |
| `generate_modernized_code` | Produces equivalent MAF code from the analyzed input |
| `get_migration_guide` | Returns a comprehensive migration guide for the detected framework |

## 🚀 Quick Start

### Prerequisites

- Python 3.10+
- Azure CLI (`az login`)
- Azure AI Foundry project with a deployed reasoning model

### Setup

```bash
cd AIAppsModernization
python -m venv .venv
.venv\Scripts\activate       # Windows
pip install -r requirements.txt
```

Create a `.env` file:

```
FOUNDRY_PROJECT_ENDPOINT=https://<your-project>.services.ai.azure.com/...
FOUNDRY_MODEL_DEPLOYMENT_NAME=gpt-5.1
FOUNDRY_API_KEY=<your-key>
```

### Run

```bash
# MCP server (default — for GitHub Copilot / Agent Portal)
python main.py

# HTTP server (for debugging with Agent Inspector)
python main.py --server

# Interactive CLI
python main.py --cli
```

### Configure in VS Code

Add to `.vscode/mcp.json`:

```json
{
  "servers": {
    "code-modernizer": {
      "command": "python",
      "args": ["AIAppsModernization/main.py"]
    }
  }
}
```

## ☁️ Provisioning & Deployment

The infrastructure is managed with **Terraform** and orchestrated by the **Azure Developer CLI (`azd`)**. The `azure.yaml` at the repo root defines hooks that automate environment selection, Terraform execution, Docker image build, and Container App deployment.

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (`az login`)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) (`azd auth login`)
- [Terraform ≥ 1.9](https://developer.hashicorp.com/terraform/install)
- An Azure subscription with permissions for: AI Foundry, Container Apps, APIM, ACR, VNet, and RBAC

### Environments

Three pre-configured environments live under `infra/terraform/environments/`:

| Setting | `dev` | `stg` | `prd` |
|---------|-------|-------|-------|
| Resource Group | `rg-agent-migration-dev` | `rg-agent-migration-stg` | `rg-agent-migration-prd` |
| VNet CIDR | `10.0.0.0/16` | `10.1.0.0/16` | `10.2.0.0/16` |
| ACR SKU | Basic | Basic | **Premium** (zone-redundant) |
| APIM SKU | Developer | Developer | **Premium** |
| Model Capacity | 10 | 50 | 100 |
| Container CPU / Memory | 1 / 2 Gi | 2 / 4 Gi | 3.5 / 7 Gi |
| Public Access | Enabled | Enabled | **Disabled** |
| Diagnostics | Off | On | On |

> **Progressive hardening**: dev is fully open for fast iteration; stg adds capacity and diagnostics; prd locks down public access, uses Premium SKUs with zone redundancy, and maximizes compute.

### Deploy with `azd`

```bash
# 1. Authenticate
az login
azd auth login

# 2. Select the target environment (dev | stg | prd)
azd env set AZURE_ENV_NAME dev

# 3. Provision infrastructure + build & deploy the container
azd up
```

`azd up` executes the following pipeline automatically:

1. **Preprovision hook** — Copies `infra/terraform/environments/{AZURE_ENV_NAME}.tfvars.json` → `infra/terraform/main.tfvars.json`
2. **Terraform init → plan → apply** — Creates all Azure resources using the selected environment configuration
3. **Postprovision hook** (`infra/terraform/scripts/postprovision.sh`) —
   - Reads Terraform outputs (ACR name, AI Foundry endpoint, Container Apps Environment, etc.)
   - Builds the Docker image via `az acr build` with environment-tagged versions
   - Creates or updates the Container App with the new image, managed identity, and environment variables
   - Prints the `AGENT_BASE_URL` and persists it in azd environment variables

After deployment, the agent is accessible at:

```
https://<agent-name>.<cae-default-domain>/runs      # Direct Container App
https://<apim-gateway>/agents-api/runs               # Via APIM
https://<apim-gateway>/mcp                           # MCP endpoint (Streamable HTTP)
```

### Deploying to Multiple Environments

Each environment is fully isolated with its own resource group, VNet, and Azure resources:

```bash
# Deploy to dev
azd env set AZURE_ENV_NAME dev && azd up

# Deploy to staging
azd env set AZURE_ENV_NAME stg && azd up

# Deploy to production
azd env set AZURE_ENV_NAME prd && azd up
```

### What Gets Provisioned

The Terraform root module (`infra/terraform/main.tf`) orchestrates these resources in order:

1. **Resource Group** — `rg-agent-migration-{env}`
2. **Container Registry** — Docker image storage (AVM module)
3. **Log Analytics + Application Insights** — Monitoring and telemetry
4. **AI Foundry** — Cognitive Services account + AI Project + Capability Host + model deployment + App Insights connection
5. **User-Assigned Managed Identity** — Keyless auth for the Container App
6. **RBAC Role Assignments** (×8) — ACR pull, AI User, Cognitive Services User across identities
7. **Virtual Network + Subnets** — CAE subnet (`/23`) and APIM subnet (`/27`)
8. **Container Apps Environment** — With VNet integration and workload profiles
9. **NSG for APIM** *(conditional)* — Full External VNet mode rules
10. **API Management** *(conditional)* — Gateway with system-assigned identity
11. **APIs + MCP Server** *(conditional)* — OpenAPI import, CORS policy, and MCP tool exposure via `azapi_resource`

### Standalone Terraform CLI

For teams not using `azd`, a wrapper script is provided:

```bash
cd infra/terraform

# Initialize and plan
./deploy-infra.sh init-plan environments/dev.tfvars.json

# Apply the plan
./deploy-infra.sh apply

# Destroy all resources (interactive confirmation)
./deploy-infra.sh destroy environments/dev.tfvars.json
```

> **Note**: When using the standalone CLI, the postprovision step (Docker build + Container App deploy) must be run manually. See `infra/terraform/scripts/postprovision.sh`.

## 📁 Project Structure

```
├── AIAppsModernization/
│   ├── main.py                 # Entry point — MCP, HTTP, or CLI mode
│   ├── modernizer_agent.py     # Agent definition and instructions
│   ├── tools.py                # Code analysis & generation tools
│   ├── Dockerfile              # Multi-stage build (Python 3.13 + uv)
│   └── requirements.txt
├── SemanticKernelSamples/
│   ├── joke_agent_sk.py        # Sample SK app (input for testing)
│   ├── joke_agent_autogen.py   # Sample AutoGen app (input for testing)
│   └── joke_agent_MAF.py       # Modernized MAF version
├── infra/terraform/
│   ├── main.tf                          # Root module — orchestrates all resources
│   ├── variables.tf                     # ~50 variables for full customization
│   ├── outputs.tf                       # Outputs consumed by postprovision
│   ├── backend.tf                       # State backend (local)
│   ├── deploy-infra.sh                  # Standalone Terraform CLI wrapper
│   ├── environments/
│   │   ├── dev.tfvars.json              # Development configuration
│   │   ├── stg.tfvars.json              # Staging configuration
│   │   └── prd.tfvars.json              # Production configuration
│   ├── modules/
│   │   ├── ai-foundry/                  # AI Services + Project + Model
│   │   ├── azure-apim-apis-deployment/  # APIs + MCP server in APIM
│   │   ├── azure-container-apps-environments/
│   │   ├── azure-nsg-apim/              # NSG rules for APIM External VNet
│   │   ├── azure-virtual-networks/      # VNet + subnets
│   │   └── monitoring/                  # Log Analytics + App Insights
│   └── scripts/
│       └── postprovision.sh             # Build image + deploy Container App
├── .github/agents/              # ModernMint custom Copilot agents
├── docs/specs/                  # Example modernization specification
├── plans/                       # 5-phase implementation plan with checklists
└── docs/
    ├── architecture.png
    └── agent-portal.png
```

## 🧪 Example

Feed the SK sample to the modernizer:

```
Analyze and modernize this Semantic Kernel agent to Microsoft Agent Framework:
<paste contents of SemanticKernelSamples/joke_agent_sk.py>
```

The agent will:
1. Detect Semantic Kernel patterns (Kernel, kernel_function, ChatHistory, etc.)
2. Generate equivalent MAF code using `AzureAIClient`, `create_agent`, and typed tool annotations
3. Return the migration guide with key differences

## 📚 Resources

- [Microsoft Foundry Docs](https://learn.microsoft.com/azure/ai-foundry/)
- [Agent Framework SDK](https://learn.microsoft.com/azure/ai-foundry/agents/overview?view=foundry)
- [MCP Specification](https://modelcontextprotocol.io/docs/getting-started/intro)
- [Agent Factory Portal](https://github.com/misantibanez/AI-MAF-AGENT-CREATION)
- [Challenge Starter Kit](https://github.com/microsoft/agentsleague-techconnect/tree/main/starter-kits/2-reasoning-agents)
