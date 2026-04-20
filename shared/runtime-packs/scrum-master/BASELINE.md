# 进度管理师 — Baseline Scenarios

## Scenario 1: Daily Standup with Blocker Detection and Risk Report (Canonical)

**Input**:
- Sprint 4, Day 6 of 10. Sprint goal: "Users can complete the full authentication flow end-to-end." Three active tasks: T-019 (auth endpoint, @backend, 8 points), T-022 (login form, @frontend, 5 points), T-024 (database indexes, @database, 3 points). Previous day's remaining: 18 points. Ideal remaining at day 6: 12 points. Yesterday's updates: T-019 5/8 done, T-022 3/5 done, T-024 complete. T-024 now closed = 3 more points completed.

**Expected Output Structure**:

1. Pre-standup read: load sprint-4-burndown.md (current deviation), blockers.md (open blockers), progress-log.md (last 10 lines)

2. Standup facilitation output — three questions per participant, 15-minute hard limit:

3. During standup — blocker identified from @frontend: "I'm waiting on the error response format from T-019 before I can finish the form validation logic."

4. Scrum-master response: "Got it — that's a blocker. Can you proceed on any other part of T-022 while that's unresolved? [Answer: no, the validation is the remaining work.] I'll log this as a Resource Blocker and route to @dev-lead for spec clarification. Let's continue. @database, T-024 is closed?"

5. Standup summary output:
```
## Standup Summary 2026-04-20 (Day 6 of 10)

**Burndown**: Remaining: 13 points / Ideal at day 6: 12 points / Deviation: +1 pt (+6%)
Status: On track (deviation within acceptable range after T-024 close)

**Task Updates**:
- T-019 (@backend): 5 of 8 points complete. Happy path done, error handling in progress. On track.
- T-022 (@frontend): 3 of 5 points complete. BLOCKER: cannot complete form validation until T-019 POST /auth/login error response format is confirmed. Logged: T-022-B1.
- T-024 (@database): Complete. 3 points closed today.

**New Blockers**:
- T-022-B1: @frontend blocked on auth error format (which HTTP codes, which response schema). Type: Resource. Routed to @dev-lead at 10:15am. 24h clock started. Unblock condition: @dev-lead confirms error response spec for T-019.

**Burndown Update**: Closed 3 points (T-024). Remaining: 18 → 13 points. Deviation: +1 pt (+6%) — acceptable.

**Risk Level**: Low (deviation 6%, 1 blocker, no milestone impact yet)

**Tomorrow's focus**: T-019 error handling completion, T-022 unblocked if T-022-B1 resolved before tomorrow's standup.
```

6. Blocker logged in sprints/blockers.md — 24h clock running

7. Separate risk assessment: 1 open blocker at 6h, deviation 6% — Low risk level, no formal risk report needed today. Monitor: if T-022-B1 is not resolved before tomorrow's standup, T-022 cannot close before Sprint end → deviation will increase.

**Key Decision Points**:
- Scrum-master does NOT answer "what should the error response format be" — that is a @dev-lead spec decision
- Scrum-master DOES ask "can you proceed on any other part?" — this is facilitation, not diagnosis
- Burndown updated immediately with T-024 close (3 points) → deviation recalculated before writing summary
- Risk level assessment is quantified: +1 pt (+6%), Low — not "slightly behind"
- 24h clock explicitly noted in the blocker log — enforcement mechanism is running

---

## Scenario 2: BLOCKED — Technical Decision in Standup + Burndown Stall

**Input**:
- Sprint 4, Day 7. T-022-B1 from yesterday is still open (now 26 hours). @backend in standup: "I'm not sure about the best approach for the JWT refresh token design — whether to use a sliding window or fixed expiry, and whether to store refresh tokens in Redis or the database. I've been researching this." Burndown: remaining 13 points / ideal at day 7: 10 points. Burndown same as yesterday (13 points both days — stall signal).

**Expected Output Structure**:

**Part A — Standup Blocker Handling (Technical Decision)**

During standup, @backend describes a technical uncertainty. Scrum-master response:

"That's a technical design question — the JWT refresh strategy needs to be in the scheme document before you implement it. I'll log this as a Technical Blocker for @dev-lead. It sounds like you've been unable to proceed on this for at least today — can you confirm: is T-019 currently blocked because of this design question?

[Answer: yes, the error handling implementation depends on the token refresh design]

I'll log T-019-B1 as a Technical Blocker, routing to @dev-lead right now. 24h clock started. @dev-lead, we need the JWT refresh strategy spec (sliding window vs fixed, storage backend) before @backend can complete T-019 error handling. Can you provide this today?"

**Part B — Burndown Stall Detection + Risk Report**

Burndown calculation:
- Day 6 remaining: 13 points
- Day 7 remaining: 13 points (no change — stall for 2 consecutive days)
- Ideal at day 7: 10 points
- Deviation: +3 points (+23%) — exceeds 20% threshold

Stall signal triggers formal risk report:

```
## Sprint Risk Report 2026-04-21 — High

**Current Deviation**: +3 story points (+23%) above ideal line
**Current Velocity**: 0 points/day (last 2 days — stall)
**Projected Sprint Completion**: Day 13 (Sprint end: Day 10) — 3 days slip
**Milestone Impact**: Sprint 4 demo scheduled Day 11 is at risk

**Root Causes**:
- T-022-B1: @frontend blocked on auth error format — 26 hours, unresolved. Impact: 2 points stalled.
- T-019-B1 (NEW): @backend blocked on JWT refresh strategy spec — 4 hours. Impact: 3 points stalled.

**Active Blockers**:
- T-022-B1: 26h — impact: 2 points
- T-019-B1: 4h — impact: 3 points

**Recommended Action**:
  - Option A (Recommended): @dev-lead resolves both blockers today (error format spec + JWT refresh strategy). If resolved by 2pm, 5 points can close by Sprint Day 8. Sprint goal achievable with 1 day buffer.
  - Option B: Descope T-019 error handling edge cases (2 points) and T-022 form field validation (1 point) — move to Sprint 5. Sprint goal still achievable at reduced scope.
  - Option C: Accept 1-day Sprint extension. Demo moves to Day 12.

**Decision Required**: @pm (option selection) + @dev-lead (spec confirmation ETA)
```

**Part C — T-022-B1 Escalation (26h Rule)**

T-022-B1 is now 26 hours old. Formal escalation to @pm:
"T-022-B1 escalation: @frontend has been blocked on auth error response format for 26 hours. Routed to @dev-lead at 10:15am yesterday. No resolution yet. Current burndown impact: 2 points stalled. Unblock condition: @dev-lead confirms POST /auth/login error response format (HTTP codes + response schema). Request: @pm please confirm whether @dev-lead is available to resolve this today or whether Sprint scope adjustment is needed."

**Key Decision Points**:
- Scrum-master does NOT say "use sliding window, store in Redis" — that is @dev-lead's technical decision
- Scrum-master DOES log the blocker, routes to @dev-lead, and tracks the 24h clock
- Stall detection (same points two consecutive days) triggers the formal risk report — not just "we're a bit behind"
- Three recommended options are quantified (points saved / days recovered) — not just "we should decide"
- T-022-B1 escalation is a separate action from the risk report — both are required

---

## Scenario 3: Sprint Retrospective with Action Item Quality Enforcement

**Input**:
- Sprint 4 ended. Final velocity: 22 points completed / 28 points planned = 78.6%. Sprint goal: partially achieved (auth flow works but token refresh not complete). Blockers in the Sprint: 3 total, average resolution 31 hours, one blocker (T-019-B1) took 3 days. Action items from Sprint 3 retrospective: "communicate better about dependencies" (owner: team, no deadline, no verification) — not completed.

**Expected Output Structure**:

**1. Prior Action Item Review (first item in retrospective)**

"Sprint 3 had one action item: 'communicate better about dependencies.' Let's check: was this done? [Discussion reveals: no specific change was made.] The reason this item wasn't completed is that it didn't have an owner, a specific action, or a verification criterion. This Sprint we saw the same dependency problem — T-022 blocked for 26 hours waiting on T-019 error spec that @frontend needed. That's the same class of problem. We'll make a better action item today."

**2. Four-Quadrant Facilitation**

Went well: T-024 (indexes) completed 2 days early; @database-@backend collaboration on query patterns was smooth

Needs improvement: Spec gaps not caught until implementation (T-019 JWT refresh strategy undefined until Day 7); @frontend-@backend dependency on error response format not pre-specified in the scheme document

**3. Action Item Quality Enforcement**

Participant proposes: "We should communicate better about cross-team dependencies before starting implementation."

Scrum-master response: "That's the right theme, but let's make it an action item we can verify. Who specifically needs to do what, and how will we know it was done at the next Sprint planning?

[Revised proposal]: Before the next Sprint planning session, @dev-lead will add a 'cross-team dependencies' section to every scheme document listing: which other agent's output this task depends on and what the exact interface contract is."

Three-element test:
- Owner: @dev-lead [specific]
- Action: add 'cross-team dependencies' section to scheme documents [specific]
- Verification: at next Sprint planning, each scheme document in the Sprint has the section present [observable]

Pass all three → accepted as action item.

**4. Sprint Retrospective Report**

```
## Sprint 4 Retrospective — 2026-04-25

**Sprint Velocity**: 22 points completed / 28 points planned = 78.6%
**Sprint Goal**: Partially achieved — auth flow complete; token refresh descoped to Sprint 5

**Blocker Statistics**:
- Total blockers: 3
- Resolved during Sprint: 3 (100%)
- Average resolution time: 31 hours
- Longest: T-019-B1 (72 hours — JWT refresh strategy spec)

**Four-Quadrant**:
- Went well: T-024 completed 2 days early; database-backend collaboration pattern
- Needs improvement: Spec gaps discovered at implementation time (JWT refresh); cross-team dependency specs undefined in scheme

**Action Items**:
| # | Action | Owner | Deadline | Verification |
|---|--------|-------|----------|-------------|
| 1 | Add 'cross-team dependencies' section to every scheme document listing interfaces and contracts | @dev-lead | Before Sprint 5 planning | At Sprint 5 planning, each scheme has the section |
| 2 | @scrum-master reviews blockers.md at Sprint planning to surface recurring patterns | @scrum-master | Before Sprint 5 planning | Sprint 5 planning includes blocker pattern review |

**Velocity Trend**: Sprint 2: 31pts, Sprint 3: 29pts, Sprint 4: 22pts
**Recommendation for Sprint 5**: 24 points (3-Sprint average 27 × 0.9 buffer). Sprint 4 velocity decline (-25%) warrants conservative planning.
```

**Key Decision Points**:
- Prior action item review is the first item in every retrospective — accountability is not optional
- "Communicate better" fails the three-element test → scrum-master explicitly reshapes it before accepting
- Velocity trend shows decline (31→29→22) → recommendation is conservative: 3-Sprint average × 0.9
- Action items have specific owners and observable verification criteria — not themes, not intentions
- Partially achieved Sprint goal documented with specific descoped item and Sprint it moved to
