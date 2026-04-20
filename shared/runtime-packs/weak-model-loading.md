# Weak-Model Loading Protocol

**Purpose**: Fills the broken link in `output-styles/harness-orchestrator.md`
that previously pointed to `shared/references/weak-model-loading.md` (removed).
New canonical location: `shared/runtime-packs/weak-model-loading.md`.

---

## What Is Weak-Model Mode

Weak-model mode applies when the executing LLM is one of:
- GLM (Zhipu)
- MiniMax
- DeepSeek (any variant)
- Doubao
- Step
- Any model with context window < 32K tokens
- Any model declared via `project-mode: weak-model` in project CLAUDE.md

Weak models exhibit predictable failure modes under high context load:
- **Primacy dominance**: instructions near the start are over-weighted; later
  instructions are under-weighted or ignored
- **Recency cliff**: instructions past ~4K tokens from prompt start have sharply
  reduced reliability
- **Context bloat collapse**: loading 10+ agent files into context simultaneously
  causes the model to merge rule sets, follow the wrong agent's rules, or ignore
  all rules entirely

---

## Loading Rules (Weak-Model Mode)

### Rule 1: Maximum 3–5 Files Per Dispatch
Do not load every relevant agent file "just in case." Determine the exact
next step and load only:
1. The target agent L1 (`agents/<name>.md`)
2. One topic-specific runtime pack file if the task is domain-specific
3. The current task file
4. One template (if relevant)
5. Dispatch table (if routing is ambiguous)

### Rule 2: Prefer Core Section Injection
If an agent's L1 has `<!-- core-start -->` / `<!-- core-end -->` markers, inject
only the core segment. This reduces token footprint while preserving critical rules.

### Rule 3: Single Agent Input Target ≤ 2K Tokens
Tasks exceeding ~2K tokens of context for a single agent input must be split
into sub-tasks before dispatch. The main process splits; agents do not self-split.

### Rule 4: All 6 DispatchPlan Fields Mandatory
In weak-model mode, the compact ★ Insight shortcut is not sufficient. Every
non-trivial dispatch requires a full 6-field DispatchPlan. Incomplete plan = dispatch refused.

### Rule 5: Fast-Path Disabled
The fast-path (Section 15 of harness-orchestrator-longform.md) is disabled in
weak-model mode. All tasks run the full 12-step workflow. The risk of a weak
model silently skipping a quality gate outweighs the efficiency gain.

### Rule 6: Compact Trigger at 60% Context (Not 80%)
In standard mode, compact is triggered at 80% context. In weak-model mode,
trigger compact at 60% to reduce context degradation risk in long sessions.

### Rule 7: ★ Insight Strict Enforcement
Hook-D's four-element ★ Insight check is strict in weak-model mode. Maintenance
mode downgrade does NOT apply. All four elements must be present:
- Current action
- Decision basis
- Main risk
- User decision

### Rule 8: Entry Command Preference
Prefer structured entry commands over free-form orchestrator judgment:
- `/需求蒸馏` — requirement refinement
- `/新功能` — new feature workflow
- `/快速修复` — fast fix
- `/代码审查` — code review
- `/安全检查` — security check
- `/会话交接` — session handover

Orchestrator free-form judgment should be < 20% of turns in weak-model mode.

---

## Context Loading Sequence for Weak Models

When starting a new dispatch in weak-model mode, load in this order:

```
Step 1: task file (current state, inputs, DoD)
Step 2: agent L1 only (agents/<name>.md)
Step 3: one topic runtime pack (if task is domain-specific)
Step 4: dispatch table (if routing decision needed)
```

Do NOT pre-load:
- Full agent roster
- Multiple agent files
- longform governance documents
- All runtime packs "for reference"

---

## Anti-Patterns (Weak-Model Specific)

**Context Bloat**: loading all 33 agent files into context. The weak model
will blend rules from multiple agents and follow none of them reliably.
Fix: load only the target agent L1.

**Rule Burial**: placing the most important rule at line 200 of a 300-line
prompt. Weak models have recency-primacy gradients — critical rules must be
near the start (Primacy Anchor) and near the end (Recency Anchor).
Fix: ensure L1 has rules at top + final-reminder at bottom.

**Implicit Routing**: assuming the weak model will infer which agent to call
from context. Weak models do not reliably infer dispatch table routing.
Fix: state the target agent explicitly in every dispatch instruction.

**Compact Delay**: allowing context to reach 80-90% before compacting.
At this level, weak models have significant context degradation.
Fix: trigger compact at 60% in weak-model mode.

---

## When to Declare Weak-Model Mode

In project CLAUDE.md:
```yaml
project-mode: weak-model
```

Or via slash command:
```
/弱模型模式 on
```

Confirm the active mode in each ★ Insight block until the mode is stable.

---

## References

- Full orchestration rules: `shared/guides/harness-orchestrator-longform.md §14.3`
- Runtime pack architecture: `shared/runtime-packs/README.md`
- Hook-D ★ Insight enforcement: `hooks/hook-d-insight-check.sh`
- Dispatch table: `shared/guides/dispatch-table.md`
