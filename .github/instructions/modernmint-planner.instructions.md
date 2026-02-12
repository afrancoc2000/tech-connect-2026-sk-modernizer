---
applyTo: "plans/**"
---

# Implementation Plan Instructions

When working with files under the `plans/` directory, follow these conventions:

## Plan Files

- Plans describe **HOW** to modernize an AI application — concrete technical steps, code transformations, and dependency changes.
- All code examples must use current Microsoft Agent Framework APIs (not deprecated Semantic Kernel or AutoGen patterns).
- Every task must include step-by-step instructions precise enough for an AI coding agent to execute without interpretation.
- Tasks must be ordered so the project remains buildable/runnable after each phase completes.
- Before/after code patterns must be provided for every code transformation task.

## Pattern Mapping Accuracy

- Semantic Kernel patterns map to Agent Framework per the [official SK migration guide](https://learn.microsoft.com/en-us/agent-framework/migration-guide/from-semantic-kernel/).
- AutoGen patterns map to Agent Framework per the [official AutoGen migration guide](https://learn.microsoft.com/en-us/agent-framework/migration-guide/from-autogen/).
- When no 1:1 mapping exists, document the assumption and chosen approach clearly.

## Quality Standards

- Every task has at least one verification criterion.
- No task references code that hasn't been created by a prior task.
- All dependency changes (additions and removals) are explicitly listed.
- Environment variable changes are documented.

## Target Code Style

- Python 3.10+ with async/await.
- Type annotations using `Annotated` for tool parameters.
- Docstrings on all tool functions (used as tool descriptions by MAF).
- Environment configuration via `.env` and `python-dotenv`.
- Use `agent_framework` import style.
- Use `--pre` flag for pip install during preview period.

## Workflow

1. The `@modernmint-spec` agent produces the specification at `specs/modernization-spec.md` (optional prerequisite).
2. The `@modernmint-planner` agent reads the specification and codebase, then generates the plan under `plans/`.
3. A quality checklist is generated at `plans/checklists/plan-quality.md`.
4. Once the plan is validated, an implementer executes the plan phases in order.
