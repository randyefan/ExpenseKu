# ADR-0002 — App-level de-duplication of Category/Person, with a prompt

Status: Accepted
Date: 2026-08-09

## Context

The People leaderboard and Spend-by-Category charts aggregate across reusable Category and Person entities. Duplicate records (a "Fadil" and a "fadil") would silently split totals and corrupt rankings. SwiftData mirrored to CloudKit **cannot enforce unique constraints**, so uniqueness must be guarded in the app.

## Decision

- Category and Person are **never free-typed onto an expense**. The expense editor only lets the owner **pick from existing** entries or explicitly create a new one.
- On create ("＋ New"), the app queries existing entities by **trimmed, case-insensitive** name. If a match is found, it **prompts** the owner — e.g. "Use existing 'Fadil'?" — rather than silently reusing the match or blindly inserting a duplicate.

## Consequences

- Duplicate tags are prevented at the point of creation, keeping aggregates correct without a DB-level constraint.
- The prompt keeps the owner in control (a deliberate near-duplicate is still possible if they insist), at the cost of one extra tap when a name collides.
- Creation flows (in the editor and in the Manage screens) share one de-dup routine.
