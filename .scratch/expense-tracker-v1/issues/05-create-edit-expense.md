# 05 — Create / edit / delete an Expense

Status: ready-for-agent
Blocked by: 03, 04

The core logging loop: the add/edit-expense screen and flow.

## Scope

- Fields: amount, date (defaults to now), category (pick/create), people (pick/create, zero+), note.
- Fastest-path add flow on iPhone per ticket 01's design.
- Edit and delete existing expenses.
- Money entry uses `Decimal`, formatted for IDR.

## Definition of done

- Owner can log a fully-tagged expense in seconds and edit/delete it afterward.

## Comments
