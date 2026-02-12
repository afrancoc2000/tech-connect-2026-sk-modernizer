# Copyright (c) Microsoft. All rights reserved.

"""
AI Agent Code Modernizer

An AI agent that analyzes code written with Semantic Kernel or AutoGen
and provides modernization guidance to Microsoft Agent Framework.

This agent exposes the following tools:
- analyze_code_patterns: Analyze source code to identify AI agent patterns
- generate_modernized_code: Generate modernized Agent Framework code
- get_migration_guide: Get comprehensive migration documentation
"""

import asyncio
import os
from dotenv import load_dotenv
from azure.identity.aio import DefaultAzureCredential

from agent_framework.azure import AzureAIClient

from tools import (
    analyze_code_patterns,
    generate_modernized_code,
    get_migration_guide,
)

# Load environment variables
load_dotenv(override=True)

# Agent instructions
AGENT_INSTRUCTIONS = """You are an expert AI Agent Code Modernizer. Your role is to help developers 
migrate their AI agent applications from Semantic Kernel or AutoGen to Microsoft Agent Framework.

You have access to the following tools:

1. **analyze_code_patterns**: Use this to analyze source code and identify which framework 
   (Semantic Kernel or AutoGen) is being used, what patterns are present, and what needs to 
   be modernized.

2. **generate_modernized_code**: Use this to generate equivalent code using Microsoft Agent Framework.
   Always analyze the code first before generating modernized versions.

3. **get_migration_guide**: Use this to provide comprehensive migration documentation for 
   either Semantic Kernel or AutoGen to Agent Framework.

When helping developers:
1. First, analyze their code to understand what they're working with
2. Explain what patterns you've identified and what changes are needed
3. Generate modernized code that maintains the same functionality
4. Provide the relevant migration guide for reference

Be thorough, helpful, and ensure the generated code follows Agent Framework best practices:
- Use async/await patterns
- Use type annotations with Annotated for tool parameters
- Use streaming for better user experience
- Use thread persistence for multi-turn conversations
- For multi-agent scenarios, use WorkflowBuilder

Always remind developers to:
- Install the correct package versions
- Configure their .env file with Foundry credentials
- Review and test the generated code before using in production
"""


def create_modernizer_agent(credential):
    """Create and return the modernizer agent."""
    
    endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT")
    model = os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME")
    
    if not endpoint or not model:
        raise ValueError(
            "Please set FOUNDRY_PROJECT_ENDPOINT and FOUNDRY_MODEL_DEPLOYMENT_NAME "
            "environment variables. Copy .env.example to .env and configure it."
        )
    
    return AzureAIClient(
        project_endpoint=endpoint,
        model_deployment_name=model,
        credential=credential,
    ).create_agent(
        name="CodeModernizer",
        instructions=AGENT_INSTRUCTIONS,
        tools=[
            analyze_code_patterns,
            generate_modernized_code,
            get_migration_guide,
        ],
    )


async def run_cli():
    """Run the agent in CLI mode for testing."""
    
    print("=" * 60)
    print("AI Agent Code Modernizer")
    print("Modernize Semantic Kernel / AutoGen code to Agent Framework")
    print("=" * 60)
    print()
    
    async with (
        DefaultAzureCredential() as credential,
        create_modernizer_agent(credential) as agent,
    ):
        thread = agent.get_new_thread()
        
        print("Ready! Paste your code or ask for migration help.")
        print("Type 'quit' to exit, 'guide sk' or 'guide autogen' for guides.")
        print()
        
        while True:
            user_input = input("You: ").strip()
            
            if not user_input:
                continue
            
            if user_input.lower() == "quit":
                print("Goodbye!")
                break
            
            print("\nAssistant: ", end="", flush=True)
            
            async for chunk in agent.run_stream(user_input, thread=thread):
                if chunk.text:
                    print(chunk.text, end="", flush=True)
            
            print("\n")


if __name__ == "__main__":
    asyncio.run(run_cli())
