# Shared Output Protocols — BLOCKED / FAILED / READY / UNSURE

**Purpose**: Standardizes the four terminal output states that all Harness agents use.
**Applies to**: All 33 specialist agents. Every agent output must close with one of these states.

---

## The Four States

### READY-FOR-NEXT
The agent completed its assigned scope. Work is ready for the next step in the pipeline.

```
Status: READY-FOR-NEXT
Recommended Next Step: @<agent-name> — [specific focus or handoff detail]
```

**Conditions for READY-FOR-NEXT**:
- All DoD items have been addressed (or explicitly noted as out-of-scope with reason)
- Self-test passed (for implementation agents)
- No blocking ambiguities remain in the current task
- Output artifacts are complete and named correctly

**What READY-FOR-NEXT does NOT mean**:
- The work is correct (that is for @code-review to determine)
- The design is sound (that is for @code-review + @security-auditor)
- The work is deliverable (that is for @test-lead to determine)

---

### BLOCKED
The agent cannot proceed without information, a decision, or a dependency that
it does not currently have.

```
Status: BLOCKED
Blocked on: [precise description of what is missing]
Blocked by: [who can unblock: @dev-lead / user / @architect / @database / etc.]
What I have done so far: [work completed before the block]
What I need to proceed: [specific input or decision required]
```

**Use BLOCKED when**:
- The technical scheme has a gap (missing error code, undefined field type,
  unspecified auth model)
- The business requirement is ambiguous in a way that changes implementation
- A required upstream artifact is not yet available (schema not migrated,
  service not deployed, API not finalized)
- The task requires a scope decision that belongs to the user or @pm
- The agent has encountered a domain it is not equipped to handle (unfamiliar
  stack, unknown compliance framework)

**BLOCKED is not failure**. BLOCKED is the correct behavior when proceeding would
mean guessing, assuming, or creating technical debt. An agent that returns BLOCKED
early saves more rework than an agent that guesses through the gap.

**BLOCKED handling protocol**:
1. Main process receives BLOCKED
2. Identifies the blocker type: spec gap → @dev-lead; requirement gap → @client or user;
   architecture gap → @architect; infra dependency → @devops; domain unknown → surface to user
3. Dispatches to the appropriate unblocking agent
4. Returns to the original agent with the resolved input

---

### FAILED
The agent attempted the task, encountered a specific error or failure, and cannot
produce valid output. Unlike BLOCKED (precondition failure), FAILED means an
execution failure during the attempt.

```
Status: FAILED
Failure type: [technical error / quality gate failure / verification failure]
Failure point: [where in the workflow the failure occurred]
Error details: [specific error message, output, or test result]
Recovery path: [what would need to change for a retry to succeed]
Partial outputs: [any valid partial work that was produced]
```

**Use FAILED when**:
- Tests or verifications fail with specific errors
- Required tools return errors (compilation failure, test runner failure)
- The implementation produces demonstrably incorrect output
- The agent discovers a GP-* violation in its own work that it cannot resolve

**FAILED vs. BLOCKED**:
- BLOCKED: "I cannot start / continue — I need X before I can proceed"
- FAILED: "I tried and produced output, but the output is wrong / broken / fails verification"

**FAILED handling protocol**:
1. Main process receives FAILED
2. Classifies: implementation defect → re-dispatch with diagnosis; scheme gap → @dev-lead;
   architecture defect → @architect; 3rd rework → mandatory escalation (GP-O06)
3. Re-dispatches only with a changed input — not an identical retry
4. If 3 consecutive FAILEDs at same state: GP-O06 mandatory escalation

---

### UNSURE
The agent completed the task as specified but has a specific concern about
correctness, safety, or scope that it cannot resolve unilaterally.

```
Status: UNSURE
Concern type: [correctness / security / scope / performance / compatibility]
Specific concern: [precise description of what is uncertain]
Why I cannot resolve it: [the knowledge gap or context gap]
Recommended verification: [who should verify and what they should check]
Work produced: [description of the completed work]
```

**Use UNSURE when**:
- The implementation looks correct but the agent cannot verify a specific aspect
  (e.g., "I implemented JWT validation but cannot verify that the key rotation
  edge case is correctly handled without seeing the full auth service")
- The task was completed but the agent suspects a performance problem it cannot
  measure in the current context
- An assumption was made that was necessary to proceed but may not hold
  (these are ASSUMPTION NOTEs in the output body, plus UNSURE status if material)

**UNSURE is not weakness**. UNSURE is epistemic honesty. An agent that says
UNSURE with a specific concern produces a better outcome than an agent that says
READY-FOR-NEXT with a hidden assumption.

---

## State Machine

```
Task dispatched
    │
    ▼
Agent working
    │
    ├─── Cannot proceed (missing input/spec) ────→ BLOCKED
    │
    ├─── Attempted, output fails verification ───→ FAILED
    │
    ├─── Completed with a specific residual concern → UNSURE
    │
    └─── Completed, verified, no blockers ────────→ READY-FOR-NEXT
```

---

## Compound Status

An agent may produce both READY-FOR-NEXT and a set of ASSUMPTION NOTEs or
UNSURE flags on specific aspects. In this case:

```
Status: READY-FOR-NEXT (with caveats)
Caveats:
  ASSUMPTION: [what was assumed and why]
  UNSURE: [what was not verifiable + recommended next check]
Recommended Next Step: @code-review — specifically verify [caveat point]
```

The main process should propagate the caveats into the DispatchPlan for the
next agent so the concern does not get lost across handoffs.

---

## ★ Insight Integration

Post-dispatch ★ Insight MUST reflect the received status:

```
★ Insight (post-dispatch)
- Current action: received @backend return for Task-009
- Decision basis: status = BLOCKED on JWT refresh behavior gap in scheme T008
- Main risk: gap may require @dev-lead scheme revision before @backend can proceed
- User decision: none yet — routing to @dev-lead to patch the gap
```

A post-dispatch ★ Insight that says "looks good" when the status is BLOCKED is
a protocol failure (the "Green-Stamp" anti-pattern).

---

## Agent Execution SOP (merged from protocols/agent-sop-protocol.md)

**Source**: `~/.claude/shared/protocols/agent-sop-protocol.md` content merged here 2026-04-20.
The source file is retained at its original path for protocol-layer compatibility.

### Core Thinking Principles

**CoT (Chain of Thought)**: Before executing, explicitly reason through "why I'm doing this."
Reasoning chain must cover: user's real intent (surface vs. deep), whether input is complete,
potential risks on the execution path.

**ToT (Tree of Thoughts)**: At key decision points (tech selection, implementation path,
boundary decisions) expand 2–3 candidate branches, compare, then select one with explicit
rationale for rejecting the others. Never present a single option without alternatives.

**Minimum Necessary Principle**: Only do what the Task file explicitly requires.
Log opportunistic improvements — do not execute them. Tight boundaries > expanded scope.

### 7-Step SOP (SOP-7)

1. **Input Validation** — Read Task + associated files + upstream returns. Check completeness.
   Missing required fields or irresolvable ambiguity → immediate BLOCKED, do not continue.

2. **Intent Reconstruction (CoT)** — Answer: what is the real user/upstream intent? Why did
   this task land on me (not another agent)? What unique value does my specialization add?

3. **Scope Tightening** — Explicitly list: In-scope actions (file/function level), Out-of-scope
   items, and the boundary rationale.

4. **Solution Generation (ToT)** — For key decisions: list 2–3 candidate solutions with
   trade-offs. Select one and state why others were rejected.
   If the task is purely mechanical, state "no solution selection required."

5. **Execution** — Execute per selected plan. Leave traceable evidence (file path + line + change).
   Minor deviation → log and continue. Major deviation → stop, return BLOCKED or FAILED.

6. **Self-Review** — 5-item self-check before delivery:
   - [ ] Intent consistency: does output address the Step 2 intent?
   - [ ] Scope consistency: did I stay within the Step 3 boundary?
   - [ ] Quality baseline: meets this role's professional standards?
   - [ ] Risk disclosure: are all identified risks explicitly stated in output?
   - [ ] Verifiability: can downstream agents/users independently verify my claims?

7. **Structured Delivery** — Submit per `task-output-protocol.md` format:
   execution summary (3–5 sentences), artifact list, risk register,
   next-step recommendation, and terminal status (DONE / BLOCKED / FAILED).

### Escalation / Bounce-Back Protocol

Return BLOCKED or FAILED immediately (do not push through) when:

1. **Insufficient input** — Task or associated files lack critical info that cannot be inferred
2. **Out-of-jurisdiction** — Task genuinely belongs to another agent's domain
3. **Upstream scheme defect** — Root cause is in the upstream design/architecture
4. **Requirement contradiction** — Business description is self-contradictory or contradicts facts
5. **Resource/capability gap** — Requires tools, permissions, or domain knowledge this agent lacks

Required 4-element format for every BLOCKED:

```
BLOCKED 原因：[one sentence]
根本问题：[technical / requirement / architecture / resource / information]
建议去向：[which agent or user should handle this]
继续推进的前提：[prerequisite that must be met to unblock]
```

### Team Principles (All Agents)

- **Specialization, no overreach** — each agent does its job, does not proxy others
- **Evidence over intuition** — every judgment needs file/line/data support
- **BLOCKED is responsibility, not failure** — the wrong move is guessing through a gap
- **LLM hallucination awareness** — mark uncertain API/library/performance claims `[HALLUCINATION-RISK]`
- **External state for long tasks** — use progress-log/task files, not session memory
