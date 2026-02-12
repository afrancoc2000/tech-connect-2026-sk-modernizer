#!/usr/bin/env python
"""
Joke Agent using Semantic Kernel
A simple agent that tells jokes using Azure OpenAI through Semantic Kernel.
"""

import asyncio
import os
from dotenv import load_dotenv

from semantic_kernel import Kernel
from semantic_kernel.connectors.ai.open_ai import AzureChatCompletion
from semantic_kernel.functions import kernel_function
from semantic_kernel.connectors.ai.function_choice_behavior import FunctionChoiceBehavior
from semantic_kernel.connectors.ai.chat_completion_client_base import ChatCompletionClientBase
from semantic_kernel.contents.chat_history import ChatHistory

# Load environment variables
load_dotenv()


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


async def main():
    # Create kernel
    kernel = Kernel()
    
    # Configure Azure OpenAI service
    # You can use either Azure OpenAI or OpenAI API
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
    history.add_system_message("""
    You are an expert comedian who tells funny jokes.
    When asked for a joke, first use the get_joke_topic function to get a topic,
    then tell a joke about that topic.
    After telling the joke, use the rate_joke function to rate it.
    Be creative and funny!
    """)
    
    print("🎭 Joke Agent with Semantic Kernel")
    print("=" * 50)
    print("Type 'exit' to quit\n")
    
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


if __name__ == "__main__":
    asyncio.run(main())
