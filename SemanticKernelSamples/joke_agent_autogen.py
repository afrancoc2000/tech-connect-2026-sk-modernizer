#!/usr/bin/env python
"""
Joke Agent using AutoGen
A simple multi-agent system that tells and evaluates jokes using AutoGen.
"""

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

# Load environment variables
load_dotenv()


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
        system_message="""
        You are a professional comedian who tells very funny jokes.
        
        When asked for a joke:
        1. Use the get_random_joke_topic tool to get a topic
        2. Tell a creative and funny joke about that topic
        3. End your turn so the critic can evaluate your joke
        
        Be creative, use wordplay and clever humor.
        """,
    )
    
    # Create the critic agent
    critic_agent = AssistantAgent(
        name="Critic",
        model_client=model_client,
        tools=[rate_tool],
        system_message="""
        You are a comedy critic who evaluates jokes.
        
        When the comedian tells a joke:
        1. Use the rate_joke tool to give a rating
        2. Provide brief constructive feedback
        3. Say "APPROVED" if the joke deserves more than 7 points, or "DONE" to finish
        
        Be fair but funny in your reviews.
        """,
    )
    
    # Create termination condition
    termination = TextMentionTermination("DONE")
    
    # Create the team with round-robin chat
    team = RoundRobinGroupChat(
        participants=[comedian_agent, critic_agent],
        termination_condition=termination,
        max_turns=6,
    )
    
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


if __name__ == "__main__":
    asyncio.run(main())
