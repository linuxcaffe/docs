# BUDGET.md

*Production accounting and ATL/BTL costing — [NbWeb-cine](../README.md)*

---

[insert screenshot — stripboard budget total and hledger output]

## Overview

*Coming soon — content from the current README budget and accounting sections.*

## Status

- [x] gen-budget.py — CHARACTER/actor two-path costing; resource BTL (day + hourly)
- [x] Live budget total in stripboard via {{hledger: balance ...}} inline query
- [x] ↻ regen button — runs gen-budget.py, clears cache, updates total in place
- [x] ATL: fudge (pre-cast estimate) or rate × days from cast annotation sidecar
- [x] BTL: location fee, resource day/hour rates from annotation sidecars
- [x] Date-range filtering on resource notes (start: / end:)
- [x] per-hour resources — hours_type: maps to day note hours sub-fields
- [x] Annotation sidecars — cost data admin-only, note body crew-visible
- [x] hledger journal format — queryable for any report (top sheet, cost-to-date, etc.)
- [ ] Credits generation from cast/character notes (planned)
