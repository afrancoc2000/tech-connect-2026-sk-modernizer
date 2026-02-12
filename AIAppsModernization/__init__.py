# Copyright (c) Microsoft. All rights reserved.

"""
AI Agent Code Modernizer Package

A Microsoft Agent Framework-based agent that modernizes Semantic Kernel
and AutoGen code to Agent Framework.
"""

from tools import (
    analyze_code_patterns,
    generate_modernized_code,
    get_migration_guide,
)

__all__ = [
    "analyze_code_patterns",
    "generate_modernized_code", 
    "get_migration_guide",
]

__version__ = "1.0.0"
