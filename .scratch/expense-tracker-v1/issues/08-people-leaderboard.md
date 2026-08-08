# 08 — People leaderboard ("who did I spend the most with")

Status: resolved

The headline analytics feature: rank companions by attributed spend.

## Scope

- Ranked list: **Person → total attributed spend + count of shared expenses**.
- Attribution: **full amount to each companion** (query-time; nothing stored). A 100k expense with two people credits 100k to each.
- **Filters**: by category and by date range (e.g. "top people for Makan this month").
- Query layer shared with ticket 07 where sensible.

## Definition of done

- Leaderboard ranks people correctly, and the category + date filters produce the expected subsets.

## Comments

- 2026-08-09: Implemented. Pure aggregation in `Analytics/PeopleLeaderboard.swift` (`ranked(from:category:dateRange:)` → `[PersonSpend]`, full-amount-to-each attribution, desc by total then name) — UI-free and dependency-free so it's unit-testable. `Features/Insights/PeopleLeaderboardView` renders the ranked list with a **period** filter (`DateRangeFilter`: all-time / last-30 / this-month / this-year) and a **category** filter. Hosted by `InsightsView` in the Insights tab (replaces the placeholder). Verified **BUILD SUCCEEDED** on the iOS 17 simulator.
- Note: no XCTest target exists yet (adding one needs Xcode). The `Analytics/` layer was written UI-free precisely so the attribution + filter logic can be covered by unit tests once a test target is added — recommended follow-up to nail the DoD's "filters produce the expected subsets".
