# Implementation Plan: SemanticKernelSamples Modernization

**Created**: 2026-02-12
**Source Framework**: Semantic Kernel and AutoGen
**Target Framework**: Microsoft Agent Framework (MAF)
**Specification**: `docs/specs/SemanticKernelSamples-modernization-spec.md` (quality checklist only — plan based on codebase analysis)

---

## 1. Overview

This plan modernizes two joke agent applications in the `SemanticKernelSamples/` directory from **Semantic Kernel** and **AutoGen** to **Microsoft Agent Framework (MAF)**. The migration covers:

- **`joke_agent_sk.py`** — A single-agent Semantic Kernel application with a `JokePlugin` (two `@kernel_function` tools), `ChatHistory`, `AzureChatCompletion`, and `FunctionChoiceBehavior.Auto()`. This will be transformed into a MAF agent using `AzureAIClient`, plain Python tool functions, and `AgentThread`.
- **`joke_agent_autogen.py`** — A multi-agent AutoGen application with two `AssistantAgent` instances (Comedian and Critic) orchestrated via `RoundRobinGroupChat`, `FunctionTool` wrappers, `TextMentionTermination`, and streaming via `Console`. This will be transformed into a MAF workflow using `SequentialBuilder` with two agent participants.

A reference MAF implementation (`joke_agent_MAF.py`) already exists in the workspace and will be used for validation, but each source file will be independently modernized.

## 2. Technical Inventory

### 2.1 Source Files Requiring Changes

| File | Current Framework | Key Patterns | Transformation Complexity |
|------|-------------------|--------------|--------------------------|
| `joke_agent_sk.py` | Semantic Kernel | `Kernel`, `@kernel_function`, `AzureChatCompletion`, `ChatHistory`, `FunctionChoiceBehavior.Auto()`, `add_plugin`, `add_service`, `get_prompt_execution_settings_from_service_id`, `get_chat_message_contents` | Medium |
| `joke_agent_autogen.py` | AutoGen | `AssistantAgent`, `RoundRobinGroupChat`, `TextMentionTermination`, `FunctionTool`, `AzureOpenAIChatCompletionClient`, `CancellationToken`, `Console`, `team.run_stream`, `team.reset` | High |
| `requirements.txt` | Both | `semantic-kernel>=1.0.0`, `autogen-agentchat>=0.4.0`, `autogen-ext[openai]>=0.4.0`, `openai>=1.0.0` | Low |
| `.env.example` | N/A | `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_DEPLOYMENT_NAME` | Low |
| `README.md` | N/A | Documentation references to SK and AutoGen patterns | Low |

### 2.2 Current Dependencies

```
semantic-kernel>=1.0.0
autogen-agentchat>=0.4.0
autogen-ext[openai]>=0.4.0
openai>=1.0.0
azure-identity>=1.15.0
python-dotenv>=1.0.0
```

### 2.3 Target Dependencies

```
agent-framework --pre
azure-identity>=1.15.0
python-dotenv>=1.0.0
```

### 2.4 Agent Topology

**Current (SK)**: Single agent — `Kernel` with `JokePlugin` (2 functions) → user sends message → model calls tools and responds → chat history maintains state.

**Current (AutoGen)**: Multi-agent — `Comedian` (has `topic_tool`) and `Critic` (has `rate_tool`) agents in a `RoundRobinGroupChat` with max 6 turns and `TextMentionTermination("DONE")`. User input triggers the team; agents alternate turns.

**Target (SK → MAF)**: Single agent — `AzureAIClient.create_agent()` with `tools=[get_joke_topic, rate_joke]` and `AgentThread` for conversation state. Interactive CLI with streaming responses.

**Target (AutoGen → MAF)**: Multi-agent workflow — `SequentialBuilder` with Comedian and Critic agents as participants. Each user request triggers a workflow run with sequential agent execution.

### 2.5 Reference Implementation

`joke_agent_MAF.py` already exists in the workspace and demonstrates the MAF single-agent pattern. Key patterns from the reference:

- `AzureAIClient(project_endpoint=..., model_deployment_name=..., credential=...)`
- `client.create_agent(name=..., instructions=..., tools=[...])`
- `agent.get_new_thread()` for conversation state
- `agent.run_stream(user_input, thread=thread)` for streaming
- `DefaultAzureCredential` for authentication
- Tool functions as plain Python functions with `Annotated` type hints

## 3. Phase Summary

| Phase | Description | Files Affected | Tasks |
|-------|-------------|----------------|-------|
| 1 — Setup | Dependencies, environment configuration | `requirements.txt`, `.env.example` | 2 |
| 2 — SK Transform | Modernize Semantic Kernel agent to MAF | `joke_agent_sk.py` | 5 |
| 3 — AutoGen Transform | Modernize AutoGen multi-agent to MAF | `joke_agent_autogen.py` | 6 |
| 4 — Integration | Documentation, cleanup, reconciliation | `README.md`, `joke_agent_MAF.py` | 3 |
| 5 — Validation | Testing and verification | All files | 3 |
| **Total** | | | **19** |

## 4. Execution Order

Phases must be executed in order. Phase 1 establishes the dependency foundation. Phases 2 and 3 can be executed independently of each other but both depend on Phase 1. Phase 4 depends on Phases 2 and 3 being complete. Phase 5 validates the entire migration.

```
Phase 1 (Setup)
    ├── Phase 2 (SK Transform)
    └── Phase 3 (AutoGen Transform)
         └── Phase 4 (Integration)
              └── Phase 5 (Validation)
```

## 5. Assumptions

- **Authentication**: The target uses `DefaultAzureCredential` (managed identity / Azure CLI login) instead of raw API keys, consistent with the reference implementation. The `.env.example` will include both credential approaches.
- **`agent_framework` package**: Available via `pip install agent-framework --pre` during the preview period.
- **Streaming**: The MAF `run_stream()` API is used for interactive CLI output in both agents.
- **Multi-agent orchestration**: The AutoGen `RoundRobinGroupChat` maps to `SequentialBuilder` since participants execute in a fixed order (Comedian → Critic).
- **No full specification exists**: The file at `docs/specs/SemanticKernelSamples-modernization-spec.md` contains only a quality checklist. This plan is based on direct codebase analysis.
- **Reference file retained**: `joke_agent_MAF.py` will be kept as the canonical modernized single-agent version; `joke_agent_sk.py` will be replaced in-place.

## 6. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| `agent-framework` API is in preview and may change | Medium | Pin to a specific pre-release version; use `--pre` flag |
| `SequentialBuilder` may not support termination conditions identical to `TextMentionTermination` | Medium | Implement termination via `ctx.yield_output()` or max-turns configuration in workflow |
| `DefaultAzureCredential` requires Azure CLI login or managed identity | Low | Document API-key fallback in `.env.example` and code comments |
| Multi-agent streaming output format differs from AutoGen `Console` | Low | Implement custom output formatting in the workflow loop |
