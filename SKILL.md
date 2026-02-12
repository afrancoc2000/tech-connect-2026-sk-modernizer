# SKILL.md — ModernMintSpec Skill

## Skill Name

`modernmint-spec`

## Description

Creates technology-agnostic modernization specifications for AI applications built with Semantic Kernel or AutoGen. Analyzes the existing codebase, catalogs capabilities, and produces a comprehensive specification document focused on **what** must change — without prescribing implementation details.

## When to Use

Use this skill when:
- A user asks to create, draft, or generate a modernization specification
- A user wants to define the scope of an AI application migration
- A user needs to document what an existing Semantic Kernel or AutoGen application does before modernizing it
- A user asks what needs to change to modernize their AI agent code

## Inputs

- **Natural-language description**: A brief statement of what the user wants to modernize and any specific goals or constraints.
- **Workspace context**: The skill reads source files in `AIAppsModernization/` and `SemanticKernelSamples/` to identify current framework patterns and capabilities.

## Outputs

1. **Specification file**: `specs/modernization-spec.md` — a structured document containing:
   - Executive summary
   - Current capabilities inventory
   - Actors and stakeholders
   - Modernization scope (in-scope and out-of-scope)
   - Functional requirements with acceptance criteria
   - Non-functional requirements
   - User scenarios
   - Integration points
   - Migration constraints
   - Measurable success criteria
   - Assumptions and risks
   - Open questions (maximum 3)

2. **Quality checklist**: `specs/checklists/spec-quality.md` — a validation checklist ensuring specification completeness.

## Behavior

1. Scan the workspace to identify Semantic Kernel and AutoGen patterns
2. Catalog all user-facing capabilities the existing application provides
3. Generate the specification using the template in the agent definition
4. Validate against quality criteria (no implementation details, testable requirements, measurable success criteria)
5. Self-correct up to 3 iterations if validation fails
6. Report completion and recommend invoking `@modernmint-planner` for the next step

## Constraints

- Specifications must be **technology-agnostic** — no framework names, SDKs, APIs, or code
- Focus on **WHAT** and **WHY**, never **HOW**
- Maximum **3 open questions** — resolve ambiguity with documented assumptions
- All functional requirements must be **testable and unambiguous**
- Success criteria must be **measurable from a user or business perspective**

## Source Frameworks Recognized

| Framework | Patterns |
|-----------|----------|
| Semantic Kernel | `Kernel`, `@kernel_function`, `ChatHistory`, `FunctionChoiceBehavior`, plugins, planners, connectors, memory stores |
| AutoGen | `AssistantAgent`, `UserProxyAgent`, `RoundRobinGroupChat`, `FunctionTool`, `TextMentionTermination`, multi-agent orchestration |

## Workflow Integration

This skill is the first step in the ModernMint workflow:

1. **Specify** (this skill) → Produces modernization specification
2. **Plan** (`@modernmint-planner`) → Generates technical implementation plan from the specification
