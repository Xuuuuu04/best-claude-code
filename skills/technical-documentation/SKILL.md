---
name: technical-documentation
description: Technical writing and documentation methodology for the Harness team. Covers reader-persona-driven structure, Diátaxis framework (Tutorial/How-to/Reference/Explanation), API documentation (OpenAPI-grade), user manuals, deployment guides, academic documentation (IMRaD), milestone reports, handover documents, version stamping, fact trail architecture, and code example requirements.
type: skill
---

# Technical Documentation Skill

## 1. Reader-Persona-First Discipline

Before writing any content, define:
- Who is the primary reader?
- What do they need to accomplish after reading?
- What is their existing knowledge level?
- What format do they expect?

Audience-agnostic writing serves no one. Same topic, different readers → completely different documents.

Example: "Start the application"
- For non-technical client: full explanation + verification + troubleshooting contact
- For operator: command + verification curl + expected output only

## 2. Diátaxis Framework

| Quadrant | Orientation | Example |
|---|---|---|
| **Tutorial** | Learning-oriented | "Getting Started with the API" |
| **How-to guide** | Task-oriented | "How to deploy to production" |
| **Reference** | Information-oriented | "API endpoint specification" |
| **Explanation** | Understanding-oriented | "Authentication architecture" |

Mixing quadrants causes confusion. A single document should primarily serve one quadrant.

## 3. Document Type Structures

**API Documentation**: Overview → Authentication → Quick Start → Endpoint Reference → Error Code Table → SDK Examples → Rate Limits

**User Manual**: Overview → Key Concepts → Step-by-step Tasks (max 7 steps each) → FAQ → Troubleshooting

**Deployment Guide**: Prerequisites → Installation Steps → Configuration → Verification → Troubleshooting → Rollback

**Academic (IMRaD)**: Introduction (problem + gap + contribution) → Methods (replicable) → Results (descriptive) → Discussion (interpretation)

**Milestone Report**: Executive Summary → Deliverables Completed → Metrics/KPIs → Risks and Blockers → Next Steps

**Handover Document**: System Overview → Architecture Decisions → Operational Runbooks → Known Issues → Contact Points

## 4. Code Example Requirements

Every snippet must be:
- Language-tagged
- Include imports / dependencies
- Include required env vars or placeholders
- Include expected output
- Copy-paste runnable (or clearly marked if not)

BAD: `POST /api/v1/orders` with schema dump only.
GOOD: Full curl command with headers, body, success response, and error response table.

## 5. Fact Trail Architecture

- Track which source document backs each claim
- Every API endpoint description traces back to implementation file
- Enables accurate updates when underlying facts change
- NEVER fabricate facts. Missing source → BLOCK and route to upstream agent.

## 6. Version and Date Stamping

- `v[MAJOR.MINOR] — [YYYY-MM-DD]` in every document header
- Changelog entry for all versions after v1.0
- Version increment strategy:
  - Patch (0.0.x): typo fixes, minor corrections
  - Minor (0.x.0): new sections, feature additions
  - Major (x.0.0): structural reorganization

## 7. Readability Metrics

- Paragraph limit: 200 words
- List item limit: 7 items per list
- Short declarative sentences preferred
- Table of contents with anchor links for documents > 5 sections
- "No-Placeholder Contract": every delivered section is complete. No TODO, "待补充", or empty cross-references.

## 8. Error Code Table Format

| Code | HTTP Status | Title | Description | Resolution | Example |
|---|---|---|---|---|---|
| `VALIDATION_ERROR` | 422 | Invalid input | Field failed validation | Check field constraints per docs | `{"code":"VALIDATION_ERROR","field":"email"}` |

## 9. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Fact Fabrication** | Inventing API behaviors to fill gaps | BLOCK and route to upstream agent |
| **Audience-Agnostic Writing** | No defined reader persona | Name reader persona at document opening |
| **Undated Evergreen** | No version or date stamp | `v1.0 — 2026-04-20` required |
| **Code Dump Disguised as Documentation** | Pasting schema without prose | Every code block wrapped in explanatory prose |
| **Missing Navigation** | Long documents without ToC | Documents > 5 sections require explicit ToC |
