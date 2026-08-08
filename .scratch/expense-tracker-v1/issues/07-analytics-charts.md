# 07 — Analytics: spend by category & spend over time

Status: resolved

The two overview charts, using Swift Charts.

## Scope

- **Spend by category** — total per category over a selectable period.
- **Spend over time** — spend trend across a time axis.
- Query/aggregation layer over SwiftData feeding both charts.

## Definition of done

- Both charts render correct totals from real expense data and update as data changes.

## Comments

- 2026-08-09: Implemented. Pure aggregation in `Analytics/SpendSummary.swift` (`byCategory(from:dateRange:)` with an "Uncategorized" bucket per ADR-0001; `overTime(from:dateRange:granularity:)` bucketing by day/month) — UI-free, unit-testable, sharing the pattern the leaderboard established. Charts (Swift Charts): `SpendByCategoryChart` (horizontal bars + IDR annotations) and `SpendOverTimeChart` (monthly bars). `InsightsView` restructured to host both charts over a shared period filter plus a link to the leaderboard. Added `Decimal.doubleValue` (chart-boundary only; Decimal stays the money source of truth). Verified **BUILD SUCCEEDED** on the iOS 17 simulator.
