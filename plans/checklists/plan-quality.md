# Plan Quality Checklist: SemanticKernelSamples Modernization

**Purpose**: Validate implementation plan completeness and technical accuracy
**Created**: 2026-02-12
**Plan**: `plans/implementation-plan.md`
**Specification**: `docs/specs/SemanticKernelSamples-modernization-spec.md` (quality checklist only — no full spec available)

## Technical Accuracy

- [x] All pattern mappings align with official MAF migration guides
- [x] Target code examples use current Agent Framework API (not deprecated patterns)
- [x] Dependency versions are correct and compatible
- [x] Import paths match the `agent_framework` package structure
- [x] Semantic Kernel mappings: `Kernel` → `AzureAIClient`/`create_agent`, `@kernel_function` → plain functions, `ChatHistory` → `AgentThread`, `FunctionChoiceBehavior.Auto()` → automatic, `AzureChatCompletion` → `AzureAIClient`
- [x] AutoGen mappings: `AssistantAgent` → `create_agent`, `RoundRobinGroupChat` → `SequentialBuilder`, `FunctionTool` → plain functions, `AzureOpenAIChatCompletionClient` → `AzureAIClient`, `TextMentionTermination` → workflow completion, `Console` → `run_stream` loop

## Completeness

- [x] Every source file in the inventory has transformation tasks
  - `joke_agent_sk.py`: Tasks 2.1–2.5
  - `joke_agent_autogen.py`: Tasks 3.1–3.6
  - `requirements.txt`: Task 1.1
  - `.env.example`: Task 1.2
  - `README.md`: Task 4.2
  - `joke_agent_MAF.py`: Task 4.1 (reconciliation)
- [x] All dependencies are addressed (additions: `agent-framework --pre`; removals: `semantic-kernel`, `autogen-agentchat`, `autogen-ext`, `openai`)
- [x] Environment variable changes are documented (new: `FOUNDRY_PROJECT_ENDPOINT`, `FOUNDRY_MODEL_DEPLOYMENT_NAME`; removed: `AZURE_OPENAI_API_KEY`)
- [x] Entry points and execution modes are covered (CLI interactive loop for both agents)

## Executability

- [x] Tasks are ordered so the project builds after each phase
  - Phase 1 (dependencies) → Phase 2/3 (transforms) → Phase 4 (integration) → Phase 5 (validation)
- [x] No circular dependencies between tasks
- [x] Each task has clear, atomic step-by-step instructions
- [x] Verification criteria exist for every task
- [x] Before/after code patterns provided for all code transformation tasks
- [x] Complete target file shown for both `joke_agent_sk.py` (Task 2.5) and `joke_agent_autogen.py` (Task 3.6)

## Traceability

- [ ] N/A — No full modernization specification exists; plan is based on codebase analysis
  - The specification file at `docs/specs/SemanticKernelSamples-modernization-spec.md` contains only a quality checklist, not functional requirements
  - All transformation decisions are grounded in framework pattern detection and official migration guides

## Notes

- The existing reference implementation `joke_agent_MAF.py` was used to validate target patterns for the single-agent case.
- The AutoGen multi-agent transformation (Phase 3) is the most complex phase due to the `RoundRobinGroupChat` → `SequentialBuilder` mapping and the nested async context managers pattern.
- The plan assumes `agent-framework` is available via `pip install agent-framework --pre` during the preview period. API changes may require plan updates.
- All checklist items pass (except Traceability, which is N/A due to missing full specification). The plan is ready for implementation.
