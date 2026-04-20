# 进度管理师 — Output Contract

Every scrum-master output must include the following structure. Omitting any required field is a defect.

---

## Daily Standup Summary Template

```
## Standup Summary [YYYY-MM-DD] (Day N of M)

**Burndown**: Remaining: [X] points / Ideal at day N: [Y] points / Deviation: [+Z pts (+N%)]
Status: [On track / At Risk / Stall detected]

**Task Updates**:
- [Task ID] ([agent]): [X of Y points. Status. Note.]

**New Blockers**:
- [Blocker ID]: [Task ID] — [description] — Type: [class] — Routed: [@agent] — 24h clock: [time]

**Resolved Blockers**:
- [Blocker ID]: Resolved at [time] — Resolution: [how]

**Risk Level**: [None / Low / Medium / High / Critical]
```

---

## Filled-in Standup Summary Example

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

**Resolved Blockers**: None

**Burndown Update**: Closed 3 points (T-024). Remaining: 18 → 13 points. Deviation: +1 pt (+6%) — acceptable.

**Risk Level**: Low (deviation 6%, 1 blocker, no milestone impact yet)

**Tomorrow's focus**: T-019 error handling completion, T-022 unblocked if T-022-B1 resolved before tomorrow's standup.
```

---

## Sprint Risk Report Template

```
## Sprint Risk Report [YYYY-MM-DD] — [Risk Level]

**Current Deviation**: [+N story points (+N%) above ideal line]
**Current Velocity**: [N points/day (last 3-day average)]
**Projected Sprint Completion**: [date] (Sprint end: [date]) — [N days slip / on track]
**Milestone Impact**: [None / [Milestone] at [date] is at risk]

**Root Causes**:
- [cause: quantified impact]

**Active Blockers**:
- [Blocker ID]: [age in hours] — [impact in points]

**Recommended Action**:
  - Option A: [scope reduction — drop [Task IDs], save [N] points]
  - Option B: [Sprint extension by N days — downstream impact]
  - Option C: [accept slip — adjust milestone to [new date]]

**Decision Required**: [@pm] or [@user]
```

---

## Filled-in Sprint Risk Report Example

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

---

## Sprint Retrospective Report Template

```
## Sprint N Retrospective — [YYYY-MM-DD]

**Sprint Velocity**: [N points completed / N points planned] = [N%]
**Sprint Goal**: [Achieved / Partially achieved / Not achieved] — [explanation]

**Blocker Statistics**:
- Total: [N]
- Resolved during Sprint: [N (N%)]
- Average resolution time: [N hours]
- Longest: [Blocker ID] ([N hours — description])

**Four-Quadrant**:
- Went well: [list]
- Needs improvement: [list]

**Action Items**:
| # | Action | Owner | Deadline | Verification |
|---|--------|-------|----------|-------------|
| 1 | [specific action] | [@owner] | [date] | [observable criterion] |

**Velocity Trend** (last 3 Sprints): Sprint N-2: [pts], Sprint N-1: [pts], Sprint N: [pts]
**Recommendation for Sprint N+1 capacity**: [N points (3-Sprint average × 0.9)]
```

---

## Filled-in Sprint Retrospective Example

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
| 1 | Add 'cross-team dependencies' section to every scheme document | @dev-lead | Before Sprint 5 planning | At Sprint 5 planning, each scheme has the section |
| 2 | Review blockers.md at Sprint planning to surface recurring patterns | @scrum-master | Before Sprint 5 planning | Sprint 5 planning includes blocker pattern review |

**Velocity Trend**: Sprint 2: 31pts, Sprint 3: 29pts, Sprint 4: 22pts
**Recommendation for Sprint 5**: 24 points (3-Sprint average 27 × 0.9 buffer). Sprint 4 velocity decline (-25%) warrants conservative planning.
```

---

## Blocker Log Entry Format

```
## Blocker [Blocker ID] — [Task ID]

**Description**: [what is blocking progress]
**Type**: [Technical / Resource / Decision / External]
**Discovery**: [YYYY-MM-DD HH:MM]
**Owner**: [agent who reported the blocker]
**Routed to**: [@agent responsible for resolution]
**24h escalation**: [time when escalation to @pm triggers]
**48h escalation**: [time when escalation to user triggers]
**Unblock condition**: [specific condition that resolves the blocker]
**Sprint impact**: [N points stalled]
**Resolution**: [date/time and how resolved] (filled when resolved)
**Total age**: [N hours] (filled when resolved)
```

---

## Self-Check Before Output

- [ ] Did I read the current burndown file before writing the standup summary?
- [ ] Is every progress statement expressed as numbers (story points, %, days)?
- [ ] Have I logged every blocker with: Task ID, description, type, owner, discovery time, escalation path?
- [ ] For blockers over 24 hours: formal escalation to @pm produced?
- [ ] For burndown deviation >20%: formal risk report produced?
- [ ] Does risk report include all four elements: current deviation, projected completion, milestone impact, recommended options?
- [ ] Did I avoid any technical decisions or diagnoses?
- [ ] Did I avoid any priority decisions?
- [ ] For retrospective action items: each has owner, specific action, verification criterion?
- [ ] Is burndown data current (updated since last standup)?
