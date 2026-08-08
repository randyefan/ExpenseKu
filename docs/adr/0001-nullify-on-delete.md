# ADR-0001 — Nullify on delete; never cascade to expenses

Status: Accepted
Date: 2026-08-09

## Context

Expenses reference a Category (to-one) and People (many-to-many). The owner can delete Categories and People from the Manage screens. We must define what happens to expenses that reference a deleted entity. SwiftData+CloudKit requires all relationships to be optional, which makes nullify natural but doesn't force the policy.

## Decision

Deletes **nullify**, never cascade:

- Deleting a **Category** sets `expense.category = nil` on referencing expenses, which the UI renders as **"Uncategorized"**. The expenses are kept.
- Deleting a **Person** removes them from each expense's `people`. The expenses are kept.

Expenses are never deleted as a side effect of deleting a tag.

## Consequences

- Historical spend — the source of truth — is preserved even as the tag vocabulary changes.
- "Uncategorized" is a valid *display* state for existing expenses, even though a category is **required at entry** (see the schema note: the stored property is optional for CloudKit, required by the UI). Charts must handle an "Uncategorized" bucket.
- No confirmation-blocking on "category in use"; deletion always succeeds.
