---
name: backend-and-data
description: Guides building reliable server-side code — API endpoints and route handlers, input validation at the boundary, data modeling, schema migrations, and transactional integrity. Use when implementing or modifying backend endpoints, services, database schemas, migrations, or the contract between frontend and backend.
---

# Backend & Data Engineering

## Overview

Build server-side code that validates at the boundary, keeps data consistent, and evolves schemas without breaking consumers. Backend bugs are disproportionately expensive: they corrupt data, leak information, or break every client at once. This skill enforces the discipline that prevents those failure modes.

For the *design* of the API surface (naming, versioning, error semantics, Hyrum's Law), see `api-and-interface-design`. This skill covers the *implementation and data* side.

## When to Use

- Implementing or modifying API endpoints, route handlers, or server actions
- Adding or changing database tables, columns, or indexes
- Writing schema migrations
- Handling user input server-side
- Changing the contract between frontend and backend

## Process

### 1. Define the contract first

Before writing handler code, write down (in the PR description, a types file, or an OpenAPI/zod schema):

- Request shape: method, path, params, body, auth requirements
- Response shape: success payload, every error status and body
- Who consumes it and what they already depend on

If the endpoint already exists, list current consumers before changing anything. An "unused" field is only unused until you grep for it.

### 2. Validate at the boundary

Every input crossing a trust boundary gets validated **at the edge**, before business logic:

- Use a schema validator (zod, joi, valibot) — not hand-rolled `if` checks
- Validate type, shape, range, and length; reject unknown fields where feasible
- Parse, don't validate-and-cast: the output of validation should be a typed value the rest of the code trusts
- Never trust client-supplied IDs for authorization decisions — check ownership server-side on every request

### 3. Handle errors as part of the contract

- Map every failure to a deliberate status code: 400 (bad input), 401/403 (auth), 404 (not found or hidden), 409 (conflict), 422 (semantic), 500 (ours)
- Error bodies follow one consistent shape across the service
- Never leak internals: no stack traces, SQL, or file paths in responses
- Log the detailed error server-side with request correlation (see `observability-and-instrumentation`)

### 4. Model data deliberately

- Name tables/columns for the domain, not the UI
- Every table: primary key, `created_at`/`updated_at`, explicit nullability
- Foreign keys with explicit `ON DELETE` behavior — decide, don't default
- Add indexes for the queries you actually run; verify with `EXPLAIN` on realistic data
- Constraints in the database (unique, check, not-null) — application-level checks are advisory, database constraints are guarantees

### 5. Migrate safely (expand → migrate → contract)

Schema changes deploy separately from code that depends on them. Never break the running version:

1. **Expand:** add the new column/table/index as nullable or defaulted. Deploy.
2. **Migrate:** backfill data; new code writes both shapes if needed. Deploy.
3. **Contract:** once nothing reads the old shape, remove it in a later release.

Rules:

- Every migration has a tested rollback (or is documented as irreversible and gated on a backup)
- No destructive migration (drop column/table) in the same release as the code change that stops using it
- Long-running backfills run as batched jobs, not inside the migration transaction
- Test migrations against a copy of production-shaped data, not an empty database

### 6. Keep writes transactional and idempotent

- Multi-step writes that must succeed together go in one transaction
- Endpoints that may be retried (payments, submissions, webhooks) are idempotent — use idempotency keys or natural unique constraints
- No read-modify-write races: use atomic updates, optimistic locking, or `SELECT ... FOR UPDATE`

### 7. Verify

Follow `test-driven-development` for the handler logic. Minimum evidence before done:

- [ ] Contract tests: happy path + every documented error status
- [ ] Validation tests: malformed body, missing fields, wrong types, oversized input
- [ ] AuthZ test: user A cannot read/modify user B's resource
- [ ] Migration applied and rolled back cleanly on a non-empty database
- [ ] `EXPLAIN` checked for any new query against an indexed path

## Rationalizations

| Excuse | Reality |
|---|---|
| "The frontend already validates this" | The frontend is a convenience, not a boundary. Anyone with curl bypasses it. |
| "I'll add the index when it gets slow" | "Slow" shows up in production first. Check the query plan now — it's one command. |
| "This migration is tiny, no rollback needed" | Tiny migrations fail too, usually at 2 a.m. Write the down path while the up path is fresh. |
| "We can drop the column in the same PR" | The old code runs during deploy. Expand → migrate → contract, always. |
| "It's an internal endpoint, auth can wait" | Internal endpoints become external the day someone needs them. Boundaries don't rot gracefully. |
| "A retry just creates a duplicate row, we'll dedupe later" | Duplicated money movement isn't deduped later. Idempotency is part of the write, not a cleanup job. |

## Red Flags — stop and fix

- Handler reads `req.body.foo` without a schema parse anywhere above it
- Authorization check based on data the client sent
- Migration file that both alters schema and updates rows in one transaction on a large table
- `catch (e) { return res.status(500).send(e.message) }` — leaking internals
- New query filtering on an unindexed column
- "TODO: make this transactional"

## Verification

Done means evidence, not confidence:

- Tests from step 7 passing in CI output
- The contract (schema/types) committed next to the handler
- Migration up **and** down executed successfully against realistic data
- Security checklist items for input handling cleared (`../../references/security-checklist.md`)
