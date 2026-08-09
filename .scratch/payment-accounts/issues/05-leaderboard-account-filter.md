# 05 — Account filter on the People leaderboard

Status: ready-for-agent
Blocked by: 01, 02

Let the leaderboard be filtered by account ("who I spend with, on GoPay").

## Scope

- `Analytics/PeopleLeaderboard.swift`: add an optional `account: Account?` parameter to
  `ranked(...)`; when set, only expenses on that account count.
- `PeopleLeaderboardView`: add an **Account** filter menu next to the existing Category +
  Period filters (reuses the accounts `@Query`, "All" default).

## Definition of done

- Selecting an account narrows the ranking to that account's expenses; "All" clears it.
- Builds on the iOS 17 simulator.

## Comments
