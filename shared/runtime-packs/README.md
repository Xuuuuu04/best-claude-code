# Runtime Packs — Architecture, Naming, Loading, Maintenance

## Three-Layer Architecture

The Harness agent system uses a three-layer knowledge architecture:

```
Layer 1 (L1): agents/<name>.md
  - ≤ 80 lines
  - Frontmatter + hardcoded rules + identity + workflow skeleton
  - runtime-index section points to L3 files
  - Always loaded at dispatch time

Layer 2 (L2): shared/runtime-packs/<agent>/core.md  [= "L3 core"]
  - Full methodology, skill tree, anti-patterns, collaboration protocol
  - Loaded on demand via runtime-index hints
  - Content must be ≥ 95% of original agent body (knowledge preservation)

Layer 3 (L3): shared/runtime-packs/<agent>/<topic>.md
  - Topic-specific deep dives (e.g., rtos.md, owasp.md, spark.md)
  - Loaded only when the specific topic is triggered
  - Reduces per-dispatch token cost
```

**Why three layers?** Weak models (GLM, DeepSeek, Doubao, MiniMax) degrade when
startup context exceeds ~6K tokens. Moving knowledge from L1 to L2/L3 keeps the
dispatch prompt lean while preserving full domain knowledge at runtime.

---

## Naming Conventions

```
shared/runtime-packs/<agent-slug>/
  core.md          — full-detail content (required for every agent)
  BASELINE.md      — 3 representative input scenarios + expected output structure
  <topic>.md       — domain-specific deep-dive (optional, multiple allowed)
```

Agent slugs match the `agents/<name>.md` filename without the `.md` extension:
`code-review`, `backend`, `embedded-dev`, `security-auditor`, etc.

Topic file names are lowercase, hyphen-separated, domain-descriptive:
- `rtos.md`, `drivers.md`, `ota.md` (embedded)
- `owasp.md`, `stride.md`, `compliance.md` (security)
- `spark.md`, `flink.md`, `warehouse.md` (data-engineer)
- `electron.md`, `tauri.md`, `qt.md` (desktop)
- `training.md`, `inference.md`, `eval.md` (ml-engineer)
- `antipatterns.md` (any domain)

---

## Loading Protocol

### At Dispatch Time (Main Process)
When dispatching an agent, assemble the runtime context pack:
1. The agent L1 (`agents/<name>.md`) — always included
2. `shared/runtime-packs/<name>/core.md` — include for complex tasks
3. Relevant topic files — include only what the task requires
4. One reference guide or template — per DispatchPlan
5. Current task context (task file, changed files)

Weak-model budget: 3–5 files maximum.

### At Agent Runtime (Self-Loading)
Agents follow the `runtime-index` section in their L1 to load topic files:
```
Peripheral driver → Read ~/.claude/shared/runtime-packs/embedded-dev/drivers.md
Unfamiliar territory → Read ~/.claude/shared/runtime-packs/<agent>/core.md
```

### Loading Priority
1. L1 rules section (Primacy Anchor) — always active
2. Topic-specific L3 file — loaded on trigger
3. core.md — loaded for complex or ambiguous tasks
4. BASELINE.md — loaded for calibration or onboarding

---

## Content Standards

### core.md Requirements
- REBUILT or ORIGINAL marker in frontmatter comments
- Full methodology section (not just workflow skeleton)
- Skill tree (3-level: domain → skill → specific capability)
- Anti-patterns section with named patterns
- Collaboration boundaries (upstream / downstream / lateral)
- Output contract with filled example
- Dispatch signals (strong triggers + do-not-dispatch conditions)

### BASELINE.md Requirements
Three scenarios minimum:
1. Simple canonical task — single deliverable, clear scope
2. Ambiguous/blocked task — BLOCK conditions, escalation path
3. Complex multi-component task — full workflow, collaboration points

Each scenario format:
```
## Scenario N: [short title]
**Input**: [what was provided]
**Expected Output Structure**: [fields and sections expected]
**Key Decision Points**: [what the agent must decide]
**BLOCK Condition**: [what would cause a BLOCK return]
```

---

## Maintenance Rules

1. **Knowledge preservation**: core.md byte count must be ≥ 95% of original
   agent body byte count. If the original was lost, mark as REBUILT.

2. **Sync obligation**: when an agent L1 is modified, the corresponding core.md
   must be reviewed for consistency within the same commit.

3. **No silent L1 changes**: agent L1 modifications route through
   `@prompt-engineer` per GP-O09. Direct edits are prohibited.

4. **Broken links**: the runtime-index section in each L1 uses absolute paths
   (`~/.claude/shared/runtime-packs/<agent>/`). Verify paths after any
   directory restructure.

5. **Hook-A whitelist**: `shared/runtime-packs/` is whitelisted for
   prompt-engineer writes. See `hooks/hook-a-claude-dir-guard.sh`.

6. **Rebuild notation**: if a core.md was rebuilt from domain knowledge rather
   than original source, add this comment in the file header:
   ```
   <!-- REBUILT: original detailed version lost during 2026-04-20 refactor -->
   ```

---

## Index of Runtime Packs

| Agent | core.md | BASELINE.md | Topic Files |
|---|---|---|---|
| embedded-dev | TBD | TBD | rtos, drivers, ota, antipatterns |
| security-auditor | TBD | TBD | owasp, stride, compliance |
| data-engineer | TBD | TBD | spark, flink, warehouse |
| desktop-dev | TBD | TBD | electron, tauri, qt |
| ml-engineer | TBD | TBD | training, inference, eval |
| (28 more agents) | TBD | TBD | — |

See `shared/runtime-packs/PHASE-PROGRESS.md` for current completion status.
