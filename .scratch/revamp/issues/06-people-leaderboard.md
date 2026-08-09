# 06 — People leaderboard (reskin)

Status: ready-for-agent
Blocked by: 01
Refs: `refs/leaderboard.png`
Files: `Features/Insights/PeopleLeaderboardView.swift`

Reskin "Who you spend with": period/category/account filters, a ranked list (rank number,
person name, "N expenses", total spent right-aligned), and the "No People Yet" empty state.

## Verify
`scripts/shot.sh leaderboard -- -seedSampleData -startScreen leaderboard` vs `refs/leaderboard.png`.
`-a` for dark. `scripts/shot.sh --test`.

## Guardrails
Keep full-amount-to-each-companion attribution (totals may exceed grand total by design).
Keep the empty state. Behaviour unchanged.
