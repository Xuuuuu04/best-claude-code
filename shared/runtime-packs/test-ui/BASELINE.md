# 界面测试师 — Baseline Scenarios

## Scenario 1: Full UI Evidence Package — Login Page (Canonical)

**Input**:
- Task: T-019 — Login page UI verification, test-func Round 1 passed
- Environment: https://staging.example.com, Chrome 124, macOS
- Test account: member role (no credentials in evidence package)

**Expected Output Structure**:
- Status: READY-FOR-NEXT → @test-lead
- Files in `tests/screenshots/v1/`:
  - `login-desktop-initial.png` — page before any interaction, 1920×1080
  - `login-desktop-normal.png` — page with values filled in (before submit), 1920×1080
  - `login-desktop-error.png` — error state after wrong password, 1920×1080
  - `login-desktop-loading.png` — spinner during authentication, 1920×1080
  - `login-mobile-initial.png` — 375×667
  - `login-mobile-normal.png` — 375×667
  - `login-mobile-error.png` — 375×667
  - `login-desktop-focus-password.png` — focus state screenshot for ambiguous item
  - `interaction-check.md`
- Interaction checklist (8 items):
  - Tab traversal: PASS — 7 elements, logical order documented
  - Focus visible: FAIL — password field loses focus ring entirely (screenshot reference provided)
  - Hover feedback: PASS — login button background changes on hover
  - Click/active feedback: PASS — button depresses visually within 100ms
  - Error state visible: PASS — error message appears below password field
  - Loading state: UNSURE — spinner visible but no text change; unclear if this meets project loading spec
  - Toast/notification: N/A — no toast expected on login page
  - Disabled state: PASS — submit button disabled during submission, click does not trigger event
- WCAG spot-check: contrast PASS; focus ring FAIL (same as above); tap targets PASS (≥44px on mobile)
- Obvious defects section: 1 FAIL listed with screenshot filename reference
- Verdict recommendation: @测试总监师

**Key Decision Points**:
- Password field FAIL reported as observable fact (focus ring absent) not opinion ("looks weak")
- Loading state is UNSURE (not forced to PASS or FAIL) because it requires design spec context
- N/A used for toast (not applicable to login page) — not left blank
- Both viewports captured — not just desktop
- Screenshot files exist for every state listed in the matrix

---

## Scenario 2: BLOCKED — Page Not Accessible

**Input**:
- Task: T-047 — Checkout flow UI verification
- Test-func has passed for checkout
- Test account credentials provided
- Environment: https://staging.example.com

**Expected Output Structure**:
- Status: BLOCKED
- Captured: `checkout-desktop-500-error.png` — the HTTP 500 page itself
- Reason: "The checkout page returns HTTP 500 for all test accounts. Cannot capture normal/error/empty states for checkout. Captured the 500 error page as evidence."
- Unblock condition: "@frontend or @backend must resolve the server error on the checkout endpoint. After unblock, re-capture full state matrix for checkout flow."
- No interaction checklist items completed (cannot test interaction on a broken page)

**Key Decision Points**:
- Did NOT list any states as covered (coverage fabrication anti-pattern avoided)
- DID capture the broken state screenshot as evidence
- BLOCKED is not the same as unable to start — captured what was available (the error page itself)
- Specific unblock condition stated

---

## Scenario 3: Targeted Re-capture After Fix

**Input**:
- Task: T-019 Round 2 — post-fix re-capture
- @test-lead's Round 1 verdict BLOCKED items: (1) password field focus ring absent; (2) mobile error state missing
- @frontend has fixed both items
- Only these two items need re-capture

**Expected Output Structure**:
- Status: READY-FOR-NEXT → @test-lead
- Scope: targeted re-capture, not full suite
- Files added to `tests/screenshots/v2/`:
  - `login-desktop-focus-password-v2.png` — new focus state for password field
  - `login-mobile-error-v2.png` — mobile error state (was missing in v1)
- Interaction checklist: only the 2 previously failed items re-evaluated:
  - Focus visible: PASS — password field now shows 2px solid #0066cc focus ring. Screenshot: `login-desktop-focus-password-v2.png`. [Previously FAIL Round 1]
  - (Mobile error state was captured as screenshot only, no separate checklist item)
- Screenshot matrix updated: `login-mobile-error.png` → `login-mobile-error-v2.png` now present
- Remaining v1 checklist items: unchanged from Round 1 (not re-tested — no changes to those areas)
- Verdict recommendation: @测试总监师 for Round 2 verdict

**Key Decision Points**:
- Only re-captured what was BLOCKED in the prior verdict — not a full re-run
- Annotated re-captured items as "[Previously FAIL Round 1]"
- Did NOT re-run the full 8-item checklist (efficient targeted re-capture)
- Files versioned as v2 to keep audit trail separate from v1
