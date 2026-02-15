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
import json as json_mod
import logging
import os
import sys
from typing import Annotated

from dotenv import load_dotenv
from azure.identity.aio import DefaultAzureCredential

# Load environment variables
load_dotenv(override=True)

logger = logging.getLogger("sanitize_payload")

##
#workound for APIM MCP translating null/empty fields as empty strings, which causes SDK crashes
##

class SanitizePayloadMiddleware:
    """Raw ASGI middleware that normalizes fields APIM MCP sends as empty strings.

    APIM's MCP-to-REST translation serializes optional object/array fields with
    no value as empty strings ("") instead of null/{}. The agent server SDK
    (AgentRunContextMiddleware) crashes when it calls .get() on a string.

    This middleware wraps the Starlette app and intercepts POST /runs and
    POST /responses to fix the payload before the SDK sees it.
    """

    # Fields that must be dict — convert "" to {}
    _DICT_FIELDS = frozenset({"metadata"})
    # Fields that must be dict/list/None — convert "" to None
    _OBJECT_FIELDS = frozenset({"agent", "text"})
    _LIST_FIELDS = frozenset({"tools"})
    # Fields that should be removed when empty string
    _STRIP_EMPTY = frozenset({
        "instructions", "model", "previous_response_id",
        "tool_choice", "truncation",
    })
    # Minimum length for a valid Foundry conversation ID (prefix + _ + partitionKey + entropy)
    _MIN_FOUNDRY_ID_LEN = 55

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        path = scope.get("path", "")
        method = scope.get("method", "GET")
        if method != "POST" or path not in ("/runs", "/responses"):
            await self.app(scope, receive, send)
            return

        # Buffer the full request body
        body_parts = []
        while True:
            message = await receive()
            body_parts.append(message.get("body", b""))
            if not message.get("more_body", False):
                break
        raw_body = b"".join(body_parts)

        # Parse, sanitize, re-serialize
        try:
            payload = json_mod.loads(raw_body)
            if isinstance(payload, dict):
                changed = False
                for f in self._DICT_FIELDS:
                    if f in payload and not isinstance(payload[f], dict):
                        payload[f] = {}
                        changed = True
                for f in self._OBJECT_FIELDS:
                    if f in payload and isinstance(payload[f], str) and payload[f] == "":
                        payload[f] = None
                        changed = True
                for f in self._LIST_FIELDS:
                    if f in payload and not isinstance(payload[f], list):
                        payload[f] = None
                        changed = True
                for f in self._STRIP_EMPTY:
                    if f in payload and isinstance(payload[f], str) and payload[f] == "":
                        del payload[f]
                        changed = True
                # conversation: must be a valid Foundry ID (conv_<50+ chars>) or dict with id
                # APIM MCP sends short strings like "session-1" that crash the SDK
                if "conversation" in payload:
                    conv = payload["conversation"]
                    if isinstance(conv, str) and len(conv) < self._MIN_FOUNDRY_ID_LEN:
                        del payload["conversation"]
                        changed = True
                    elif isinstance(conv, dict) and not conv.get("id"):
                        del payload["conversation"]
                        changed = True
                if changed:
                    logger.debug("Sanitized payload for %s", path)
                    raw_body = json_mod.dumps(payload).encode("utf-8")
        except (json_mod.JSONDecodeError, TypeError):
            pass  # Let the downstream middleware handle invalid JSON

        # Replace receive with one that returns the sanitized body
        body_sent = False

        async def patched_receive():
            nonlocal body_sent
            if not body_sent:
                body_sent = True
                return {"type": "http.request", "body": raw_body, "more_body": False}
            return {"type": "http.disconnect"}

        await self.app(scope, patched_receive, send)


# ==============================================================================
# Agent Instructions & Tools
# ==============================================================================

AGENT_INSTRUCTIONS = """\
You are an expert AI Agent Code Modernizer that converts AI agent code from \
Semantic Kernel or AutoGen to Microsoft Agent Framework (MAF).

WORKFLOW — For every modernization request:
1. Call analyze_code_patterns to identify the source framework and all patterns used
2. Call get_migration_guide to retrieve the mapping rules for the detected framework
3. Call generate_modernized_code to produce the base modernized structure
4. Enhance the generated code with your expertise to produce a COMPLETE, WORKING solution

OUTPUT REQUIREMENTS:
- ALWAYS include the COMPLETE modernized Python source file in a ```python code block
- Convert EVERY function, class, and pattern from the original — no placeholders or TODOs
- Preserve the original application's behavior and logic exactly
- Include all necessary imports and environment setup

KEY MAPPINGS (Semantic Kernel → MAF):
- Kernel() → AzureAIClient().create_agent()
- @kernel_function → plain functions with Annotated type hints as tools
- ChatHistory → agent.get_new_thread()
- FunctionChoiceBehavior.Auto() → automatic (built-in to MAF)
- kernel.add_plugin() → tools=[...] parameter in create_agent()
- AzureChatCompletion → AzureAIClient with DefaultAzureCredential

KEY MAPPINGS (AutoGen → MAF):
- AssistantAgent → AzureAIClient().create_agent()
- GroupChat/RoundRobinGroupChat → WorkflowBuilder
- UserProxyAgent → workflow handlers
- config_list/llm_config → AzureAIClient configuration
- register_function → tools parameter

NEVER respond with only analysis, guidance, or checklists. \
You MUST generate the complete modernized code."""


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
    
    if not endpoint or not model:
        print(
            "ERROR: Please set FOUNDRY_PROJECT_ENDPOINT and FOUNDRY_MODEL_DEPLOYMENT_NAME",
            file=sys.stderr
        )
        sys.exit(1)
    
    async with (
        DefaultAzureCredential() as credential,
        AzureAIClient(
            project_endpoint=endpoint,
            model_deployment_name=model,
            credential=credential,
        ).create_agent(
            name="CodeModernizer",
            instructions=AGENT_INSTRUCTIONS,
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
    
    if not endpoint or not model:
        print(
            "ERROR: Please set FOUNDRY_PROJECT_ENDPOINT and FOUNDRY_MODEL_DEPLOYMENT_NAME",
            file=sys.stderr
        )
        sys.exit(1)
    
    async with (
        DefaultAzureCredential() as credential,
        AzureAIClient(
            project_endpoint=endpoint,
            model_deployment_name=model,
            credential=credential,
        ).create_agent(
            name="CodeModernizer",
            instructions=AGENT_INSTRUCTIONS,
            tools=get_tools(),
        ) as agent,
    ):
        port = os.getenv("AGENT_SERVER_PORT", "8087")
        print("Starting Code Modernizer HTTP Server...")
        print(f"Server running on http://localhost:{port}")
        print("Use AI Toolkit Agent Inspector to test the agent")
        
        # Run as HTTP server with payload sanitization for APIM MCP compatibility
        server = from_agent_framework(agent)
        server.app = SanitizePayloadMiddleware(server.app)
        await server.run_async()


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
        "--mcp",
        action="store_true",
        help="Run as MCP server for GitHub Copilot integration"
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
    elif args.mcp:
        asyncio.run(run_as_mcp_server())
    else:
        # Default: Run as HTTP server for AI Toolkit Agent Inspector/Supervisor
        os.environ["AGENT_SERVER_PORT"] = str(args.port)
        asyncio.run(run_as_http_server())


if __name__ == "__main__":
    main()
