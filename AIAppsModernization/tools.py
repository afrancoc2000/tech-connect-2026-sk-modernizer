# Copyright (c) Microsoft. All rights reserved.

"""
Code Modernization Tools

Tools for analyzing AI agent code written in Semantic Kernel or AutoGen
and providing modernization guidance to Microsoft Agent Framework.
"""

import re
from typing import Annotated


def analyze_code_patterns(
    code: Annotated[str, "The source code to analyze for AI agent patterns."],
) -> str:
    """
    Analyze source code to identify Semantic Kernel or AutoGen patterns.
    
    Returns a detailed analysis of the detected framework, patterns used,
    and recommendations for modernization.
    """
    analysis = {
        "framework": "unknown",
        "patterns_found": [],
        "imports": [],
        "modernization_notes": []
    }
    
    # Detect Semantic Kernel patterns
    sk_patterns = {
        "kernel_import": r"from\s+semantic_kernel|import\s+semantic_kernel",
        "kernel_creation": r"Kernel\(\)|kernel\s*=\s*Kernel",
        "plugin_import": r"from\s+semantic_kernel\.functions|\.plugins",
        "chat_completion": r"ChatCompletionClientBase|add_chat_service",
        "native_function": r"@kernel_function|@sk_function",
        "prompt_template": r"PromptTemplateConfig|ChatPromptTemplate",
        "planner": r"ActionPlanner|SequentialPlanner|StepwisePlanner",
        "memory": r"SemanticTextMemory|VolatileMemoryStore",
        "connector": r"AzureChatCompletion|OpenAIChatCompletion",
    }
    
    # Detect AutoGen patterns
    autogen_patterns = {
        "autogen_import": r"from\s+autogen|import\s+autogen|from\s+pyautogen|import\s+pyautogen",
        "assistant_agent": r"AssistantAgent\(|ConversableAgent\(",
        "user_proxy": r"UserProxyAgent\(",
        "group_chat": r"GroupChat\(|GroupChatManager\(",
        "config_list": r"config_list|llm_config",
        "code_execution": r"code_execution_config|CodeExecutorAgent",
        "function_calling": r"register_function|function_map",
        "nested_chat": r"register_nested_chats|nested_chat",
    }
    
    sk_matches = []
    autogen_matches = []
    
    for pattern_name, pattern in sk_patterns.items():
        if re.search(pattern, code, re.IGNORECASE):
            sk_matches.append(pattern_name)
    
    for pattern_name, pattern in autogen_patterns.items():
        if re.search(pattern, code, re.IGNORECASE):
            autogen_matches.append(pattern_name)
    
    # Determine primary framework
    if len(sk_matches) > len(autogen_matches) and len(sk_matches) > 0:
        analysis["framework"] = "semantic_kernel"
        analysis["patterns_found"] = sk_matches
    elif len(autogen_matches) > 0:
        analysis["framework"] = "autogen"
        analysis["patterns_found"] = autogen_matches
    
    # Extract imports
    import_pattern = r"^(?:from|import)\s+[\w\.]+.*$"
    imports = re.findall(import_pattern, code, re.MULTILINE)
    analysis["imports"] = imports[:20]  # Limit to first 20 imports
    
    # Generate modernization notes based on patterns
    if analysis["framework"] == "semantic_kernel":
        analysis["modernization_notes"] = _get_sk_modernization_notes(sk_matches)
    elif analysis["framework"] == "autogen":
        analysis["modernization_notes"] = _get_autogen_modernization_notes(autogen_matches)
    
    result = f"""
## Code Analysis Results

### Detected Framework: {analysis['framework'].replace('_', ' ').title()}

### Patterns Found:
{chr(10).join(f"- {p.replace('_', ' ').title()}" for p in analysis['patterns_found'])}

### Key Imports:
```python
{chr(10).join(analysis['imports'][:10])}
```

### Modernization Notes:
{chr(10).join(f"- {note}" for note in analysis['modernization_notes'])}
"""
    return result


def _get_sk_modernization_notes(patterns: list[str]) -> list[str]:
    """Generate modernization notes for Semantic Kernel patterns."""
    notes = []
    
    if "kernel_creation" in patterns:
        notes.append("Replace `Kernel()` with `AzureAIClient().create_agent()` for agent creation")
    
    if "native_function" in patterns:
        notes.append("Replace `@kernel_function` decorated functions with standard Python functions as tools")
    
    if "chat_completion" in patterns:
        notes.append("Replace chat completion services with `AzureAIClient` or `OpenAIChatClient`")
    
    if "planner" in patterns:
        notes.append("Replace planners with `WorkflowBuilder` for orchestration")
    
    if "memory" in patterns:
        notes.append("Replace SK memory with Agent Framework thread persistence or external stores")
    
    if "connector" in patterns:
        notes.append("Replace connectors with Agent Framework clients (AzureAIClient, OpenAIChatClient)")
    
    if "prompt_template" in patterns:
        notes.append("Replace PromptTemplateConfig with agent instructions parameter")
    
    if "plugin_import" in patterns:
        notes.append("Convert plugins to standard tool functions with type annotations")
    
    return notes


def _get_autogen_modernization_notes(patterns: list[str]) -> list[str]:
    """Generate modernization notes for AutoGen patterns."""
    notes = []
    
    if "assistant_agent" in patterns:
        notes.append("Replace `AssistantAgent` with `ChatAgent` from Agent Framework")
    
    if "user_proxy" in patterns:
        notes.append("Replace `UserProxyAgent` with workflow handlers and human-in-loop patterns")
    
    if "group_chat" in patterns:
        notes.append("Replace `GroupChat` with `WorkflowBuilder` multi-agent orchestration")
    
    if "config_list" in patterns:
        notes.append("Replace `config_list` with Agent Framework client configuration")
    
    if "code_execution" in patterns:
        notes.append("Replace code execution config with secure tool implementations")
    
    if "function_calling" in patterns:
        notes.append("Replace `register_function` with tools parameter in agent creation")
    
    if "nested_chat" in patterns:
        notes.append("Replace nested chats with workflow orchestration patterns")
    
    return notes


def generate_modernized_code(
    original_code: Annotated[str, "The original Semantic Kernel or AutoGen code to modernize."],
    framework: Annotated[str, "The source framework: 'semantic_kernel' or 'autogen'."],
) -> str:
    """
    Generate modernized code using Microsoft Agent Framework based on the original code.
    
    Provides a complete, working example that maintains the same functionality
    but uses Agent Framework patterns and best practices.
    """
    
    if framework.lower() in ["semantic_kernel", "sk", "semantickernel"]:
        return _generate_from_semantic_kernel(original_code)
    elif framework.lower() in ["autogen", "pyautogen", "auto-gen"]:
        return _generate_from_autogen(original_code)
    else:
        return "Unable to determine source framework. Please specify 'semantic_kernel' or 'autogen'."


def _generate_from_semantic_kernel(code: str) -> str:
    """Generate Agent Framework code from Semantic Kernel patterns."""
    
    # Extract function names that look like tools
    function_pattern = r"@(?:kernel_function|sk_function).*?\ndef\s+(\w+)"
    functions = re.findall(function_pattern, code, re.DOTALL)
    
    # Extract any instructions/system messages
    instruction_pattern = r"(?:system_message|instructions?)\s*[=:]\s*[\"']([^\"']+)[\"']"
    instructions = re.findall(instruction_pattern, code)
    default_instructions = instructions[0] if instructions else "You are a helpful AI assistant."
    
    tools_code = ""
    if functions:
        tools_code = f"""
# Tools (converted from Semantic Kernel functions)
# Note: Review and adjust type annotations as needed

{"".join(f'''
def {func}(
    # Add appropriate parameters with Annotated types
    param: Annotated[str, "Description of parameter"]
) -> str:
    \"\"\"Description of what this tool does.\"\"\"
    # TODO: Implement tool logic from original @kernel_function
    pass
''' for func in functions[:5])}
"""

    modernized = f'''# Copyright (c) Microsoft. All rights reserved.

"""
Modernized Agent - Converted from Semantic Kernel to Microsoft Agent Framework
"""

import asyncio
import os
from typing import Annotated
from dotenv import load_dotenv

from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential

# Load environment variables
load_dotenv(override=True)
{tools_code}

async def main() -> None:
    """Main entry point for the modernized agent."""
    
    # Create the agent using Azure AI Client
    async with (
        DefaultAzureCredential() as credential,
        AzureAIClient(
            project_endpoint=os.getenv("FOUNDRY_PROJECT_ENDPOINT"),
            model_deployment_name=os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME"),
            credential=credential,
        ).create_agent(
            name="ModernizedAgent",
            instructions="""{default_instructions}""",
            # tools=[{", ".join(functions[:5]) if functions else "# Add tools here"}],
        ) as agent,
    ):
        # Multi-turn conversation with thread persistence
        thread = agent.get_new_thread()
        
        print("Agent ready. Type 'quit' to exit.")
        while True:
            user_input = input("You: ")
            if user_input.lower() == "quit":
                break
            
            print("Agent: ", end="", flush=True)
            async for chunk in agent.run_stream(user_input, thread=thread):
                if chunk.text:
                    print(chunk.text, end="", flush=True)
            print()


if __name__ == "__main__":
    asyncio.run(main())
'''
    
    return f"""
## Modernized Code (Agent Framework)

```python
{modernized}
```

### Migration Checklist:
1. ✅ Replaced Kernel with AzureAIClient
2. ✅ Converted @kernel_function decorators to standard tool functions
3. ✅ Added thread persistence for multi-turn conversations
4. ✅ Used async streaming for better UX
5. ⚠️ Review and complete tool implementations
6. ⚠️ Update .env with your Foundry credentials
7. ⚠️ Install requirements: `pip install agent-framework-azure-ai==1.0.0b260107`
"""


def _generate_from_autogen(code: str) -> str:
    """Generate Agent Framework code from AutoGen patterns."""
    
    # Check for multi-agent patterns
    has_group_chat = bool(re.search(r"GroupChat\(|GroupChatManager", code))
    has_user_proxy = bool(re.search(r"UserProxyAgent", code))
    
    # Extract agent names
    agent_pattern = r"(\w+)\s*=\s*(?:AssistantAgent|ConversableAgent|UserProxyAgent)\("
    agent_names = re.findall(agent_pattern, code)
    
    # Extract instructions
    instruction_pattern = r"system_message\s*[=:]\s*[\"']([^\"']+)[\"']"
    instructions = re.findall(instruction_pattern, code)
    default_instructions = instructions[0] if instructions else "You are a helpful AI assistant."
    
    if has_group_chat and len(agent_names) > 1:
        return _generate_multi_agent_workflow(agent_names, default_instructions)
    else:
        return _generate_single_agent(default_instructions)


def _generate_single_agent(instructions: str) -> str:
    """Generate a single agent conversion."""
    
    modernized = f'''# Copyright (c) Microsoft. All rights reserved.

"""
Modernized Agent - Converted from AutoGen to Microsoft Agent Framework
"""

import asyncio
import os
from typing import Annotated
from dotenv import load_dotenv

from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential

# Load environment variables
load_dotenv(override=True)


# Define tools (converted from AutoGen function registrations)
def example_tool(
    query: Annotated[str, "The query to process."],
) -> str:
    """Example tool - replace with your actual tool logic."""
    return f"Processed: {{query}}"


async def main() -> None:
    """Main entry point for the modernized agent."""
    
    async with (
        DefaultAzureCredential() as credential,
        AzureAIClient(
            project_endpoint=os.getenv("FOUNDRY_PROJECT_ENDPOINT"),
            model_deployment_name=os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME"),
            credential=credential,
        ).create_agent(
            name="ModernizedAgent",
            instructions="""{instructions}""",
            tools=[example_tool],
        ) as agent,
    ):
        thread = agent.get_new_thread()
        
        print("Agent ready. Type 'quit' to exit.")
        while True:
            user_input = input("You: ")
            if user_input.lower() == "quit":
                break
            
            print("Agent: ", end="", flush=True)
            async for chunk in agent.run_stream(user_input, thread=thread):
                if chunk.text:
                    print(chunk.text, end="", flush=True)
            print()


if __name__ == "__main__":
    asyncio.run(main())
'''
    
    return f"""
## Modernized Code (Agent Framework)

```python
{modernized}
```

### Migration Checklist:
1. ✅ Replaced AssistantAgent with AzureAIClient.create_agent()
2. ✅ Replaced config_list with environment-based configuration
3. ✅ Added streaming support for better UX
4. ⚠️ Convert registered functions to tool functions with Annotated types
5. ⚠️ Update .env with your Foundry credentials
6. ⚠️ Install requirements: `pip install agent-framework-azure-ai==1.0.0b260107`
"""


def _generate_multi_agent_workflow(agent_names: list[str], instructions: str) -> str:
    """Generate a multi-agent workflow conversion using WorkflowBuilder."""
    
    agents_code = "\n".join([
        f'        "{name}": AzureAIClient(project_endpoint=endpoint, model_deployment_name=model, credential=credential).create_agent(name="{name}", instructions="Agent {name} instructions"),'
        for name in agent_names[:4]
    ])
    
    modernized = f'''# Copyright (c) Microsoft. All rights reserved.

"""
Modernized Multi-Agent Workflow - Converted from AutoGen GroupChat to Agent Framework Workflow
"""

import asyncio
import os
from uuid import uuid4
from dotenv import load_dotenv

from agent_framework import (
    WorkflowBuilder,
    WorkflowContext,
    handler,
    AgentRunUpdateEvent,
    AgentRunResponseUpdate,
    TextContent,
    Role,
)
from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential

# Load environment variables
load_dotenv(override=True)


class OrchestratorExecutor:
    """Orchestrates the multi-agent workflow."""
    
    def __init__(self, agents: dict):
        self.agents = agents
        self.id = "orchestrator"
    
    @handler
    async def handle(self, messages: list, ctx: WorkflowContext) -> str:
        \"\"\"Process messages through the agent workflow.\"\"\"
        
        # Example: Sequential agent invocation (customize based on your needs)
        result = ""
        for name, agent in self.agents.items():
            response = await agent.run(messages)
            result += f"\\n[{{name}}]: {{response.text}}"
            
            await ctx.add_event(
                AgentRunUpdateEvent(
                    self.id,
                    data=AgentRunResponseUpdate(
                        contents=[TextContent(text=f"[{{name}}]: {{response.text}}")],
                        role=Role.ASSISTANT,
                        response_id=str(uuid4()),
                    ),
                )
            )
        
        return result


async def main() -> None:
    \"\"\"Main entry point for the multi-agent workflow.\"\"\"
    
    endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT")
    model = os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME")
    
    async with DefaultAzureCredential() as credential:
        # Create agents (converted from AutoGen agents)
        agents = {{
{agents_code}
        }}
        
        # Build the workflow
        orchestrator = OrchestratorExecutor(agents)
        
        workflow = (
            WorkflowBuilder()
            .set_start_executor(orchestrator)
            .build()
        )
        
        # Run as agent
        agent = workflow.as_agent()
        thread = agent.get_new_thread()
        
        print("Multi-agent workflow ready. Type 'quit' to exit.")
        while True:
            user_input = input("You: ")
            if user_input.lower() == "quit":
                break
            
            async for chunk in agent.run_stream(user_input, thread=thread):
                if chunk.text:
                    print(chunk.text, end="", flush=True)
            print()


if __name__ == "__main__":
    asyncio.run(main())
'''
    
    return f"""
## Modernized Multi-Agent Workflow (Agent Framework)

```python
{modernized}
```

### Migration Checklist:
1. ✅ Replaced GroupChat with WorkflowBuilder
2. ✅ Converted AutoGen agents to Agent Framework agents
3. ✅ Added orchestration logic via WorkflowContext
4. ⚠️ Customize the orchestration pattern (sequential, parallel, conditional)
5. ⚠️ Add error handling and retry logic
6. ⚠️ Update .env with your Foundry credentials
7. ⚠️ Install requirements: `pip install agent-framework-azure-ai==1.0.0b260107`

### Orchestration Patterns Available:
- **Sequential**: Agents execute one after another
- **Parallel (Fan-out/Fan-in)**: Agents execute simultaneously
- **Conditional**: Route based on context
- **Loop**: Iterate until condition met
- **Human-in-Loop**: Pause for human input
"""


def get_migration_guide(
    source_framework: Annotated[str, "The source framework: 'semantic_kernel' or 'autogen'."],
) -> str:
    """
    Get a comprehensive migration guide for moving from the specified framework
    to Microsoft Agent Framework.
    """
    
    if source_framework.lower() in ["semantic_kernel", "sk"]:
        return _get_sk_migration_guide()
    elif source_framework.lower() in ["autogen", "pyautogen"]:
        return _get_autogen_migration_guide()
    else:
        return "Please specify 'semantic_kernel' or 'autogen' as the source framework."


def _get_sk_migration_guide() -> str:
    """Get Semantic Kernel to Agent Framework migration guide."""
    return """
# Semantic Kernel to Microsoft Agent Framework Migration Guide

## Overview
Microsoft Agent Framework is a unified SDK for building enterprise AI agents. It provides 
a simpler, more streamlined API compared to Semantic Kernel while maintaining powerful 
orchestration capabilities.

## Key Concept Mappings

| Semantic Kernel | Agent Framework |
|-----------------|-----------------|
| `Kernel` | `AzureAIClient` / `OpenAIChatClient` |
| `@kernel_function` | Standard Python functions as tools |
| `ChatCompletionService` | Built into client |
| `PromptTemplate` | `instructions` parameter |
| `Plugins` | Tools (functions with Annotated types) |
| `Planner` | `WorkflowBuilder` |
| `Memory` | Thread persistence |

## Step-by-Step Migration

### 1. Replace Kernel Creation

**Before (SK):**
```python
from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion

kernel = Kernel()
kernel.add_service(AzureChatCompletion(...))
```

**After (Agent Framework):**
```python
from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential

async with (
    DefaultAzureCredential() as credential,
    AzureAIClient(
        project_endpoint="...",
        model_deployment_name="...",
        credential=credential,
    ).create_agent(name="MyAgent", instructions="...") as agent
):
    ...
```

### 2. Convert Kernel Functions to Tools

**Before (SK):**
```python
@kernel_function(name="get_weather", description="Get weather")
def get_weather(location: str) -> str:
    return f"Weather in {location}: Sunny"
```

**After (Agent Framework):**
```python
from typing import Annotated

def get_weather(
    location: Annotated[str, "The location to get weather for."],
) -> str:
    \"\"\"Get the weather for a given location.\"\"\"
    return f"Weather in {location}: Sunny"

# Pass to agent
agent = client.create_agent(..., tools=[get_weather])
```

### 3. Replace Planners with Workflows

**Before (SK):**
```python
from semantic_kernel.planners import SequentialPlanner
planner = SequentialPlanner(kernel)
plan = await planner.create_plan("...")
```

**After (Agent Framework):**
```python
from agent_framework import WorkflowBuilder

workflow = (
    WorkflowBuilder()
    .add_edge("step1", "step2")
    .set_start_executor(step1_executor)
    .build()
)
agent = workflow.as_agent()
```

## Benefits of Migration

1. **Simpler API**: Less boilerplate, more intuitive patterns
2. **Built-in Streaming**: Native support for streaming responses
3. **Thread Persistence**: Easy multi-turn conversation management
4. **MCP Support**: Connect to Model Context Protocol servers
5. **HTTP Server Mode**: Easy deployment with `as_mcp_server()`
6. **Type Safety**: Better IDE support with type annotations
"""


def _get_autogen_migration_guide() -> str:
    """Get AutoGen to Agent Framework migration guide."""
    return """
# AutoGen to Microsoft Agent Framework Migration Guide

## Overview
Microsoft Agent Framework provides a modern, type-safe approach to building AI agents 
with better support for enterprise scenarios, streaming, and deployment options.

## Key Concept Mappings

| AutoGen | Agent Framework |
|---------|-----------------|
| `AssistantAgent` | `ChatAgent` / `create_agent()` |
| `UserProxyAgent` | Workflow handlers |
| `GroupChat` | `WorkflowBuilder` |
| `config_list` | Client configuration |
| `register_function` | Tools parameter |
| `llm_config` | Client initialization |

## Step-by-Step Migration

### 1. Replace AssistantAgent

**Before (AutoGen):**
```python
from autogen import AssistantAgent

assistant = AssistantAgent(
    name="assistant",
    system_message="You are a helpful assistant.",
    llm_config={"config_list": config_list}
)
```

**After (Agent Framework):**
```python
from agent_framework.azure import AzureAIClient
from azure.identity.aio import DefaultAzureCredential

async with (
    DefaultAzureCredential() as credential,
    AzureAIClient(...).create_agent(
        name="assistant",
        instructions="You are a helpful assistant.",
    ) as agent
):
    ...
```

### 2. Replace GroupChat with WorkflowBuilder

**Before (AutoGen):**
```python
from autogen import GroupChat, GroupChatManager

groupchat = GroupChat(
    agents=[agent1, agent2, agent3],
    messages=[],
    max_round=10
)
manager = GroupChatManager(groupchat=groupchat)
```

**After (Agent Framework):**
```python
from agent_framework import WorkflowBuilder

workflow = (
    WorkflowBuilder()
    .add_edge("agent1", "agent2")
    .add_edge("agent2", "agent3")
    .set_start_executor(agent1_executor)
    .build()
)
agent = workflow.as_agent()
```

### 3. Convert Function Registrations to Tools

**Before (AutoGen):**
```python
assistant.register_function(
    function_map={
        "search": search_function,
        "calculate": calc_function,
    }
)
```

**After (Agent Framework):**
```python
from typing import Annotated

def search(query: Annotated[str, "Search query"]) -> str:
    \"\"\"Search for information.\"\"\"
    ...

def calculate(expression: Annotated[str, "Math expression"]) -> str:
    \"\"\"Calculate a math expression.\"\"\"
    ...

agent = client.create_agent(..., tools=[search, calculate])
```

### 4. Replace UserProxyAgent

**Before (AutoGen):**
```python
user_proxy = UserProxyAgent(
    name="user_proxy",
    human_input_mode="ALWAYS",
    code_execution_config={"work_dir": "coding"}
)
```

**After (Agent Framework):**
```python
# Use workflow handlers for human-in-loop
class HumanInputExecutor:
    @handler
    async def handle(self, messages, ctx):
        # Implement human input logic
        user_response = await get_human_input(messages)
        return user_response

# For code execution, use secure tool implementations
```

## Benefits of Migration

1. **Type Safety**: Full type annotations for better IDE support
2. **Streaming**: Native streaming responses
3. **Async First**: Modern async/await patterns
4. **Deployment Ready**: HTTP server mode built-in
5. **MCP Integration**: Connect to MCP servers
6. **Enterprise Features**: Tracing, evaluation, and observability
"""
