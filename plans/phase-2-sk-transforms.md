# Phase 2: Semantic Kernel Agent Transformation

**Prerequisite**: Phase 1 — Setup

---

## Task 2.1: Replace Imports

**File(s)**: `SemanticKernelSamples/joke_agent_sk.py`
**Action**: Modify

### Current State

```python
import asyncio
import os
from dotenv import load_dotenv

from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion
from semantic_kernel.functions import kernel_function
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.connectors.ai.chat_completion_client_base import ChatCompletionClientBase
from semantic_kernel.contents.chat_history import ChatHistory
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
```

### Step-by-Step Instructions

1. Remove all `from semantic_kernel` import lines:
   - `from semantic_kernel import Kernel`
   - `from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion`
   - `from semantic_kernel.functions import kernel_function`
   - `from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior`
   - `from semantic_kernel.connectors.ai.chat_completion_client_base import ChatCompletionClientBase`
   - `from semantic_kernel.contents.chat_history import ChatHistory`
2. Add `import random` (will be needed at module level since the plugin class is removed).
3. Add `from typing import Annotated`.
4. Add `from azure.identity.aio import DefaultAzureCredential`.
5. Add `from agent_framework.azure import AzureAIClient`.

### Verification

- [ ] No `semantic_kernel` imports remain in the file
- [ ] `AzureAIClient` and `DefaultAzureCredential` are imported
- [ ] `Annotated` is imported from `typing`
- [ ] `random` is imported at module level

---

## Task 2.2: Convert JokePlugin to Standalone Tool Functions

**File(s)**: `SemanticKernelSamples/joke_agent_sk.py`
**Action**: Modify

### Current State

```python
class JokePlugin:
    """Plugin with joke-related functions."""
    
    @kernel_function(
        name="get_joke_topic",
        description="Returns a random topic for a joke"
    )
    def get_joke_topic(self) -> str:
        """Get a random joke topic."""
        import random
        topics = [
            "programmers", "artificial intelligence", "cats", 
            "coffee", "work meetings", "code bugs",
            "machine learning", "the cloud", "Python vs JavaScript"
        ]
        return random.choice(topics)
    
    @kernel_function(
        name="rate_joke",
        description="Rates a joke from 1 to 10"
    )
    def rate_joke(self, joke: str) -> str:
        """Rate the quality of a joke."""
        import random
        rating = random.randint(6, 10)
        return f"Rating: {rating}/10 - {'Excellent!' if rating >= 8 else 'Good!'}"
```

### Target State

```python
def get_joke_topic() -> str:
    """Get a random joke topic."""
    topics = [
        "programmers", "artificial intelligence", "cats",
        "coffee", "work meetings", "code bugs",
        "machine learning", "the cloud", "Python vs JavaScript",
    ]
    return random.choice(topics)


def rate_joke(joke: Annotated[str, "The joke to be rated"]) -> str:
    """Rate the quality of a joke."""
    rating = random.randint(6, 10)
    return f"Rating: {rating}/10 - {'Excellent!' if rating >= 8 else 'Good!'}"
```

### Step-by-Step Instructions

1. Remove the `class JokePlugin:` class definition and its docstring.
2. Remove the `@kernel_function(...)` decorators from both methods.
3. Convert `get_joke_topic(self)` to a standalone function `get_joke_topic()` (remove `self` parameter).
4. Convert `rate_joke(self, joke: str)` to `rate_joke(joke: Annotated[str, "The joke to be rated"])` (remove `self`, add `Annotated` type hint with description).
5. Remove the `import random` statements inside each method (random is now imported at module level per Task 2.1).
6. Keep the docstrings — MAF uses them as tool descriptions.
7. De-indent both functions to module level.

### Verification

- [ ] No `class JokePlugin` exists
- [ ] No `@kernel_function` decorators exist
- [ ] `get_joke_topic()` is a module-level function with no `self` parameter
- [ ] `rate_joke()` uses `Annotated[str, "The joke to be rated"]` for the `joke` parameter
- [ ] Both functions have docstrings
- [ ] No `import random` inside function bodies (uses module-level import)

---

## Task 2.3: Replace Kernel and Service Configuration with AzureAIClient

**File(s)**: `SemanticKernelSamples/joke_agent_sk.py`
**Action**: Modify

### Current State

```python
async def main():
    # Create kernel
    kernel = Kernel()
    
    # Configure Azure OpenAI service
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    api_key = os.getenv("AZURE_OPENAI_API_KEY")
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")
    
    if not endpoint or not api_key:
        print("Error: Configure AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_API_KEY")
        print("You can also set AZURE_OPENAI_DEPLOYMENT_NAME (default: gpt-4o)")
        return
    
    # Add Azure OpenAI chat service
    chat_service = AzureChatCompletion(
        deployment_name=deployment,
        endpoint=endpoint,
        api_key=api_key,
    )
    kernel.add_service(chat_service)
    
    # Add the joke plugin
    kernel.add_plugin(JokePlugin(), plugin_name="jokes")
    
    # Create chat history
    history = ChatHistory()
    history.add_system_message("""...""")
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

        system_instructions = """
You are an expert comedian who tells funny jokes.
When asked for a joke, first use the get_joke_topic tool to get a topic,
then tell a joke about that topic.
After telling the joke, use the rate_joke tool to rate it.
Be creative and funny!
"""

        async with client.create_agent(
            name="JokeAgent",
            instructions=system_instructions,
            tools=[get_joke_topic, rate_joke],
        ) as agent:
```

### Step-by-Step Instructions

1. Remove `kernel = Kernel()`.
2. Replace `os.getenv("AZURE_OPENAI_ENDPOINT")` with a fallback chain: `os.getenv("FOUNDRY_PROJECT_ENDPOINT") or os.getenv("AZURE_AI_ENDPOINT") or os.getenv("AZURE_OPENAI_ENDPOINT")`.
3. Remove `api_key = os.getenv("AZURE_OPENAI_API_KEY")`.
4. Replace `deployment` variable with `model` using fallback chain: `os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME") or os.getenv("AZURE_AI_MODEL_DEPLOYMENT") or os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")`.
5. Update the validation check to test `endpoint` and `model` (not `api_key`).
6. Update the error message to reference `FOUNDRY_PROJECT_ENDPOINT` and `FOUNDRY_MODEL_DEPLOYMENT_NAME`.
7. Replace the `AzureChatCompletion(...)` + `kernel.add_service(...)` block with `DefaultAzureCredential` context manager and `AzureAIClient(...)` construction.
8. Remove `kernel.add_plugin(JokePlugin(), plugin_name="jokes")`.
9. Extract the system message from `ChatHistory().add_system_message(...)` into a `system_instructions` string variable.
10. Remove `ChatHistory()` creation.
11. Replace with `client.create_agent(name="JokeAgent", instructions=system_instructions, tools=[get_joke_topic, rate_joke])` as an async context manager.
12. Add return type annotation `-> None` to `main()`.

### Verification

- [ ] No `Kernel()`, `AzureChatCompletion`, `ChatHistory`, `add_service`, or `add_plugin` calls exist
- [ ] `AzureAIClient` is constructed with `project_endpoint`, `model_deployment_name`, and `credential`
- [ ] `DefaultAzureCredential` is used as an async context manager
- [ ] `create_agent()` is called with `name`, `instructions`, and `tools` parameters
- [ ] Tool functions are passed as a list `[get_joke_topic, rate_joke]`
- [ ] System instructions match the original system message content

---

## Task 2.4: Replace ChatHistory and Chat Loop with AgentThread and Streaming

**File(s)**: `SemanticKernelSamples/joke_agent_sk.py`
**Action**: Modify

### Current State

```python
    # Configure function calling
    execution_settings = kernel.get_prompt_execution_settings_from_service_id(chat_service.service_id)
    execution_settings.function_choice_behavior = FunctionChoiceBehavior.Auto()
    
    while True:
        user_input = input("You: ").strip()
        
        if user_input.lower() in ['salir', 'exit', 'quit']:
            print("Goodbye! 👋")
            break
        
        if not user_input:
            continue
        
        history.add_user_message(user_input)
        
        # Get response from the model
        chat_function = kernel.get_service(type=ChatCompletionClientBase)
        result = await chat_function.get_chat_message_contents(
            chat_history=history,
            settings=execution_settings,
            kernel=kernel,
        )
        
        if result:
            response = result[0].content
            history.add_assistant_message(response)
            print(f"\n🤖 Agent: {response}\n")
```

### Target State

```python
            # Thread keeps conversation history (replaces ChatHistory)
            thread = agent.get_new_thread()

            print("🎭 Joke Agent with Microsoft Agent Framework")
            print("=" * 50)
            print("Type 'exit' to quit\n")

            while True:
                user_input = input("You: ").strip()

                if user_input.lower() in ["salir", "exit", "quit"]:
                    print("Goodbye! 👋")
                    break

                if not user_input:
                    continue

                # Stream response (replaces get_chat_message_contents)
                print("\n🤖 Agent: ", end="", flush=True)
                full_text = []
                async for chunk in agent.run_stream(user_input, thread=thread):
                    if chunk.text:
                        print(chunk.text, end="", flush=True)
                        full_text.append(chunk.text)
                print("\n")
```

### Step-by-Step Instructions

1. Remove the `execution_settings` block:
   - `execution_settings = kernel.get_prompt_execution_settings_from_service_id(chat_service.service_id)`
   - `execution_settings.function_choice_behavior = FunctionChoiceBehavior.Auto()`
2. Add `thread = agent.get_new_thread()` inside the `create_agent` context manager, before the loop.
3. Update the header print to say "Microsoft Agent Framework" instead of "Semantic Kernel".
4. Remove `history.add_user_message(user_input)`.
5. Remove the `chat_function = kernel.get_service(type=ChatCompletionClientBase)` call.
6. Replace `get_chat_message_contents(...)` with streaming:
   - Add `print("\n🤖 Agent: ", end="", flush=True)` before the stream.
   - Add `full_text = []` for accumulation.
   - Add `async for chunk in agent.run_stream(user_input, thread=thread):` loop.
   - Inside the loop: `if chunk.text: print(chunk.text, end="", flush=True)` and `full_text.append(chunk.text)`.
   - After the loop: `print("\n")` for a newline.
7. Remove `history.add_assistant_message(response)` — the thread automatically maintains history.
8. Ensure proper indentation: the chat loop is inside the `async with client.create_agent(...)` block.

### Verification

- [ ] No `FunctionChoiceBehavior`, `execution_settings`, `get_prompt_execution_settings_from_service_id`, or `get_chat_message_contents` calls exist
- [ ] No `ChatHistory` methods (`add_user_message`, `add_assistant_message`) are called
- [ ] `agent.get_new_thread()` creates the conversation thread
- [ ] `agent.run_stream(user_input, thread=thread)` is used for streaming responses
- [ ] Output header says "Microsoft Agent Framework"

---

## Task 2.5: Verify Complete File Structure

**File(s)**: `SemanticKernelSamples/joke_agent_sk.py`
**Action**: Review

### Target State — Complete File

```python
#!/usr/bin/env python
"""
Joke Agent using Microsoft Agent Framework

Modernized from Semantic Kernel:
- Uses Azure AI model via AzureAIClient
- Exposes two tools: get_joke_topic and rate_joke
- Keeps an interactive CLI chat loop
"""

import asyncio
import os
import random
from typing import Annotated

from dotenv import load_dotenv

from azure.identity.aio import DefaultAzureCredential
from agent_framework.azure import AzureAIClient

# Load environment variables
load_dotenv(override=True)


# --------- Tools (modernized from JokePlugin) --------- #

def get_joke_topic() -> str:
    """Get a random joke topic."""
    topics = [
        "programmers", "artificial intelligence", "cats",
        "coffee", "work meetings", "code bugs",
        "machine learning", "the cloud", "Python vs JavaScript",
    ]
    return random.choice(topics)


def rate_joke(joke: Annotated[str, "The joke to be rated"]) -> str:
    """Rate the quality of a joke."""
    rating = random.randint(6, 10)
    return f"Rating: {rating}/10 - {'Excellent!' if rating >= 8 else 'Good!'}"


# --------- Main agent loop --------- #

async def main() -> None:
    # Read Azure AI Foundry settings
    endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT") or os.getenv("AZURE_AI_ENDPOINT") or os.getenv("AZURE_OPENAI_ENDPOINT")
    model = os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME") or os.getenv("AZURE_AI_MODEL_DEPLOYMENT") or os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")

    if not endpoint or not model:
        print("Error: Configure FOUNDRY_PROJECT_ENDPOINT and FOUNDRY_MODEL_DEPLOYMENT_NAME")
        print("(or AZURE_AI_ENDPOINT / AZURE_OPENAI_ENDPOINT)")
        return

    # Use DefaultAzureCredential for production-style auth
    async with DefaultAzureCredential() as credential:
        client = AzureAIClient(
            project_endpoint=endpoint,
            model_deployment_name=model,
            credential=credential,
        )

        system_instructions = """
You are an expert comedian who tells funny jokes.
When asked for a joke, first use the get_joke_topic tool to get a topic,
then tell a joke about that topic.
After telling the joke, use the rate_joke tool to rate it.
Be creative and funny!
"""

        # Create the agent with tools (replaces Kernel + plugins)
        async with client.create_agent(
            name="JokeAgent",
            instructions=system_instructions,
            tools=[get_joke_topic, rate_joke],
        ) as agent:

            # Thread keeps conversation history (replaces ChatHistory)
            thread = agent.get_new_thread()

            print("🎭 Joke Agent with Microsoft Agent Framework")
            print("=" * 50)
            print("Type 'exit' to quit\n")

            while True:
                user_input = input("You: ").strip()

                if user_input.lower() in ["salir", "exit", "quit"]:
                    print("Goodbye! 👋")
                    break

                if not user_input:
                    continue

                # Stream response (replaces get_chat_message_contents)
                print("\n🤖 Agent: ", end="", flush=True)
                full_text = []
                async for chunk in agent.run_stream(user_input, thread=thread):
                    if chunk.text:
                        print(chunk.text, end="", flush=True)
                        full_text.append(chunk.text)
                print("\n")


if __name__ == "__main__":
    asyncio.run(main())
```

### Verification

- [ ] File runs without import errors (given `agent-framework` is installed)
- [ ] No Semantic Kernel imports, classes, or patterns remain
- [ ] All tool functions have docstrings and `Annotated` type hints where applicable
- [ ] The interactive CLI loop works: accepts user input, streams agent response, maintains conversation
- [ ] File structure matches the reference implementation `joke_agent_MAF.py`
