# Phase 3: AutoGen Agent Transformation

**Prerequisite**: Phase 1 — Setup

---

## Task 3.1: Replace Imports

**File(s)**: `SemanticKernelSamples/joke_agent_autogen.py`
**Action**: Modify

### Current State

```python
import asyncio
import os
import random
from dotenv import load_dotenv

from autogen_agentchat.agents import AssistantAgent
from autogen_agentchat.teams import RoundRobinGroupChat
from autogen_agentchat.conditions import TextMentionTermination
from autogen_agentchat.ui import Console
from autogen_ext.models.openai import AzureOpenAIChatCompletionClient
from autogen_core import CancellationToken
from autogen_core.tools import FunctionTool
```

### Target State

```python
import asyncio
import os
import random
from typing import Annotated

from dotenv import load_dotenv

from azure.identity.aio import DefaultAzureCredential
from agent_framework.azure import AzureAIClient
from agent_framework.workflows import SequentialBuilder
```

### Step-by-Step Instructions

1. Remove all `from autogen_agentchat` imports:
   - `from autogen_agentchat.agents import AssistantAgent`
   - `from autogen_agentchat.teams import RoundRobinGroupChat`
   - `from autogen_agentchat.conditions import TextMentionTermination`
   - `from autogen_agentchat.ui import Console`
2. Remove all `from autogen_ext` imports:
   - `from autogen_ext.models.openai import AzureOpenAIChatCompletionClient`
3. Remove all `from autogen_core` imports:
   - `from autogen_core import CancellationToken`
   - `from autogen_core.tools import FunctionTool`
4. Add `from typing import Annotated`.
5. Add `from azure.identity.aio import DefaultAzureCredential`.
6. Add `from agent_framework.azure import AzureAIClient`.
7. Add `from agent_framework.workflows import SequentialBuilder`.

### Verification

- [ ] No `autogen_agentchat`, `autogen_ext`, or `autogen_core` imports remain
- [ ] `AzureAIClient`, `DefaultAzureCredential`, and `SequentialBuilder` are imported
- [ ] `Annotated` is imported from `typing`

---

## Task 3.2: Convert FunctionTool Wrappers to Standalone Functions

**File(s)**: `SemanticKernelSamples/joke_agent_autogen.py`
**Action**: Modify

### Current State

The tool functions exist as module-level functions but are wrapped in `FunctionTool` objects for AutoGen registration:

```python
def get_random_joke_topic() -> str:
    """Returns a random topic for jokes."""
    topics = [
        "programmers", "artificial intelligence", "cats",
        "coffee", "work meetings", "code bugs",
        "machine learning", "the cloud", "Python vs JavaScript",
        "Stack Overflow", "Git commits", "debugging"
    ]
    return f"Selected topic: {random.choice(topics)}"


def rate_joke(joke: str) -> str:
    """Rates a joke from 1 to 10."""
    rating = random.randint(5, 10)
    emojis = "😄" * (rating // 2)
    return f"Rating: {rating}/10 {emojis}"
```

And later in `main()`:

```python
    topic_tool = FunctionTool(
        get_random_joke_topic,
        description="Gets a random topic for telling a joke"
    )
    
    rate_tool = FunctionTool(
        rate_joke,
        description="Rates a joke from 1 to 10"
    )
```

### Target State

The functions remain as module-level plain Python functions. The `FunctionTool` wrappers are removed — MAF uses docstrings as tool descriptions. Add `Annotated` types to parameters.

```python
def get_random_joke_topic() -> str:
    """Gets a random topic for telling a joke."""
    topics = [
        "programmers", "artificial intelligence", "cats",
        "coffee", "work meetings", "code bugs",
        "machine learning", "the cloud", "Python vs JavaScript",
        "Stack Overflow", "Git commits", "debugging",
    ]
    return f"Selected topic: {random.choice(topics)}"


def rate_joke(joke: Annotated[str, "The joke text to rate"]) -> str:
    """Rates a joke from 1 to 10."""
    rating = random.randint(5, 10)
    emojis = "😄" * (rating // 2)
    return f"Rating: {rating}/10 {emojis}"
```

### Step-by-Step Instructions

1. Keep both `get_random_joke_topic()` and `rate_joke()` as module-level functions.
2. Update `rate_joke`'s `joke: str` parameter to `joke: Annotated[str, "The joke text to rate"]`.
3. Ensure the docstrings match the `FunctionTool` descriptions (update if needed to be more descriptive).
4. Remove the `FunctionTool(...)` wrapper calls from `main()` (handled in Task 3.3).

### Verification

- [ ] Both functions are plain module-level functions without decorators or wrappers
- [ ] `rate_joke` uses `Annotated[str, "The joke text to rate"]` for the `joke` parameter
- [ ] Both functions have docstrings that describe their purpose
- [ ] No `FunctionTool` references remain in the file

---

## Task 3.3: Replace Model Client and Agent Construction with AzureAIClient

**File(s)**: `SemanticKernelSamples/joke_agent_autogen.py`
**Action**: Modify

### Current State

```python
async def main():
    # Configure Azure OpenAI
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    api_key = os.getenv("AZURE_OPENAI_API_KEY")
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")
    
    if not endpoint or not api_key:
        print("Error: Configure AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_API_KEY")
        print("You can also set AZURE_OPENAI_DEPLOYMENT_NAME (default: gpt-4o)")
        return
    
    # Create the model client
    model_client = AzureOpenAIChatCompletionClient(
        azure_deployment=deployment,
        model=deployment,
        api_version="2024-06-01",
        azure_endpoint=endpoint,
        api_key=api_key,
    )
    
    # Create tools
    topic_tool = FunctionTool(
        get_random_joke_topic,
        description="Gets a random topic for telling a joke"
    )
    
    rate_tool = FunctionTool(
        rate_joke,
        description="Rates a joke from 1 to 10"
    )
    
    # Create the comedian agent
    comedian_agent = AssistantAgent(
        name="Comedian",
        model_client=model_client,
        tools=[topic_tool],
        system_message="""...""",
    )
    
    # Create the critic agent
    critic_agent = AssistantAgent(
        name="Critic",
        model_client=model_client,
        tools=[rate_tool],
        system_message="""...""",
    )
```

### Target State

```python
async def main() -> None:
    # Read Azure AI Foundry settings
    endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT") or os.getenv("AZURE_AI_ENDPOINT") or os.getenv("AZURE_OPENAI_ENDPOINT")
    model = os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME") or os.getenv("AZURE_AI_MODEL_DEPLOYMENT") or os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")

    if not endpoint or not model:
        print("Error: Configure FOUNDRY_PROJECT_ENDPOINT and FOUNDRY_MODEL_DEPLOYMENT_NAME")
        print("(or AZURE_AI_ENDPOINT / AZURE_OPENAI_ENDPOINT)")
        return

    async with DefaultAzureCredential() as credential:
        client = AzureAIClient(
            project_endpoint=endpoint,
            model_deployment_name=model,
            credential=credential,
        )

        # Create the comedian agent
        async with client.create_agent(
            name="Comedian",
            instructions="""
You are a professional comedian who tells very funny jokes.

When asked for a joke:
1. Use the get_random_joke_topic tool to get a topic
2. Tell a creative and funny joke about that topic
3. End your turn so the critic can evaluate your joke

Be creative, use wordplay and clever humor.
""",
            tools=[get_random_joke_topic],
        ) as comedian_agent:

            # Create the critic agent
            async with client.create_agent(
                name="Critic",
                instructions="""
You are a comedy critic who evaluates jokes.

When the comedian tells a joke:
1. Use the rate_joke tool to give a rating
2. Provide brief constructive feedback
3. Say "APPROVED" if the joke deserves more than 7 points, or "DONE" to finish

Be fair but funny in your reviews.
""",
                tools=[rate_joke],
            ) as critic_agent:
```

### Step-by-Step Instructions

1. Add return type annotation `-> None` to `main()`.
2. Replace `os.getenv("AZURE_OPENAI_ENDPOINT")` with fallback chain: `os.getenv("FOUNDRY_PROJECT_ENDPOINT") or os.getenv("AZURE_AI_ENDPOINT") or os.getenv("AZURE_OPENAI_ENDPOINT")`.
3. Remove `api_key = os.getenv("AZURE_OPENAI_API_KEY")`.
4. Replace `deployment` with `model` using fallback chain: `os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME") or os.getenv("AZURE_AI_MODEL_DEPLOYMENT") or os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")`.
5. Update validation to check `endpoint` and `model` (not `api_key`).
6. Update error message to reference `FOUNDRY_PROJECT_ENDPOINT`.
7. Remove `AzureOpenAIChatCompletionClient(...)` construction.
8. Remove both `FunctionTool(...)` wrapper calls.
9. Remove both `AssistantAgent(...)` constructions.
10. Add `DefaultAzureCredential` async context manager.
11. Create `AzureAIClient(project_endpoint=..., model_deployment_name=..., credential=...)`.
12. Create comedian agent via `client.create_agent(name="Comedian", instructions=..., tools=[get_random_joke_topic])` as async context manager.
13. Create critic agent via `client.create_agent(name="Critic", instructions=..., tools=[rate_joke])` as nested async context manager.
14. Move `system_message` content to `instructions` parameter for each agent.
15. Replace `model_client=` with implicit client from `AzureAIClient` — no need to pass model client per agent.

### Verification

- [ ] No `AzureOpenAIChatCompletionClient`, `AssistantAgent`, or `FunctionTool` calls remain
- [ ] `AzureAIClient` is constructed with `project_endpoint`, `model_deployment_name`, and `credential`
- [ ] Both agents are created via `client.create_agent()` with `name`, `instructions`, and `tools`
- [ ] Comedian has `tools=[get_random_joke_topic]` and Critic has `tools=[rate_joke]`
- [ ] Agent instructions match the original `system_message` content

---

## Task 3.4: Replace RoundRobinGroupChat with SequentialBuilder Workflow

**File(s)**: `SemanticKernelSamples/joke_agent_autogen.py`
**Action**: Modify

### Current State

```python
    # Create termination condition
    termination = TextMentionTermination("DONE")
    
    # Create the team with round-robin chat
    team = RoundRobinGroupChat(
        participants=[comedian_agent, critic_agent],
        termination_condition=termination,
        max_turns=6,
    )
```

### Target State

```python
                # Build sequential workflow (replaces RoundRobinGroupChat)
                workflow = (
                    SequentialBuilder(participants=[comedian_agent, critic_agent])
                    .build()
                )
```

### Step-by-Step Instructions

1. Remove `TextMentionTermination("DONE")` — termination is handled by the workflow completion or agent instructions.
2. Remove `RoundRobinGroupChat(...)` construction.
3. Add `SequentialBuilder(participants=[comedian_agent, critic_agent]).build()` to create the workflow.
4. The `SequentialBuilder` executes agents in order: Comedian first, then Critic — matching the original round-robin behavior.
5. Place this inside the nested `async with` blocks for both agents.

### Verification

- [ ] No `RoundRobinGroupChat` or `TextMentionTermination` references remain
- [ ] `SequentialBuilder` is used with both agents as participants
- [ ] The workflow is built with `.build()`

---

## Task 3.5: Replace Team Chat Loop with Workflow Execution and Streaming

**File(s)**: `SemanticKernelSamples/joke_agent_autogen.py`
**Action**: Modify

### Current State

```python
    print("🎭 Joke System with AutoGen")
    print("=" * 50)
    print("Agents: Comedian 🎤 and Critic 📝")
    print("Type 'exit' to quit\n")
    
    while True:
        user_input = input("You: ").strip()
        
        if user_input.lower() in ['salir', 'exit', 'quit']:
            print("Goodbye! 👋")
            break
        
        if not user_input:
            continue
        
        print("\n" + "=" * 50)
        
        # Run the team conversation
        result = await Console(
            team.run_stream(task=user_input, cancellation_token=CancellationToken())
        )
        
        # Reset the team for the next round
        await team.reset()
        
        print("=" * 50 + "\n")
```

### Target State

```python
                print("🎭 Joke System with Microsoft Agent Framework")
                print("=" * 50)
                print("Agents: Comedian 🎤 and Critic 📝")
                print("Type 'exit' to quit\n")

                while True:
                    user_input = input("You: ").strip()

                    if user_input.lower() in ["salir", "exit", "quit"]:
                        print("Goodbye! 👋")
                        break

                    if not user_input:
                        continue

                    print("\n" + "=" * 50)

                    # Run the workflow (replaces team.run_stream)
                    async for update in workflow.run_stream(user_input):
                        if hasattr(update, "agent_name") and hasattr(update, "text"):
                            if update.text:
                                print(f"\n---------- {update.agent_name} ----------")
                                print(update.text)
                        elif hasattr(update, "text") and update.text:
                            print(update.text, end="", flush=True)

                    print("\n" + "=" * 50 + "\n")
```

### Step-by-Step Instructions

1. Update the header print to say "Microsoft Agent Framework" instead of "AutoGen".
2. Remove `Console(team.run_stream(task=user_input, cancellation_token=CancellationToken()))` — replace with workflow streaming.
3. Remove `await team.reset()` — each workflow run starts fresh; no explicit reset needed.
4. Add `async for update in workflow.run_stream(user_input):` loop.
5. Inside the loop, check for `agent_name` attribute to print agent-labeled output (matching the original Comedian/Critic format).
6. For text-only updates, print as streaming text.
7. Ensure proper indentation: the loop is inside all three `async with` blocks (credential, comedian_agent, critic_agent).

### Verification

- [ ] No `Console`, `CancellationToken`, `team.run_stream`, or `team.reset` calls remain
- [ ] `workflow.run_stream(user_input)` is used for streaming execution
- [ ] Agent names are displayed in output, matching the original Comedian/Critic display format
- [ ] Output header says "Microsoft Agent Framework"
- [ ] No explicit reset call — workflow handles state internally

---

## Task 3.6: Verify Complete File Structure

**File(s)**: `SemanticKernelSamples/joke_agent_autogen.py`
**Action**: Review

### Target State — Complete File

```python
#!/usr/bin/env python
"""
Joke Agent using Microsoft Agent Framework

Modernized from AutoGen:
- Uses Azure AI Foundry via AzureAIClient
- Two agents (Comedian + Critic) in a sequential workflow
- Replaces RoundRobinGroupChat with SequentialBuilder
"""

import asyncio
import os
import random
from typing import Annotated

from dotenv import load_dotenv

from azure.identity.aio import DefaultAzureCredential
from agent_framework.azure import AzureAIClient
from agent_framework.workflows import SequentialBuilder

# Load environment variables
load_dotenv(override=True)


# --------- Tools --------- #

def get_random_joke_topic() -> str:
    """Gets a random topic for telling a joke."""
    topics = [
        "programmers", "artificial intelligence", "cats",
        "coffee", "work meetings", "code bugs",
        "machine learning", "the cloud", "Python vs JavaScript",
        "Stack Overflow", "Git commits", "debugging",
    ]
    return f"Selected topic: {random.choice(topics)}"


def rate_joke(joke: Annotated[str, "The joke text to rate"]) -> str:
    """Rates a joke from 1 to 10."""
    rating = random.randint(5, 10)
    emojis = "😄" * (rating // 2)
    return f"Rating: {rating}/10 {emojis}"


# --------- Main workflow --------- #

async def main() -> None:
    # Read Azure AI Foundry settings
    endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT") or os.getenv("AZURE_AI_ENDPOINT") or os.getenv("AZURE_OPENAI_ENDPOINT")
    model = os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME") or os.getenv("AZURE_AI_MODEL_DEPLOYMENT") or os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")

    if not endpoint or not model:
        print("Error: Configure FOUNDRY_PROJECT_ENDPOINT and FOUNDRY_MODEL_DEPLOYMENT_NAME")
        print("(or AZURE_AI_ENDPOINT / AZURE_OPENAI_ENDPOINT)")
        return

    async with DefaultAzureCredential() as credential:
        client = AzureAIClient(
            project_endpoint=endpoint,
            model_deployment_name=model,
            credential=credential,
        )

        # Create the comedian agent
        async with client.create_agent(
            name="Comedian",
            instructions="""
You are a professional comedian who tells very funny jokes.

When asked for a joke:
1. Use the get_random_joke_topic tool to get a topic
2. Tell a creative and funny joke about that topic
3. End your turn so the critic can evaluate your joke

Be creative, use wordplay and clever humor.
""",
            tools=[get_random_joke_topic],
        ) as comedian_agent:

            # Create the critic agent
            async with client.create_agent(
                name="Critic",
                instructions="""
You are a comedy critic who evaluates jokes.

When the comedian tells a joke:
1. Use the rate_joke tool to give a rating
2. Provide brief constructive feedback
3. Say "APPROVED" if the joke deserves more than 7 points, or "DONE" to finish

Be fair but funny in your reviews.
""",
                tools=[rate_joke],
            ) as critic_agent:

                # Build sequential workflow (replaces RoundRobinGroupChat)
                workflow = (
                    SequentialBuilder(participants=[comedian_agent, critic_agent])
                    .build()
                )

                print("🎭 Joke System with Microsoft Agent Framework")
                print("=" * 50)
                print("Agents: Comedian 🎤 and Critic 📝")
                print("Type 'exit' to quit\n")

                while True:
                    user_input = input("You: ").strip()

                    if user_input.lower() in ["salir", "exit", "quit"]:
                        print("Goodbye! 👋")
                        break

                    if not user_input:
                        continue

                    print("\n" + "=" * 50)

                    # Run the workflow (replaces team.run_stream)
                    async for update in workflow.run_stream(user_input):
                        if hasattr(update, "agent_name") and hasattr(update, "text"):
                            if update.text:
                                print(f"\n---------- {update.agent_name} ----------")
                                print(update.text)
                        elif hasattr(update, "text") and update.text:
                            print(update.text, end="", flush=True)

                    print("\n" + "=" * 50 + "\n")


if __name__ == "__main__":
    asyncio.run(main())
```

### Verification

- [ ] File runs without import errors (given `agent-framework` is installed)
- [ ] No AutoGen imports, classes, or patterns remain
- [ ] All tool functions have docstrings and `Annotated` type hints where applicable
- [ ] `SequentialBuilder` orchestrates Comedian → Critic in sequence
- [ ] The interactive CLI loop works: accepts user input, runs the workflow, displays agent-labeled output
- [ ] Both agents are created via `client.create_agent()` with proper instructions and tools
