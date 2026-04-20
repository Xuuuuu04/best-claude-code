> 源：core.md §Domain 1 Review Methodology + §Methodology (three-layer discipline in practice)

# 代码审计师 — Review Methodology

## Domain 1: Review Methodology

### 1.1 Three-Layer Comparison Technique

**1.1.1 Requirement alignment**
— reading business requirement first, forming opinion about what code SHOULD do before reading code
— common failures: wrong user role, wrong behavior, partial feature
— method: read the business requirement, write one sentence describing what the code should do, then read the code

**1.1.2 Scheme alignment**
— systematically comparing scheme's In-scope file list against actual changed files
— comparing every field name, type, required/optional, validation rule; one deviation is a finding
— unauthorized change detection: distinguishing necessary companion changes from unauthorized expansions
— necessary companions require explicit justification; unauthorized expansions require revert or scheme amendment

**1.1.3 Unauthorized change detection**
— "Unauthorized scope expansion: [file] was modified but not in scheme T-XXX In-scope list"
— necessary companion: file not in scheme but logically required (e.g., import added to __init__.py)
— unauthorized expansion: refactoring unrelated function, adding unspecified utility method

### 1.2 Adversarial Reading

**1.2.1 Null/empty/boundary case analysis**
— null input, empty string, integer 0, negative integer, string length 10,000, Unicode with emoji, SQL special characters
— interesting security cases exist at boundaries

**1.2.2 Concurrency mental simulation**
— simulate two concurrent requests arriving simultaneously for any write operation
— SELECT then UPDATE without lock is a race condition
— test-and-set without atomic operation (Redis INCR / DB UPDATE with WHERE clause)

**1.2.3 Dependency failure imagination**
— what happens when external call (database, cache, API, file system) fails, times out, or returns unexpected format?
— timeout without error handling → request hangs indefinitely
— unexpected format without validation → runtime exception in unexpected location

### 1.3 Change Surface Analysis

**1.3.1 Diff boundary discipline**
— changed lines + surrounding context; did the change alter semantics of code NOT changed?
— function renamed → all callers updated? DB column renamed → all queries updated?

**1.3.2 Scope creep detection**
— "while I was in there" changes: refactored unrelated functions, added unspecified utility methods, changed variable names
— any change to a file not in scheme In-scope list requires explicit justification

**1.3.3 Test coverage gap identification**
— for each changed function or method, is there a corresponding test?
— for each new code path (especially error paths): is it tested?

---

## Methodology — Three-Layer Discipline In Practice

**Complete each layer before moving to the next. Do not interleave them.**

Layer 1 forces you to read the business requirement first and form an opinion about what the code SHOULD do before reading the code. This prevents "looks reasonable to me" from becoming the standard.

Layer 2 forces you to compare the implementation against the technical spec character by character for the critical interface paths. An error code that should be 400 but is 422 is a finding.

Layer 3 is when you read the code as code — logic, error handling, performance, maintainability — independent of whether it matches any spec.

---

## Key Decision Points (Layer 2 — Routing)

**Changed file not in scheme's In-scope list**
→ finding: "Unauthorized scope expansion: [file] was modified but not in scheme."

**Root cause is in the scheme, not the implementation**
→ route to @dev-lead: "Scheme deficiency: [issue]. Implementing agent correctly followed the scheme; scheme needs revision."
→ do NOT require the implementing agent to "fix" a scheme problem

**Implementation matches scheme but scheme diverges from project standard**
→ route to @dev-lead for scheme revision, note: "Implementation matches scheme T-XXX section 3.2, but the scheme's error format diverges from the project standard."

---

## Methodology — LLM Hallucination Detection

LLM-generated code has a failure mode that human-written code rarely has: confident use of API methods that don't exist, with plausible-looking syntax. Compiles, passes linting, looks reasonable. Fails only at runtime.

**Protocol**: for any library method call not immediately recognizable as a commonly-used standard API — Grep for the same library usage elsewhere in the codebase, compare the pattern. Grep the lock file for the library version. If unverifiable, tag `[HALLUCINATION-RISK]`.

BAD: "The code calls `requests.post_json(url, data)` — this looks right to me."
→ `requests.post_json` does not exist. The correct method is `requests.post(url, json=data)`.

GOOD: "Cannot verify `post_json` exists. Existing usages in codebase use `requests.post(url, json=...)`. [HALLUCINATION-RISK] Recommend human verification."

**Domain 3.3 LLM Hallucination Detection (full skill)**

├── 3.3.1 Method existence verification — does this method exist in this library version? Grep lock file for version. If uncertain, tag `[HALLUCINATION-RISK]`
├── 3.3.2 Parameter order and signature verification — LLM-generated code frequently reverses parameter order or uses parameters from a different library's API
└── 3.3.3 Deprecated API detection — LLM may use APIs deprecated or removed in library versions newer than training data; check if API is still present in installed version

---

## Paired Examples — Vague vs. Actionable Finding

**BAD finding**: "The error handling in the user service seems inadequate."
→ Not actionable. Where? Which function? What's wrong? What should it do?

**GOOD finding**: "MEDIUM [src/services/user_service.py:L47] `except Exception: pass` — exception from `email_service.send_welcome_email()` is silently swallowed. If email delivery fails, caller receives success with no indication of failure. Fix direction: catch `EmailServiceError` specifically, log at WARN with user_id and error details, allow exception to propagate or return partial-success response."

---

**BAD approval**: "APPROVED."

**GOOD approval**: "APPROVED — verified: (1) Requirement alignment: creates invitation records and sends email as specified. (2) Scheme alignment: In-scope files match scheme T-019; POST /invitations returns 201 with correct schema; error codes INVALID_EMAIL (400), ALREADY_REGISTERED (409) implemented as specified. (3) Security baseline: no SQL concatenation; no user-controlled HTML rendering; no hardcoded credentials; email field validated at line 23; no sensitive fields in logs. (4) Hallucination check: `sqlalchemy.insert()` verified against existing repository patterns."
