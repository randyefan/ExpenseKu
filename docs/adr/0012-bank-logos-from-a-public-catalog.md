# ADR-0012 — Bank logos come from a read-only CloudKit public catalog

Status: Accepted
Date: 2026-10-17
Amends: "no backend" in `CONTEXT.md`

## Context

The owner wants Accounts to carry real bank logos, and wants the list of logos to change
at any time without an App Store release. Bundled images cannot change without a
release. A logo API (logo.dev, Brandfetch) needs a key the repository may not hold,
sends the owner's bank names to a third party, and covers Indonesian banks unevenly. A
static JSON host is a second backend outside Apple's, with its own cache invalidation.

## Decision

**A `BankLogo` record type in the public database of the app's existing CloudKit
container**, edited by the developer in CloudKit Console. The app only ever reads it.
An Account stores the record's `id` as a string (`brandID`), not a relationship:
SwiftData cannot relate the private store to the public database.

A snapshot of the catalog ships in the app bundle and is used until the first fetch
succeeds.

## Consequences

- "No backend" now reads: no backend **for the owner's data**. The public database holds
  only the shared logo list; nothing the owner enters leaves their private database.
- There is still no server to run. Hosting and quota are CloudKit's.
- The record type, its indexes (`sortOrder` sortable, `recordName` queryable) and the new
  `Account.brandID` field must be deployed to CloudKit **Production** before a release.
- A logo withdrawn from the catalog leaves `brandID` dangling; the app draws a bank glyph
  instead, and restoring the record restores the logo.
- Bank logos are trademarks. They are shown unaltered, only to mark the owner's own
  Accounts.
