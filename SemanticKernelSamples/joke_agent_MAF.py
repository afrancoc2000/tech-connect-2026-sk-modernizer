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
    # (You can swap this for an API-key-based credential if desired)
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