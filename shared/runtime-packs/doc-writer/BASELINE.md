# 文档工程师 — Baseline Scenarios

## Scenario 1: API Documentation Production (Canonical)

**Input**:
- @pm requests: "write API docs for the payment endpoint — @backend delivered T-029, @test-func completed test report"
- Source materials: `src/routes/payments.py`, `src/schemas/payment.py`, `src/services/payment_service.py`, `tests/reports/T-029-test-report-v2.md`

**Expected Output Structure**:
- Reader persona: Python backend developers integrating payment processing for the first time; goal: make a successful test payment and handle common error cases within 30 minutes
- Document type (Diátaxis): Reference + Quick Start Tutorial (first 2 sections)
- Read all source files before writing any prose
- Quick Start (one complete working example at the top, no prerequisites explanation)
- Authentication section (how to obtain token, Authorization header format, TTL and refresh)
- Endpoint reference: `POST /api/v1/orders` — HTTP method, full path, summary sentence, parameters table (name / in / required / type / description / example), request body field table (all fields: required/optional, type, constraints, description), example curl (complete, runnable, includes `$(uuidgen)` for idempotency key), success response (HTTP 201 + response body example), error code table (machine-readable code + HTTP status + description + resolution guidance)
- Version stamp: `v1.0 — 2026-04-20`
- Archive path: `docs/api/payment-api-v1.0.md`
- BLOCKED section 5.3 Webhook Events — `@backend has not finalized webhook event schema (T-031 pending)`
- Next step: `@pm — archive at docs/api/payment-api-v1.0.md, confirm with @backend that Section 5.3 will be addressed in T-031`

**Key Decision Points**:
- Read all 4 source files before writing the first word of prose
- Every request body field has its own table row: required/optional, type, constraints, description
- Code example is complete and runnable — includes Authorization header, Idempotency-Key header, full JSON body with real field names
- Error code table includes machine-readable codes (`INVALID_COUNTRY`, `VALIDATION_ERROR`, `PRODUCT_UNAVAILABLE`) — not just HTTP status numbers
- BLOCKED section explicitly named with missing item, responsible agent, and gap description
- Version stamp and archive path included in delivery summary

---

## Scenario 2: BLOCKED — Missing Source Material

**Input**:
- User: "write a deployment guide for the Docker container setup"
- Source material check: no Dockerfile found, no docker-compose.yml found, no @devops runbook found

**Expected Output Structure**:
- Status: BLOCKED — cannot produce deployment guide without source materials
- Specific block message:
  - "BLOCKED — Deployment guide requires the following source materials that are not available:"
  - "1. Dockerfile — required for: Docker image build specification, base image, exposed ports, environment variables section. Responsible: @devops"
  - "2. docker-compose.yml — required for: service configuration, volume mounts, network setup, environment variable defaults. Responsible: @devops"
  - "3. @devops runbook or deployment procedure document — required for: prerequisites section (OS, ports, DNS, certificates), step-by-step commands, verification steps, rollback procedure. Responsible: @devops"
- Reader persona: "I can begin once the source materials are available. Please confirm: who is the primary reader for this guide? Operations engineers (technical) or non-technical client stakeholders? This determines the vocabulary and structure."
- Do NOT write a skeleton with placeholder sections
- Do NOT invent prerequisites based on what "seems obvious"
- Route: "Please dispatch @devops to provide the above materials before I can proceed."

**Key Decision Points**:
- BLOCK is the correct response — not a skeleton with TBD sections
- Each blocked section names the specific missing item, what it is needed for, and the responsible agent
- Reader persona clarification asked as a single precise question (not a comprehensive interview)
- No fabricated prerequisites ("probably needs Docker installed") — no source material, no documentation

---

## Scenario 3: Document Update — Version Increment

**Input**:
- @backend: "we added a new endpoint: `GET /api/v1/orders/{id}` — retrieve a single order by ID"
- Existing document: `docs/api/payment-api-v1.0.md`
- Source: `src/routes/orders.py` (new endpoint handler available)

**Expected Output Structure**:
- Read `docs/api/payment-api-v1.0.md` fully before making any changes
- Read `src/routes/orders.py` to verify the endpoint behavior before writing
- Identify affected sections: add new endpoint section, update Table of Contents
- Write new section: `GET /api/v1/orders/{id}` — path parameter table (id: required, string, "Order ID returned in POST /orders response"), authentication required, response body schema (same order object as in POST /orders response — reference existing section rather than copying), error codes for 404 `ORDER_NOT_FOUND`
- Version increment: `v1.0 → v1.1` (minor increment: new section addition)
- Date stamp update: current date
- Change history entry: `v1.1 2026-04-20: Added GET /api/v1/orders/{id} endpoint documentation`
- Surgical Edit — update only the affected sections; do not rewrite stable sections
- Delivery summary: confirms what changed, the new version, the archive path of the updated file

**Key Decision Points**:
- Read the existing document fully before editing — do not overwrite sections that haven't changed
- Read the source file for the new endpoint before writing any prose about it
- Use Edit (surgical) not Write (full-file rewrite) — minimizes diff surface, preserves change history
- Minor version increment (0.x.0) for section addition — not a patch (0.0.x) or major (x.0.0)
- Single-source-of-truth: link to existing order object schema rather than copying it (no maintenance debt)
- Change history entry documents what changed in one sentence
