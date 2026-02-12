#!/usr/bin/env python
# Copyright (c) Microsoft. All rights reserved.

"""
AI Agent Code Modernizer - MCP Server Entry Point

This module exposes the Code Modernizer agent as an MCP (Model Context Protocol) server,
allowing it to be used as a tool in GitHub Copilot Chat in Visual Studio Code.

Usage:
    # Run as MCP server (default - for GitHub Copilot integration)
    python main.py
    
    # Run as HTTP server (for debugging with Agent Inspector)
    python main.py --server
    
    # Run in CLI mode (for testing)
    python main.py --cli

To configure in VS Code for GitHub Copilot Chat:
1. Add to your VS Code settings.json or .vscode/mcp.json
2. Configure the MCP server pointing to this script
"""

import argparse
import asyncio
import os
import sys
from typing import Annotated

from dotenv import load_dotenv
from azure.core.credentials import AzureKeyCredential

# Load environment variables
load_dotenv(override=True)


def get_tools():
    """Get the modernization tools."""
    from tools import (
        analyze_code_patterns,
        generate_modernized_code,
        get_migration_guide,
    )
    return [analyze_code_patterns, generate_modernized_code, get_migration_guide]


async def run_as_mcp_server():
    """Run the agent as an MCP server for GitHub Copilot integration."""
    
    from agent_framework.azure import AzureAIClient
    from mcp.server.stdio import stdio_server
    
    endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT")
    model = os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME")
    api_key = os.getenv("FOUNDRY_API_KEY")
    
    if not endpoint or not model or not api_key:
        print(
            "ERROR: Please set FOUNDRY_PROJECT_ENDPOINT, FOUNDRY_MODEL_DEPLOYMENT_NAME, and FOUNDRY_API_KEY",
            file=sys.stderr
        )
        sys.exit(1)
    
    credential = AzureKeyCredential(api_key)
    
    async with (
        AzureAIClient(
            project_endpoint=endpoint,
            model_deployment_name=model,
            credential=credential,
        ).create_agent(
            name="CodeModernizer",
            description="Modernize AI agent code from Semantic Kernel or AutoGen to Microsoft Agent Framework",
            instructions="""You are an expert AI Agent Code Modernizer. Help developers 
migrate their AI agent applications from Semantic Kernel or AutoGen to Microsoft Agent Framework.
Analyze code patterns, generate modernized code, and provide migration guides.""",
            tools=get_tools(),
        ) as agent,
    ):
        # Expose the agent as an MCP server
        server = agent.as_mcp_server()
        
        # Run the MCP server using stdio transport
        async with stdio_server() as (read_stream, write_stream):
            await server.run(
                read_stream,
                write_stream,
                server.create_initialization_options()
            )


async def run_as_http_server():
    """Run the agent as an HTTP server for debugging with Agent Inspector."""
    
    from agent_framework.azure import AzureAIClient
    from azure.ai.agentserver.agentframework import from_agent_framework
    
    endpoint = os.getenv("FOUNDRY_PROJECT_ENDPOINT")
    model = os.getenv("FOUNDRY_MODEL_DEPLOYMENT_NAME")
    api_key = os.getenv("FOUNDRY_API_KEY")
    
    if not endpoint or not model or not api_key:
        print(
            "ERROR: Please set FOUNDRY_PROJECT_ENDPOINT, FOUNDRY_MODEL_DEPLOYMENT_NAME, and FOUNDRY_API_KEY",
            file=sys.stderr
        )
        sys.exit(1)
    
    credential = AzureKeyCredential(api_key)
    
    async with (
        AzureAIClient(
            project_endpoint=endpoint,
            model_deployment_name=model,
            credential=credential,
        ).create_agent(
            name="CodeModernizer",
            description="Modernize AI agent code from Semantic Kernel or AutoGen to Microsoft Agent Framework",
            instructions="""You are an expert AI Agent Code Modernizer. Help developers 
migrate their AI agent applications from Semantic Kernel or AutoGen to Microsoft Agent Framework.
Analyze code patterns, generate modernized code, and provide migration guides.""",
            tools=get_tools(),
        ) as agent,
    ):
        print("Starting Code Modernizer HTTP Server...")
        print("Server running on http://localhost:8087")
        print("Use AI Toolkit Agent Inspector to test the agent")
        
        # Run as HTTP server
        await from_agent_framework(agent).run_async()


async def run_cli():
    """Run the agent in CLI mode for testing."""
    from modernizer_agent import run_cli as cli_mode
    await cli_mode()


def main():
    """Main entry point with argument parsing."""
    
    parser = argparse.ArgumentParser(
        description="AI Agent Code Modernizer - Modernize SK/AutoGen code to Agent Framework"
    )
    parser.add_argument(
        "--server",
        action="store_true",
        help="Run as HTTP server for debugging with Agent Inspector"
    )
    parser.add_argument(
        "--cli",
        action="store_true",
        help="Run in interactive CLI mode"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=8087,
        help="Port for HTTP server mode (default: 8087)"
    )
    
    args = parser.parse_args()
    
    if args.cli:
        asyncio.run(run_cli())
    elif args.server:
        os.environ["AGENT_SERVER_PORT"] = str(args.port)
        asyncio.run(run_as_http_server())
    else:
        # Default: Run as MCP server for GitHub Copilot
        asyncio.run(run_as_mcp_server())


if __name__ == "__main__":
    main()
