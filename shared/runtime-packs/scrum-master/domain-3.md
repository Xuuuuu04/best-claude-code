# 进度管理师 — Domain 3: Progress Visualization

## 3.1 Burndown Analysis

### Ideal vs. Actual Interpretation

The ideal burndown line decreases linearly from total Sprint points on day 0 to zero on day N.

```
Sprint: 10 days, 30 points total

Day 0: 30 points (start)
Day 1: 27 points (ideal)
Day 2: 24 points (ideal)
...
Day 10: 0 points (ideal)
```

**Early deviation (Days 1-3)**:
- May self-correct as team finds rhythm
- Monitor but do not panic
- Action: check for hidden blockers

**Late deviation (Days 7+)**:
- Danger zone — limited time to recover
- Action: formal risk report, scope reduction discussion

**Stall signal**: Actual line flat for 2 consecutive days
- Highest urgency signal
- Investigate cause before next standup
- Action: emergency risk report

### Burndown Update Procedure

```
1. Read current burndown file
2. Calculate completed points since last update
3. Subtract from remaining
4. Calculate deviation: actual remaining - ideal remaining
5. Calculate deviation %: deviation / total points × 100%
6. Append to burndown file
7. Check risk triggers
```

### Burndown File Format

```
## Sprint N Burndown

**Total points**: 30
**Sprint days**: 10
**Ideal burn rate**: 3 points/day

| Day | Date | Ideal Remaining | Actual Remaining | Completed | Deviation | Deviation % |
|-----|------|-----------------|------------------|-----------|-----------|-------------|
| 0 | 04-15 | 30 | 30 | 0 | 0 | 0% |
| 1 | 04-16 | 27 | 28 | 2 | +1 | +3% |
| 2 | 04-17 | 24 | 25 | 3 | +1 | +3% |
| 3 | 04-18 | 21 | 22 | 3 | +1 | +3% |
| 4 | 04-19 | 18 | 20 | 2 | +2 | +7% |
| 5 | 04-20 | 15 | 18 | 2 | +3 | +10% |
| 6 | 04-21 | 12 | 13 | 5 | +1 | +3% |
```

## 3.2 Risk Quantification

### Risk Measurement Formula

```
(A) Current deviation in points = actual remaining - ideal remaining
(B) Deviation as % = (A / total Sprint points) × 100%
(C) Projected completion = today + (remaining points / last 3-day average velocity)
(D) Milestone impact = any milestone between today and projected completion
```

### Risk Levels

| Level | Deviation | Blockers | Stall | Milestone Impact | Action |
|-------|-----------|----------|-------|------------------|--------|
| **None** | 0% | 0 | No | None | Monitor only |
| **Low** | <10% | 0-1 | No | None | Note in standup |
| **Medium** | 10-20% | 1-2 | No | None | Report in standup, watch closely |
| **High** | >20% | 3+ | 2 days | None | Formal risk report to @pm |
| **Critical** | Any | Any | 3+ days | Yes | Escalate to user immediately |

### Velocity Compass

Sprint-to-Sprint velocity trend analysis:

```
Velocity ratio = Sprint N velocity / Sprint N-1 velocity

> 1.10: Improving — team is finding efficiencies
0.85 - 1.10: Stable — normal variation
< 0.85: Declining — investigate causes
< 0.70 for 2 consecutive Sprints: Systemic capacity problem

Action for < 0.70:
- Present re-calibration recommendation to @pm
- Recommend conservative Sprint planning (reduce capacity by 15-20%)
- Investigate root causes: scope creep? technical debt? external dependencies?
```

### Risk Report Trigger Conditions

Any ONE of the following triggers a formal risk report:

1. **Burndown deviation > 20%** from ideal line
2. **Burndown flat for 2 consecutive days** (stall signal)
3. **3 or more simultaneous open blockers**
4. **Velocity < 75%** of previous Sprint's velocity at the same Sprint day
5. **Critical-path task delayed** with downstream dependencies

### Risk Report Required Elements

Every risk report must include ALL four elements:

1. **Current deviation**: points + percentage
2. **Projected completion date**: when the Sprint will actually finish
3. **Milestone impact**: which milestones are at risk
4. **Recommended options**: at least 2 quantified options (scope reduction, extension, accept slip)

```
# BAD risk report
"We're a bit behind and might not finish on time."

# GOOD risk report
"Current deviation: +6 points (+20%).
Projected completion: Day 12 (2 days past Sprint end).
Milestone impact: Demo scheduled Day 11 is at risk.
Options:
A. Descope T-019 edge cases (save 2 points) — Sprint goal achievable
B. Extend Sprint by 2 days — demo moves to Day 13
C. Accept slip — demo cancelled, release pushed to Sprint 5"
```

## 3.3 Sprint Metrics Dashboard

### Key Metrics to Track

| Metric | Calculation | Frequency | Target |
|--------|-------------|-----------|--------|
| Sprint velocity | Points completed / Points planned | Per Sprint | ≥ 80% |
| Blocker resolution time | Average hours from discovery to resolution | Per Sprint | < 24h |
| Blocker count | Total blockers in Sprint | Per Sprint | Decreasing trend |
| Burndown deviation | Max deviation % during Sprint | Per Sprint | < 20% |
| Scope change | Points added / removed after Sprint start | Per Sprint | < 10% |
| Action item completion | Action items completed / Action items committed | Per Sprint | ≥ 80% |

### Velocity Trend Analysis

```
## Velocity Trend (last 6 Sprints)

Sprint 1: 25 pts / 30 planned = 83%
Sprint 2: 31 pts / 35 planned = 89%
Sprint 3: 29 pts / 32 planned = 91%
Sprint 4: 22 pts / 28 planned = 79% ⚠️
Sprint 5: 26 pts / 30 planned = 87%
Sprint 6: 20 pts / 28 planned = 71% 🔴

Trend: Declining since Sprint 3
Recommendation: Reduce Sprint 7 capacity to 24 points (6-Sprint average 25.5 × 0.95)
Investigate: Sprint 4 and 6 had 3+ blockers each. Root cause: scheme gaps discovered late.
```
