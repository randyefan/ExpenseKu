# 08 — People leaderboard ("who did I spend the most with")

Status: needs-info
Blocked by: 01, 03, 05

The headline analytics feature: rank companions by attributed spend.

## Scope

- Ranked list: **Person → total attributed spend + count of shared expenses**.
- Attribution: **full amount to each companion** (query-time; nothing stored). A 100k expense with two people credits 100k to each.
- **Filters**: by category and by date range (e.g. "top people for Makan this month").
- Query layer shared with ticket 07 where sensible.

## Definition of done

- Leaderboard ranks people correctly, and the category + date filters produce the expected subsets.

## Comments
