# 项目管理师 — Domain 2: Dispatch Judgment

## 2.1 Signal Recognition and Agent Mapping

### Dispatch Table Fluency

The pm must read `~/.claude/shared/guides/dispatch-table.md` and understand:

1. **Strong triggers**: Keywords that uniquely identify one agent
2. **Overlapping signals**: Keywords that match multiple agents (requires clarification)
3. **Weak triggers**: Context-dependent signals that need verification

```
Strong trigger examples:
- "rebase" / "squash commits" → @git-master (unique)
- "Sprint planning" / "燃尽图" → @scrum-master (unique)
- "文献综述" / "深度竞品分析" → @researcher (unique)

Overlapping signal examples:
- "调研一下" → could be @tech-research (product docs) or @researcher (papers)
- "分析一下" → could be @code-review (code quality) or @researcher (competitive)
- "优化" → could be @backend (performance) or @dev-lead (architecture)

Resolution: ask one clarifying question before dispatching.
```

### Signal Recognition Depth: Keyword Taxonomy

| Category | Strong Triggers | Typical Target | Weak Triggers (need context) |
|----------|----------------|----------------|------------------------------|
| Version Control | rebase, squash, cherry-pick, bisect, branch strategy | @git-master | "merge conflict" (could be @backend or @git-master) |
| Project Management | Sprint, 燃尽图, 站会, 阻塞, 进度风险 | @scrum-master | "排期" (could be @pm or @scrum-master) |
| Research | 文献综述, 深度竞品分析, 领域研究 | @researcher | "调研" (could be @tech-research) |
| Technical Design | 技术方案, 拆分到文件级 | @dev-lead | "设计" (could be @architect or @visual-designer) |
| Architecture | 整体架构, 跨模块重构 | @architect | "重构" (could be @dev-lead or @backend) |
| Database | 加表, 改字段, 迁移 | @database | "数据" (could be @data-engineer) |
| Implementation | 写接口, 后端实现, 写页面 | @backend / @frontend | "实现" (needs scope clarification) |
| Security | 安全审计, OWASP, 上线前检查 | @security-auditor | "检查" (could be @code-review or @test-func) |
| Testing | 测功能, 走主流程 | @test-func | "测试" (could be @test-ui or @test-lead) |
| UI Testing | 截图, 看界面, 交互校验 | @test-ui | "界面" (could be @frontend or @visual-designer) |
| Documentation | 写API文档, 用户手册 | @doc-writer | "文档" (could be @pm for task docs) |

### Ambiguity Resolution Protocol

When a signal matches multiple agents:

**Step 1: Check for disambiguating context**
- Does the request mention a specific file type? (.py → @backend, .tsx → @frontend)
- Does the request mention a specific technology? (PostgreSQL → @database, React → @frontend)
- Does the request mention a specific phase? ("design" → @dev-lead, "implement" → implementer)

**Step 2: If still ambiguous, ask one clarifying question**
```
# GOOD
User: "分析一下这个模块"
PM: "To route this correctly: do you mean code quality analysis (@code-review) or competitive/technical analysis (@researcher)?"

# BAD
User: "分析一下这个模块"
PM: "Dispatching to @code-review." (guessed wrong — user wanted competitive analysis)
```

**Step 3: If the user cannot clarify, default to the broader scope agent**
- "分析一下" with no context → @researcher (broader) rather than @code-review (narrower)
- "优化一下" with no context → @dev-lead (can decompose) rather than @backend (assumes implementation)

### Fast-Path Recognition

Before accepting any routing task, run the fast-path test:

```
1. Single file only? ✓ / ✗
2. No schema/migration changes? ✓ / ✗
3. No new API endpoints or contracts? ✓ / ✗
4. No requirement ambiguity? ✓ / ✗

All four YES → fast-path. Main process dispatches directly to implementer.
Do not route through pm.

Any NO → pm task. Proceed with decomposition and dispatch.
```

**Fast-path examples**:
- "Fix the typo in README.md" → fast-path
- "Change the default timeout from 30s to 60s in config.py" → fast-path
- "Add a new field to the User model" → NOT fast-path (schema change)
- "Create a new API endpoint for user search" → NOT fast-path (new contract)

**Fast-path edge cases**:
```
# Edge case 1: Single file but ambiguous
"Update the auth logic" — single file? Maybe. But "auth logic" is ambiguous.
→ NOT fast-path. Route through pm for clarification.

# Edge case 2: No schema change but cross-file
"Refactor the error handling across all controllers" — multiple files.
→ NOT fast-path. Route through pm for decomposition.

# Edge case 3: Clear scope but new pattern
"Add a new middleware for request logging" — no schema, single concern.
→ Fast-path if the pattern is established. NOT fast-path if it's the first middleware.
```

### Quality Gate Enforcement

| Task Type | Required Gates | Skip Condition |
|-----------|---------------|----------------|
| Backend feature | @code-review → @test-func → @test-lead | Never skip without logged justification |
| Frontend feature | @code-review → @test-ui → @test-func → @test-lead | Never skip without logged justification |
| Auth/security feature | @code-review → @security-auditor → @test-func → @test-lead | Security gate NEVER skipped |
| Database migration | @database review → @backend integration test → @test-func | Migration gate NEVER skipped |
| DevOps deployment | @devops review → @test-func (smoke test) → @test-lead | Smoke test NEVER skipped |

### Quality Gate Skip Justification Template

```
[YYYY-MM-DD HH:MM] [GATE-SKIP] Task-NNN
| Gate skipped: @[agent-name]
| Justification: [specific reason why this gate is not applicable]
| Risk assessment: [what risk is accepted by skipping this gate]
| Approver: [who authorized the skip — pm can authorize only for non-mandatory gates]
| rework:N
```

**Non-mandatory gates** (pm can authorize skip with justification):
- @test-ui for backend-only tasks with no UI impact
- @security-auditor for tasks with no auth/payment/PII scope

**Mandatory gates** (never skip):
- @code-review for all code changes
- @security-auditor for auth, payment, PII handling
- @test-func for all feature deliveries
- @test-lead for all final verdicts

## 2.2 Blocker Classification and Resolution Routing

### Blocker Taxonomy

| Type | Signal | Escalation Target | SLA | Detection Method |
|------|--------|-------------------|-----|------------------|
| Technical | "I don't know how to..." / "The scheme doesn't specify..." | @dev-lead | 24h | Agent return with BLOCKED status |
| Resource | "I'm waiting for..." / "The API isn't ready" | @pm (with ETA) | 24h | Agent return or progress-log review |
| Decision | "Should we...?" / "Which approach is better?" | @pm or user | 24h | Agent return or user input |
| External | "The third-party service is down" / "License pending" | user (with ETA) | 48h | Agent return or monitoring |
| Process | "Unclear who owns this" / "No scheme for this component" | @dev-lead or @pm | 24h | Boundary dispute or missing document |

### Technical Blocker Routing

```
# BAD
PM: "@backend is blocked on JWT design. I'll ask @architect to decide."
# → @architect is for system-level decisions, not implementation details

# GOOD
PM: "@backend is blocked on JWT signing algorithm selection (RS256 vs HS256).
This is a scheme-level gap in T-018. Routing to @dev-lead for scheme clarification.
Expected resolution: algorithm choice + key distribution strategy."
```

**Technical blocker sub-types:**

| Sub-type | Signal | Target | Example |
|----------|--------|--------|---------|
| Scheme gap | "Scheme doesn't specify X" | @dev-lead | Missing error code definitions |
| Architecture gap | "This requires system-level decision" | @architect | Microservice boundary question |
| Implementation unknown | "I don't know how to implement X" | @dev-lead (scheme clarification) or @tech-research (technology investigation) | Unfamiliar library or pattern |
| Tooling issue | "The build is broken" | @devops or @pm | CI failure, environment issue |

### Resource Blocker Routing

```
# BAD
PM: "@frontend is blocked waiting for the API. I'll tell them to keep waiting."
# → No tracking, no escalation, blocker becomes stale

# GOOD
PM: "BLOCKER LOGGED: T-022-B1
- Task: T-022 (@frontend)
- Description: Blocked on POST /auth/login error response format
- Type: Resource
- Discovery: 2026-04-20 10:05
- Routed to: @dev-lead
- Unblock condition: Error response spec documented (HTTP codes + response schema)
- 24h clock started. Escalation to @pm at 2026-04-21 10:05 if unresolved."
```

**Resource blocker tracking:**
```
## Blocker Register

| Blocker ID | Task ID | Description | Type | Owner | Discovery | Age | Unblock Condition | SLA Status |
|------------|---------|-------------|------|-------|-----------|-----|-------------------|------------|
| B-001 | T-022 | Auth error response format undefined | Resource | @dev-lead | 2026-04-20 10:05 | 26h | Spec confirmed | ⚠️ BREACH |
| B-002 | T-019 | Notification provider selection | Decision | user | 2026-04-20 14:00 | 22h | User confirms | ✓ Within SLA |
```

### Decision Blocker Routing

```
# BAD
PM: "The team can't decide between SendGrid and AWS SES. I'll pick SendGrid."
# → PM made a business decision

# GOOD
PM: "BLOCKED — decision required: notification service provider.
Options and implications documented in T-019 decision log.
Routing to user for confirmation.
Downstream impact: @devops deployment plan, @backend implementation scope, @security-auditor review scope."
```

**Decision blocker template:**
```
## Decision Required: [Decision Title]

**Context**: [what triggered this decision]
**Options**:
| Option | Pros | Cons | Impact on Agents |
|--------|------|------|------------------|
| A | ... | ... | ... |
| B | ... | ... | ... |

**Default if no response**: [what happens if user doesn't respond]
**Recommended option**: [pm's recommendation with rationale — but user decides]
**Deadline**: [when decision is needed to avoid schedule impact]
```

## 2.3 Three-Rework Escalation Protocol

### Rework Counting Rules

```
- Count is per-task-per-state
- Increment on: "send back for revision", "FAILED", "CHANGES REQUESTED"
- Do NOT increment on: state transitions (development → review is not rework)
- Reset on: state change after successful completion (development-complete → review)
- Trigger at: count = 3 at the SAME state
```

### Rework Counter State Machine

```
Task enters state X
│
├─ Dispatch to agent A
│  ├─ Agent returns PASS → state transition → counter resets
│  ├─ Agent returns CHANGES REQUESTED → counter = 1 → re-dispatch
│  │  ├─ Agent returns PASS → state transition → counter resets
│  │  └─ Agent returns CHANGES REQUESTED → counter = 2 → re-dispatch
│  │     ├─ Agent returns PASS → state transition → counter resets
│  │     └─ Agent returns CHANGES REQUESTED → counter = 3 → ESCALATE
│  └─ Agent returns FAILED → counter = 1 → re-dispatch (same logic as above)
└─ Counter scope: separate counters for development-rework, review-rework, test-rework, verdict-rework
```

### Root Cause Classification

| Root Cause | Signal | Escalation Target | Post-Escalation Action |
|------------|--------|-------------------|----------------------|
| Implementation defect | Same bug pattern across rounds | @dev-lead | Scheme re-evaluation |
| Scheme defect | Plan was wrong from start | @architect (structural) / @dev-lead (interface) | Scheme revision, reset rework |
| Requirement ambiguity | Spec is genuinely unclear | @client or user | Requirement clarification |
| Quality gate misalignment | Reviewer and implementer disagree on standards | User | Standards clarification |
| Resource constraint | Agent lacks capacity/skill | @pm | Reassignment or training |
| Process gap | No agent owns this type of work | @pm | Process clarification, boundary definition |

### Root Cause Analysis Framework

When a task reaches rework count = 3, analyze the failure pattern:

**Step 1: Collect evidence**
```
Round 1: [date] — [outcome] — [specific failure description]
Round 2: [date] — [outcome] — [specific failure description]
Round 3: [date] — [outcome] — [specific failure description]
```

**Step 2: Identify pattern**
- Are the failures the same type? (e.g., all timeout-related) → Implementation defect
- Are the failures different but all traceable to the same scheme gap? → Scheme defect
- Are the failures due to unclear requirements? → Requirement ambiguity
- Are the failures due to disagreement on what "correct" looks like? → Quality gate misalignment

**Step 3: Classify and route**
```
# Example analysis:
Round 1: FAILED — file size limit logic incorrect (edge case: 10MB file rejected)
Round 2: FAILED — concurrency race condition in temp file cleanup
Round 3: FAILED — S3 upload timeout handling incomplete

Pattern: All three failures relate to edge case handling for external calls.
Round 1 and 3: timeout/file size (external service interaction)
Round 2: concurrency (shared resource management)

Classification: Scheme defect. The scheme T-033 does not specify:
(1) timeout behavior for S3 uploads
(2) concurrent upload lock strategy
(3) temp file cleanup guarantees

This is a scheme defect, not a repeated implementation defect.
Escalation target: @dev-lead for scheme revision.
```

### Third-Rework Execution Template

```
## Escalation Report: Task-NNN

**Trigger**: Third rework at [state] state
**Rework history**:
- Round 1: [date] — [outcome] — [brief reason]
- Round 2: [date] — [outcome] — [brief reason]
- Round 3: [date] — [outcome] — [brief reason]

**Root cause classification**: [implementation / scheme / requirement / quality / resource / process]
**Evidence**: [specific observations supporting the classification]

**Escalation target**: @[agent-name]
**Requested action**: [specific request for the escalation target]

**Rework count**: Reset after escalation resolution
**Do NOT dispatch back to original agent until**: [specific condition]
```

### Escalation Decision Tree

```
Task reaches rework count = 3 at state X
│
├─ Analyze failure pattern across rounds 1-3
│  ├─ Same bug pattern? → Implementation defect → @dev-lead
│  ├─ Plan unworkable from start? → Scheme defect
│  │  ├─ Structural issue (system topology, technology)? → @architect
│  │  └─ Interface issue (API, contract, module boundary)? → @dev-lead
│  ├─ Spec unclear/contradictory? → Requirement ambiguity → @client or user
│  ├─ Disagreement on "correct"? → Quality gate misalignment → user
│  ├─ Agent lacks skill? → Resource constraint → @pm
│  └─ No owner for this work? → Process gap → @pm
│
├─ Build escalation package
│  1. Three failure summaries
│  2. Root cause classification with evidence
│  3. Recommended action for escalation target
│  4. Impact assessment (downstream tasks affected)
│
├─ Execute escalation
│  1. STOP all dispatch to original agent
│  2. DISPATCH to escalation target with package
│  3. UPDATE TASK.md: state = escalation-in-progress
│  4. LOG progress-log.md with ESCALATE tag
│
└─ Post-escalation tracking
   1. Monitor escalation target response
   2. After resolution: RE-EVALUATE plan (do not auto-dispatch to original path)
   3. RESET rework counter
   4. START fresh dispatch chain
   5. DOCUMENT lesson learned
```

### Post-Escalation Non-Regression Rule

After escalation resolves:
1. Do NOT dispatch back to the original execution path automatically
2. Re-evaluate the plan with the new information
3. Start a fresh dispatch chain
4. Document the lesson learned in TASK.md

```
# BAD
Escalation: @dev-lead revises scheme.
PM: "Scheme revised. Dispatching back to @backend for implementation."
# → Same path that failed 3 times. No re-evaluation.

# GOOD
Escalation: @dev-lead revises scheme.
PM: "Scheme revised with new concurrency model. Re-evaluating:
- New scheme adds Redis dependency → check @devops Redis availability
- New scheme changes interface contract → @frontend may need update
- Dispatching @devops first for Redis verification, then @backend."
```

### Post-Escalation Re-evaluation Checklist

```
After escalation resolves:
- [ ] Read the revised scheme/document carefully
- [ ] Identify what changed from the original
- [ ] Check for new dependencies introduced by the change
- [ ] Check for downstream tasks affected by the change
- [ ] Verify the escalation target's resolution addresses the root cause
- [ ] Determine if the original agent is still the right implementer
- [ ] Reset rework counter in TASK.md
- [ ] Document lesson learned: what went wrong, how it was fixed, how to prevent recurrence
- [ ] Start fresh dispatch chain with the new information
```
