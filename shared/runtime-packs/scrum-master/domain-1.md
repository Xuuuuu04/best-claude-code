# 进度管理师 — Domain 1: Sprint Lifecycle

## 1.1 Sprint Planning

### Capacity Calculation

```
Capacity = Available working days × 0.70 × Team size
Planned load = Capacity × 0.80

Example:
- Sprint duration: 10 days
- Team: 3 agents
- Working days per agent: 8 days (accounting for meetings, PTO)
- Capacity: 8 × 0.70 × 3 = 16.8 agent-days
- Planned load: 16.8 × 0.80 = 13.4 agent-days
- Story points planned: ≤ 13 points (round down)
```

**Why 70%?** 30% overhead accounts for: unexpected blockers, code review cycles, test feedback, standup time, and context switching.

**Why 80% of capacity?** The 20% buffer absorbs: scope discovery, complexity underestimation, and emergent blockers. Planning to 100% guarantees a miss.

### Story Point Estimation

**Planning Poker**:
1. Each agent independently estimates without discussion
2. Estimates are revealed simultaneously
3. Divergence is discussed (highest and lowest explain their reasoning)
4. Re-estimate until convergence

**T-shirt Sizing** (quick relative sizing):
- S = 1-2 points (≤ 4 hours)
- M = 3-5 points (1-2 days)
- L = 8-13 points (3-5 days)
- XL = 21+ points (must decompose)

**Reference Story Anchoring**:
- Pick a well-understood completed story as baseline (e.g., "add email field to User model" = 2 points)
- Estimate new stories relative to the baseline

### Sprint Goal Design

A Sprint goal is a single, testable, outcome-focused statement:

```
GOOD: "Users can complete the full invitation flow from send to accept"
- Testable: can a user actually do this end-to-end?
- Outcome-focused: describes user capability, not task list

BAD: "Complete Tasks T-019 through T-024"
- This is a task list, not a goal
- A Sprint goal can be achieved even if some tasks are descoped
```

### Sprint Planning Document

```
## Sprint N Plan — [YYYY-MM-DD] to [YYYY-MM-DD]

**Goal**: [single measurable outcome]
**Duration**: [N] days
**Capacity**: [N] agent-days (available [N] × 0.70)
**Planned load**: [N] story points (capacity × 0.80)

**Task List**:
| Task ID | Description | Owner | Points | Dependencies |
|---------|-------------|-------|--------|--------------|
| T-019 | Auth endpoint | @backend | 8 | T-021 (migration) |
| T-022 | Login form | @frontend | 5 | T-019 (API contract) |
| T-024 | DB indexes | @database | 3 | None |

**Known Risks**:
- T-019 may require scheme revision if JWT strategy undefined
- T-022 blocked until T-019 error format confirmed

**Ideal burndown**: [N] points / [N] days = [N] points/day
```

## 1.2 Standup Facilitation

### Three-Question Model

1. **"What did you complete since the last standup?"**
   - Focus: delivered value, not activity
   - BAD: "I worked on the auth endpoint"
   - GOOD: "I completed the happy path for POST /auth/login, 3 of 8 points"

2. **"What will you work on today?"**
   - Focus: daily commitment
   - BAD: "Continue working on auth"
   - GOOD: "Implement error handling for invalid credentials and token expiry"

3. **"What is blocking you or creating risk?"**
   - Focus: friction identification
   - BAD: "Nothing"
   - GOOD: "I'm waiting on the error response format from T-019 before I can finish form validation"

### Thermal Limit Enforcement

**Recognition**: A participant has been speaking for >2 minutes on a single blocker without resolution. Problem-solving has begun.

**Intervention**:
```
"This is clearly important and needs more focus than we have in the standup.
[@dev-lead, @backend]: can you stay online after this standup for 15 minutes?
I'll flag it as a blocker and we'll track it. Let's move on."
```

**Three functions**:
1. Validates importance (not dismissive)
2. Creates specific follow-up (15-minute focused session)
3. Preserves standup constraint (move on)

### Blocker Identification Signals

| Signal | Question to Ask | Likely Blocker Type |
|--------|----------------|---------------------|
| "I'm waiting for..." | "Can you proceed without X today?" | Resource |
| "I'm not sure how to..." | "Is this a design question or implementation question?" | Technical |
| "It's taking longer than expected because..." | "Is the scope larger than estimated?" | Scope/Complexity |
| "The tests are failing and I don't know why..." | "Is this a code issue or environment issue?" | Technical |
| "I need a decision on..." | "Who can make this decision?" | Decision |

## 1.3 Retrospective Facilitation

### Four-Quadrant Format

```
## Sprint N Retrospective — [YYYY-MM-DD]

**Went well**: [specific events, patterns, collaborations]
**Needs improvement**: [specific problems, friction points, delays]
**Action items**: [specific, owned, verifiable commitments]
**Acknowledgments**: [specific contributions recognized]
```

### Action Item Quality Criteria (Three-Element Test)

Every action item must pass all three:

1. **Specific owner**: Not "the team" — a named agent or role
2. **Specific action**: Not "communicate better" — a concrete behavior change
3. **Verification criterion**: Observable outcome that can be checked

```
BAD: "Communicate better about dependencies"
- Owner: team (not specific)
- Action: communicate better (not specific)
- Verification: none

GOOD: "@dev-lead adds 'cross-team dependencies' section to every scheme document"
- Owner: @dev-lead (specific) ✓
- Action: add section to scheme documents (specific) ✓
- Verification: at next Sprint planning, each scheme has the section (observable) ✓
```

### Prior Action Item Accountability

Every retrospective begins with checking prior commitments:

```
"Sprint 3 had one action item: 'add dependency sections to schemes.'
Let's check: was this done?
[Discussion reveals: 3 of 5 schemes have the section; 2 do not.]
The reason: @dev-lead was not aware it applied to T-022 and T-023.
Lesson: action items need explicit task ID list.
```

**Rule**: Teams that commit and do not follow up learn that retrospective commitments are theater. Prior action item review is not optional.
