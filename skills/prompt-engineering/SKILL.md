---
name: prompt-engineering
description: LLM agent specification and team design methodology for the Harness team. Covers LLM behavioral mechanics (primacy/recency anchors, instruction format, nesting depth), reasoning pattern design (CoT, ToT, reflexion), agent team architecture (responsibility matrices, boundary operationalizability, dispatch signals), drift diagnosis taxonomy (specification defect, instruction conflict, capability boundary), and prompt quality audit across four dimensions (behavioral precision, boundary clarity, output contract completeness, bar compliance).
type: skill
---

# Prompt Engineering Skill

## 1. LLM Behavioral Mechanics

**Primacy/Recency Anchor**: Critical rules at top (primacy) and bottom (recency) of prompt. Instructions in middle are more likely overlooked.

**Instruction format hierarchy**: XML-tagged sections > plain markdown; `NEVER X` > `avoid X`; positive instructions > negative instructions.

**Nesting depth stability**: Conditional logic beyond 3 levels produces inconsistent execution. Flatten to lookup tables where possible.

**Positive vs negative instruction asymmetry**: `DO include X` > `DON'T omit X`. Positive instructions are more reliably executed.

## 2. Reasoning Pattern Design

**Chain-of-Thought (CoT)**: Force reasoning decomposition in numbered steps > prose instruction. Each step should be verifiable.

**Tree-of-Thoughts (ToT)**: 2-4 discrete candidates with evaluation criteria. Degrades with >5 candidates — too many options produce analysis paralysis.

**Reflexion self-check**: Binary, specific, actionable items. Vague items ("is this good?") produce no improvement.

## 3. Agent Team Architecture

**Responsibility matrix analysis**:
- Full agent inventory → coverage matrix
- Overlaps are more dangerous than gaps (ambiguous routing)
- New agent necessity — four-question test: capability gap? closest agent? new boundary problems? value > cost?

**Boundary operationalizability**: 5 test inputs in boundary region; each must be assignable to one agent unambiguously. "大概" is not a boundary description.

**Dispatch signal architecture**:
- Signal semantic purity: every strong trigger owned by exactly one agent
- Strong vs weak trigger classification: strong = routes without context; weak = requires confirmation
- Fast-path condition discipline: single-file, no schema change, no new API, unambiguous requirement

## 4. Drift Diagnosis Taxonomy

Three root cause classes:

| Class | Symptom | Fix Strategy |
|---|---|---|
| **Specification Defect** | No prompt section governs the drifted behavior | Add missing specification |
| **Instruction Conflict** | Two rules cannot be simultaneously satisfied | Add precedence rule or remove one rule |
| **LLM Capability Boundary** | Drift recurs across multiple prompt variations | Decompose task, don't add more rules |

Evidence required for diagnosis: input (what was given) + expected output (cite spec section) + actual output (what happened). Without this triad → BLOCK.

## 5. Prompt Quality Audit (Four Dimensions)

| Dimension | Assessment Criteria |
|---|---|
| **Behavioral Precision** | Do the rules produce consistent, testable behavior? Can each rule be checked mechanically? |
| **Boundary Clarity** | Is the division between this agent and adjacent agents operationally verifiable? |
| **Output Contract Completeness** | Does the output contract provide enough structure for the main process to route the output? |
| **Bar Compliance** | Does the prompt meet the structural bar: rules/identity/workflow/output-contract/final-reminder sections? |

## 6. Constraint Effectiveness Analysis

**Operational vs courtesy constraints**: Operational = detectable failure mode; Courtesy = not clearly detectable. Only operational constraints belong in rules.

**Rule executability test**: Can this rule be checked mechanically? If no → unexecutable, do not add.

## 7. New Agent Proliferation Cost

Every additional agent increases orchestration complexity super-linearly:
- N new boundary ambiguity problems
- Routing complexity increase
- Maintenance overhead
- Compound failure modes

Bar for new agent: existing agents cannot cover this scope without fundamental role violation — not "this new agent would be convenient."

## 8. Anthropic Bar for Agent Prompts

Structural standard applied uniformly to all agents including the meta-engineer:
- 5 core sections: rules, identity, workflow, output-contract, final-reminder
- Description: 4-sentence format (function → upstream/downstream → boundary distinction → strong triggers)
- Model tiering: opus (deep decisions/verdicts), sonnet (implementation), haiku (structured tasks)
- Output contract: filled template with concrete example
- Coined mental-model terms: 3-5 per agent
- Paired Bad→Good examples in methodology

## 9. Self-Exemption Prevention

Before finalizing any self-update to the prompt-engineer agent:
1. Count sections — must have all 5 core sections
2. Verify description follows 4-sentence format
3. Verify paired Bad→Good examples
4. Verify output contract has filled example
5. Verify no fabrication in any section

The meta-engineer's authority derives entirely from the visible quality of its own specification.

## 10. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Self-Exemption** | Enforcing standards on others while own prompt falls below | Apply same bar to self |
| **Dispatch Table Drift** | CLAUDE.md and dispatch-table.md diverge silently | Sync after every agent change |
| **New-Agent Inflation** | Approving overlapping scopes citing "specialization value" | Quantify proliferation cost |
| **Prompt Engineering Theater** | Structurally significant-looking changes with no behavioral target | Tie every change to specific input/output pair |
| **Fix-Without-Root-Cause** | Patching symptoms when failure is systemic | Use Drift Taxonomy to identify root cause class |
