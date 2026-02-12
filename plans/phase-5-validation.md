# Phase 5: Validation & Testing

**Prerequisite**: Phase 4 — Integration

---

## Task 5.1: Static Validation — Import and Syntax Check

**File(s)**: All Python files in `SemanticKernelSamples/`
**Action**: Verify

### Step-by-Step Instructions

1. Run a syntax check on all modernized Python files:
   ```bash
   cd SemanticKernelSamples/
   python -m py_compile joke_agent_sk.py
   python -m py_compile joke_agent_autogen.py
   ```
2. Check for import errors (requires `agent-framework` to be installed):
   ```bash
   pip install -r requirements.txt
   python -c "import joke_agent_sk"
   python -c "import joke_agent_autogen"
   ```
3. Verify no legacy framework imports remain:
   ```bash
   grep -rn "semantic_kernel\|autogen_agentchat\|autogen_ext\|autogen_core" *.py
   ```
   This should return zero results.

### Verification

- [ ] All Python files pass `py_compile` without errors
- [ ] All Python files import successfully without `ModuleNotFoundError` (given `agent-framework` is installed)
- [ ] No legacy framework imports (`semantic_kernel`, `autogen_agentchat`, `autogen_ext`, `autogen_core`) exist in any `.py` file

---

## Task 5.2: Functional Validation — Single Agent (joke_agent_sk.py)

**File(s)**: `SemanticKernelSamples/joke_agent_sk.py`
**Action**: Test

### Step-by-Step Instructions

1. Ensure `.env` is configured with valid `FOUNDRY_PROJECT_ENDPOINT` and `FOUNDRY_MODEL_DEPLOYMENT_NAME` (or fallback Azure OpenAI variables).
2. Ensure Azure CLI is logged in: `az login`.
3. Run the single-agent joke application:
   ```bash
   cd SemanticKernelSamples/
   python joke_agent_sk.py
   ```
4. Test the following scenarios:

| Test | Input | Expected Result |
|------|-------|-----------------|
| Basic joke request | "Tell me a joke" | Agent calls `get_joke_topic`, tells a joke about the returned topic, then calls `rate_joke` and displays the rating |
| Follow-up conversation | "Tell me another one" | Agent remembers context from the thread and tells a new joke |
| Empty input | (press Enter) | No crash, prompts again |
| Exit command | "exit" | Agent prints "Goodbye! 👋" and exits cleanly |
| Streaming output | Any joke request | Response appears incrementally (character by character) |

5. Verify tool calling works (the agent should display a random topic and a rating in its response).

### Verification

- [ ] Application starts and displays the header "🎭 Joke Agent with Microsoft Agent Framework"
- [ ] Agent calls `get_joke_topic` tool when asked for a joke
- [ ] Agent calls `rate_joke` tool after telling a joke
- [ ] Conversation thread maintains context across multiple turns
- [ ] Streaming output works (text appears incrementally)
- [ ] Exit command terminates the application cleanly
- [ ] Empty input does not crash the application

---

## Task 5.3: Functional Validation — Multi-Agent Workflow (joke_agent_autogen.py)

**File(s)**: `SemanticKernelSamples/joke_agent_autogen.py`
**Action**: Test

### Step-by-Step Instructions

1. Ensure `.env` is configured and Azure CLI is logged in (same as Task 5.2).
2. Run the multi-agent joke application:
   ```bash
   cd SemanticKernelSamples/
   python joke_agent_autogen.py
   ```
3. Test the following scenarios:

| Test | Input | Expected Result |
|------|-------|-----------------|
| Basic joke request | "Tell me a joke about programming" | Comedian agent calls `get_random_joke_topic`, tells a joke; Critic agent calls `rate_joke`, provides feedback |
| Agent sequencing | Any joke request | Comedian speaks first, then Critic responds — matching sequential order |
| Agent labels | Any joke request | Output shows agent names (Comedian, Critic) in the output |
| Empty input | (press Enter) | No crash, prompts again |
| Exit command | "exit" | Application exits cleanly |
| Multiple rounds | Two consecutive joke requests | Both rounds complete successfully, workflow resets between rounds |

4. Verify both agents execute in sequence and tools are called correctly.

### Verification

- [ ] Application starts and displays the header "🎭 Joke System with Microsoft Agent Framework"
- [ ] Comedian agent calls `get_random_joke_topic` tool
- [ ] Critic agent calls `rate_joke` tool
- [ ] Agents execute in sequential order (Comedian first, then Critic)
- [ ] Agent names are displayed in the output
- [ ] Multiple rounds of jokes work without errors
- [ ] Exit command terminates the application cleanly
