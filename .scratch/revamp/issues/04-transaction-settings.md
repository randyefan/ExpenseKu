# 04 — Transaction Settings sheet (reskin)

Status: ready-for-agent
Blocked by: 01
Refs: `refs/transaction-settings.png`
Files: the settings sheet presented from the home calendar button (in `ExpensesView.swift`)

Reskin the single-stepper "Monthly Start Date" (1–31) sheet with its one-line explanation and
Done button, in Warm Cards styling.

## Verify
Seed, open the calendar/settings button on home, screenshot vs `refs/transaction-settings.png`.
`-a` for dark. `scripts/shot.sh --test`.

## Guardrails
Keep the payday range 1–31 and the wording "Monthly Start Date". No new settings. No income/budget.
