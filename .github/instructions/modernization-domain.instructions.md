---
applyTo: "SemanticKernelSamples/**,AIAppsModernization/**"
---

# Modernization Domain Instructions

This repository contains AI applications built with Semantic Kernel and AutoGen, along with a modernization agent that migrates them to Microsoft Agent Framework (MAF).

## Semantic Kernel Patterns to Recognize

- **Kernel creation**: `Kernel()` as the central orchestrator
- **Plugins**: Classes with `@kernel_function` decorated methods
- **Chat services**: `AzureChatCompletion`, `OpenAIChatCompletion`
- **Chat history**: `ChatHistory` for conversation state
- **Function calling**: `FunctionChoiceBehavior.Auto()` for automatic tool invocation
- **Planners**: `SequentialPlanner`, `StepwisePlanner` for multi-step orchestration
- **Memory**: `SemanticTextMemory`, `VolatileMemoryStore`
- **Prompt templates**: `PromptTemplateConfig`, `ChatPromptTemplate`

## AutoGen Patterns to Recognize

- **Agent types**: `AssistantAgent`, `UserProxyAgent`, `ConversableAgent`
- **Multi-agent chat**: `RoundRobinGroupChat`, `GroupChat`, `GroupChatManager`
- **Tools**: `FunctionTool` wrapping standard Python functions
- **Termination**: `TextMentionTermination` for conversation ending conditions
- **Model clients**: `AzureOpenAIChatCompletionClient`
- **Code execution**: `code_execution_config` for sandboxed code running
- **Nested chats**: `register_nested_chats` for hierarchical agent conversations

## When Analyzing Code

- Identify which framework is used based on imports and patterns above.
- Catalog every user-facing capability the application provides.
- Note all external integrations (Azure OpenAI, environment variables, CLI, HTTP, MCP).
- Understand the agent topology (single agent, multi-agent, orchestrated workflow).
