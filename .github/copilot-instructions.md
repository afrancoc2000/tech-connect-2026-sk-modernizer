# GitHub Copilot Instructions

This repository contains the **AI Agent Code Modernizer** — an MCP-exposed AI agent that analyzes code written with Semantic Kernel or AutoGen and modernizes it to Microsoft Agent Framework (MAF).

## Repository Overview

- **AIAppsModernization/**: Core modernizer agent — MCP server, tools, and agent logic
- **SemanticKernelSamples/**: Sample AI applications built with Semantic Kernel and AutoGen (used as test inputs)
- **infrastructure/**: ARM templates, Docker, and deployment configuration for Azure Container Apps
- **docs/**: Architecture diagrams and supplementary documentation

## Code Conventions

- Python 3.10+ with async/await patterns
- Type annotations using `Annotated` for tool parameters
- Environment configuration via `.env` files and `python-dotenv`
- Azure AI Foundry for model hosting (GPT-5.1)
- MCP (Model Context Protocol) for tool exposure

## Agent Ecosystem

This workspace uses custom GitHub Copilot agents under `.github/agents/`:

| Agent | Purpose |
|-------|---------|
| `modernmint-spec` | Creates modernization specifications (WHAT to modernize, not HOW) |
| `modernmint-planner` | Generates technical implementation plans (HOW to modernize, step-by-step) |

### ModernMint Workflow

1. **Specify** → Use `@modernmint-spec` to create a modernization specification from requirements
2. **Plan** → Use `@modernmint-planner` to build the technical implementation plan from the spec

## Key Frameworks in This Project

### Semantic Kernel Patterns
- `Kernel`, `@kernel_function`, `ChatHistory`, `FunctionChoiceBehavior`
- Plugins, planners, connectors, memory stores

### AutoGen Patterns
- `AssistantAgent`, `UserProxyAgent`, `RoundRobinGroupChat`
- `FunctionTool`, `TextMentionTermination`, multi-agent orchestration

### Microsoft Agent Framework (Target)
- `AzureAIClient`, `create_agent()`, `WorkflowBuilder`
- Tools as standard Python functions with `Annotated` types
- Thread persistence, streaming, MCP server support
