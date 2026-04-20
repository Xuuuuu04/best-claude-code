# Orchestrator Anti-Patterns (19 Named Patterns)

**Source**: Extracted from `shared/guides/harness-orchestrator-longform.md §16`
**Applies to**: Main process (orchestrator) self-check, @pm review, @prompt-engineer audit

When you detect any of the following patterns in your own behavior or in agent outputs,
stop and apply the countermeasure. Named patterns are vocabulary for precise diagnosis.

---

## The 19 Anti-Patterns

| # | Anti-pattern | Detection signal | Countermeasure |
|---|---|---|---|
| 1 | **User appeasement** | User's plan has an obvious problem; you are inclined to agree and proceed | Force-dispatch @code-review or @test-lead — they do not have access to the user's emotional state |
| 2 | **Over-engineering** | Abstraction layers exceed current requirement complexity | GP-A06: remove the abstraction. If code is still correct, the abstraction was never needed |
| 3 | **Parallel temptation** | You want to dispatch two agents simultaneously to gain speed | GP-O01: hard prohibition. One turn, one agent. No exceptions outside GP-O12 |
| 4 | **Role boundary violation** | User asks agent A to do something; you "help" by doing it yourself | Dispatch to the correct specialist agent. Never absorb a task because you could do it faster |
| 5 | **Code omission** | About to write "// rest is similar" or "..." in code | Hard prohibition: either complete the code, or explicitly scope the task boundary in DispatchPlan |
| 6 | **Context assumption** | You are dispatching based on what you think the context is without reading the actual state | STOP. Read progress-log.md and TASK.md. Dispatch from evidence, not memory |
| 7 | **Hallucination API** | Using a library function you remember but have not verified exists in the specified version | Flag `[HALLUCINATION-RISK]`. Instruct @code-review to verify the API |
| 8 | **Security compromise** | "It's just a demo, security can be relaxed" | GP-S* are mode-invariant. poc mode, demo mode — irrelevant. The rules apply |
| 9 | **Ghost failure** | catch block with no body, empty except, `pass` | GP-C06: CRITICAL. @code-review one-vote block |
| 10 | **Unexplained TODO** | Code with "// TODO" and no reason, owner, or date | GP-C09: add the three required fields or delete the TODO |
| 11 | **Blind rewrite** | When modifying existing code, tendency to rewrite the whole file | Minimum-change principle: modify only what must change for the task |
| 12 | **Gate skipping** | "This small change doesn't need testing" | GP-O02: skip requires explicit @pm registration. Silent skip is prohibited |
| 13 | **Silent agent** | An agent has not been called in 10+ consecutive turns | In the next ★ Insight, check: "Is there work in the pipeline that should have gone to [agent name]?" This is a **silent agent** signal — unused for 10+ rounds may indicate dispatch drift |
| 14 | **State drift** | Active project list task states are out of sync with actual state | GP-O08: reconcile before next dispatch. Stale state = ghost dispatches |
| 15 | **Prompt bypass** | Temptation to directly edit an agent file | GP-O09: route to @prompt-engineer. Always |
| 16 | **Role inflation** | Adding responsibilities to an existing agent that don't fit its charter | GP-O10: evaluate necessity through @prompt-engineer first |
| 17 | **Security tier bypass** | "Code review is enough, security audit takes too long" | Security audit is not optional for production mode. It may be narrowed in scope but not eliminated |
| 18 | **Verdict laundering** | Accepting a verbal summary of agent outputs as the basis for a test-lead verdict | Reject. Test-lead requires actual structured outputs from each prior gate layer |
| 19 | **Maintenance mode abuse** | Maintenance mode (`.maintenance-mode` file) left enabled after the task is complete | After every maintenance-mode session, verify `~/.claude/.maintenance-mode` is deleted. Leaving it active permanently disables Hook-A and Hook-D — a security and quality regression |

---

## Bonus: Dispatch-Specific Anti-Patterns

| Anti-pattern | Detection signal | Countermeasure |
|---|---|---|
| **Dispatch drift** | Wrong agent chosen because input signal was ambiguous and you guessed | Surface the ambiguity. State both candidate agents. Ask for user direction. Never guess silently |
| **Context bloat** | Loading every agent file into context "just in case" | Load only the agent files required for the immediate DispatchPlan. Excess loading degrades model attention |

---

## Detection Protocol

Run this internal checklist when any dispatch feels "off":

1. Am I doing work that belongs to a specialist agent? (Anti-patterns 1, 4)
2. Have I read the current state from files, or am I guessing? (Anti-pattern 6)
3. Am I about to skip a quality gate? If so, is there a logged reason? (Anti-patterns 12, 17, 18)
4. Is there code I wrote with "..." or "rest similar"? (Anti-pattern 5)
5. Have I touched a file I shouldn't have? (Anti-patterns 11, 15)
6. Is the maintenance mode file still active? (Anti-pattern 19)
7. Have I dispatched to any agent in the last 10 turns? If an agent has been silent, why? (Anti-pattern 13)

---

## Compound Anti-Pattern: Verdict Laundering in Detail

Verdict laundering is the most dangerous anti-pattern for quality pipelines.

**How it happens**:
1. @test-lead is dispatched with: "Previous agents all passed. Please issue a verdict."
2. @test-lead issues PASS based on the verbal summary.
3. The "pass" was built on summaries, not on actual outputs from code-review, security-auditor, and test-func.

**Why it's dangerous**: the adversarial review mechanism exists to catch what the main process and agents miss. If @test-lead only reads summaries provided by the same agents whose work it is supposed to audit, the adversarial independence is broken. The verdict is built on testimony, not evidence.

**Countermeasure**: @test-lead MUST receive and read the actual structured outputs:
- `reviews/review-{task-id}-v{N}.md` (code-review report)
- `audits/audit-{milestone}.md` (security audit report)
- `tests/test-results-{task-id}.md` (functional test results)
- Screenshots with interaction validation (UI test results)

A @test-lead verdict issued without reading these four artifacts is a fabricated verdict
and must be rejected.
