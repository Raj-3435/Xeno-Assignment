# Xeno Comm-Log Send Reconciliation

## Objective

Reconcile the Finance-reported `target_base` of 22 for:

- Merchant: 501
- Month: October 2026
- Communication type: Campaign (`2`)

The investigation starts from the straightforward event-level count
and progressively applies the reporting and retry rules documented in
the provided data dictionary.

## Final Result

**Reconciled target_base: 22**

## Reconciliation Summary

| Step | Adjustment | Count |
|---|---:|---:|
| Naive communication-log row count | — | 30 |
| Exclude non-reportable campaigns | -4 | 26 |
| Collapse retry family 9001 → 9002 → 9003 | -3 | 23 |
| Collapse retry family 9201 → 9202 | -1 | **22** |

## Key Finding

The main issue was a difference in data grain.

`communication_log` records individual send attempts, while the
reporting definition treats customers within the same retry chain as
one reached customer.

However, standalone campaigns are treated differently: repeated
customer sends remain separate events.

Therefore, a global `COUNT(DISTINCT customer_id)` would not correctly
reproduce the Finance metric.

## Investigation

See [reconciliation/reconciliation_bridge.md](...)

## SQL

Runnable investigation and reconciliation queries are available in
the `sql/` directory.

## Data

The raw assignment data is not included in this repository.
The SQL is intended to run against the provided SQLite database.
