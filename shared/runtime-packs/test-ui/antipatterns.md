> 源：core.md §Anti-Patterns (inline) + §Methodology

# 界面测试师 — Anti-Patterns

## Named Anti-Patterns

---

### Coverage Fabrication

**Definition**: Listing a state or checklist item as PASS without a corresponding screenshot file in the evidence package. Creating the appearance of coverage where none exists.

**Manifestations**:

```markdown
# BAD — coverage fabrication
| State | Desktop | Mobile |
|---|---|---|
| Initial | login-desktop-initial.png | login-mobile-initial.png |
| Error | login-desktop-error.png | login-mobile-error.png |

# But login-desktop-error.png does not exist in the directory.
# The tester "remembered" seeing an error state and marked it covered.
```

```markdown
# BAD — checklist fabrication
| Item | Result | Notes |
|---|---|---|
| Tab traversal | PASS | 7 elements |
| Focus visible | PASS | — |

# No screenshot of focus state exists. The tester "assumed" focus works.
```

**Why it's dangerous**: Coverage fabrication is indistinguishable from actual coverage in the report. @test-lead assumes the evidence exists and may issue a verdict based on missing data. When the defect surfaces in production, the audit trail shows "PASS" with no supporting evidence.

**Correction**: Every listed state must have a corresponding file in `tests/screenshots/vN/`. Every checklist item marked PASS must have either: (a) a screenshot proving the state, or (b) an explicit note explaining how it was verified without a screenshot (rare, must be justified).

```markdown
GOOD — file existence verification:
Before delivering, run: ls -la tests/screenshots/v1/
Confirm every file referenced in the matrix exists and has size > 5KB.

If a state could not be captured: mark it N/A or BLOCKED, not PASS.
```

---

### Opinion Leak

**Definition**: Injecting subjective aesthetic judgments into an evidence report. UI testing is not design critique.

**Manifestations**:

```markdown
# BAD — opinion leak
"The spacing feels off between the header and the form."
"The color is too bright for a professional application."
"This layout looks cluttered on mobile."
"The font choice doesn't match the brand personality."
```

**Why it's dangerous**: Opinions are not actionable. "Too bright" is not a defect — it is a preference. When @test-lead receives opinion-laden reports, they cannot distinguish between measurable defects (which block release) and aesthetic preferences (which do not). The report loses credibility.

**Correction**: Convert every observation into a measurable statement or classify it as UNSURE if measurement is impossible.

```markdown
GOOD — observable fact:
"FAIL: Submit button is partially cut off at viewport width 375px.
Screenshot: checkout-mobile-normal.png. Button right edge at x=360px,
viewport width=375px, 15px overflow."

GOOD — UNSURE when design context needed:
"UNSURE: Primary button uses #FF5733 (orange-red). Cannot classify as
PASS/FAIL without knowing the project's approved color palette.
Screenshot: login-desktop-normal.png."

GOOD — not mentioned at all:
(The tester personally dislikes the card border radius. This is not
a measurable defect, so it is not in the report.)
```

---

### UNSURE Aversion

**Definition**: Forcing a PASS or FAIL classification on an ambiguous observation because the tester is uncomfortable leaving items unresolved.

**Manifestations**:

```markdown
# BAD — forcing PASS
| Loading state | PASS | Probably fine, there's a spinner |

# The tester didn't check whether the spinner meets the project's
# loading state specification. "Probably fine" is not evidence.
```

```markdown
# BAD — forcing FAIL
| Focus visible | FAIL | Focus ring is very thin |

# "Very thin" is subjective. Is it 1px? 2px? Does it meet WCAG?
# Without the project's accessibility baseline, this cannot be classified.
```

**Why it's dangerous**: A forced PASS on an ambiguous item is false evidence. A forced FAIL on an ambiguous item creates unnecessary rework. Both pollute the verdict with signal that does not reflect reality.

**Correction**: When uncertain, emit UNSURE with a specific reason and the information needed to resolve it.

```markdown
GOOD — honest UNSURE:
| Loading state | UNSURE | Login button shows spinner but no text change.
Cannot determine if this meets project's loading state spec without
access to design documentation. Screenshot: login-desktop-loading.png |

GOOD — honest UNSURE:
| Focus visible | UNSURE | Focus ring on primary button is 1px dashed
outline, color #9e9e9e. Unable to classify as PASS/FAIL without knowing
the project's accessibility baseline. Screenshot: login-desktop-focus-button.png |
```

---

### Partial-Screenshot Substitution

**Definition**: Capturing only the above-the-fold area or a cropped region and claiming it represents full-page coverage.

**Manifestations**:

```bash
# BAD — partial screenshot
# Using Chrome DevTools "Capture screenshot" (viewport only, not full page)
# Or using Playwright without fullPage: true
page.screenshot({path: 'login.png'})  # Only captures viewport, not full page
```

```markdown
# BAD — claiming full coverage from partial evidence
Screenshot: login-desktop-top.png (only shows header and top form)
Claimed: "Login page initial state captured"
# Missing: footer, any content below the fold, error messages that
# appear at bottom of form
```

**Why it's dangerous**: Defects often appear below the fold: footer misalignment, form error messages, overflow content, mobile-specific layout issues. A partial screenshot provides false confidence that the full page is correct.

**Correction**: Always capture full-page screenshots.

```bash
# GOOD — full page capture
# Chrome DevTools: Cmd+Shift+P → "Capture full size screenshot"
# Playwright:
page.screenshot({fullPage: true, path: 'login-desktop-initial.png'})
# Puppeteer:
page.screenshot({fullPage: true, path: 'login-desktop-initial.png'})
```

---

### Viewport Omission

**Definition**: Capturing screenshots in only one viewport (typically desktop) and omitting the mobile viewport.

**Manifestations**:

```
Evidence package contains:
- login-desktop-initial.png
- login-desktop-normal.png
- login-desktop-error.png

Missing: all mobile screenshots
```

**Why it's dangerous**: Mobile layouts have distinct failure modes: touch targets too small, text overflow, horizontal scroll, navigation collapsed incorrectly, form fields unreachable. Desktop-only testing misses an entire class of user-facing defects.

**Correction**: Both viewports are mandatory. No exceptions.

```bash
# Desktop capture
page.setViewportSize({width: 1920, height: 1080})
page.screenshot({fullPage: true, path: 'login-desktop-initial.png'})

# Mobile capture
page.setViewportSize({width: 375, height: 667})
page.screenshot({fullPage: true, path: 'login-mobile-initial.png'})
```

---

### State Matrix Omission

**Definition**: Capturing only the "normal" state and omitting other required states: initial, empty, error, loading, success.

**Manifestations**:

```
Evidence package contains only:
- login-desktop-normal.png
- login-mobile-normal.png

Missing: initial (first load), error (wrong password), empty (no data),
loading (during auth), success (post-login redirect)
```

**Why it's dangerous**: Many UI defects only appear in non-normal states: error messages positioned incorrectly, loading spinners overlapping content, empty states missing entirely. Testing only the normal state misses these defects.

**Correction**: Minimum 4 states per page. Document the state matrix before capturing.

```markdown
State matrix for login page:
| State | Trigger | Required |
|---|---|---|
| Initial | First load, no interaction | Yes |
| Normal | Form filled, before submit | Yes |
| Error | Submit with invalid credentials | Yes |
| Loading | During authentication request | Yes (if async) |
| Empty | N/A for login page | N/A |
| Success | Post-login dashboard | Optional |
```
