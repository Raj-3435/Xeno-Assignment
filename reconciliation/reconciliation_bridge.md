# Reconciliation Bridge

## Scope

Merchant 501, October 2026, communication_type = '2'.

---

## Step 0 — Naive count

### Query
```
SELECT COUNT(*) AS naive_count
FROM communication_log
WHERE merchant_id = 501
  AND communication_type = '2'
  AND sent_time >= '2026-10-01'
  AND sent_time < '2026-11-01';
```
Screenshot:

<img width="346" height="134" alt="image" src="https://github.com/user-attachments/assets/a508d4c0-16e8-489b-a476-5b0563d54717" />

### Result

30

### Why this does not reconcile

This counts every communication_log row as an independent send
attempt.

Finance reports a target_base of 22, so further investigation was
required.

---

## Step 1 — Campaign reporting eligibility

### Investigation

I joined communication_log to campaign and applied the reporting
eligibility rules.

### Query

```
SELECT COUNT(*) AS eligible_sends
FROM communication_log cl
JOIN campaign c
    ON cl.communication_id = c.id
WHERE cl.merchant_id = 501
  AND cl.communication_type = '2'
  AND cl.sent_time >= '2026-10-01'
  AND cl.sent_time < '2026-11-01'
  AND c.creation_status = 'approved'
  AND c.processing_status = 'processed';
```
Screenshot:

<img width="399" height="233" alt="image" src="https://github.com/user-attachments/assets/71565f52-2744-4ad0-a15e-7580bcbea495" />

### Result

26

### Adjustment

30 → 26 (-4)

### Reason

Campaign 9004 has four communication_log rows but has
creation_status = 'approval_awaiting'. It therefore does not qualify
for official reporting.

---

## Step 2 — Retry family 9001 → 9002 → 9003

### Investigation

Campaigns 9002 and 9003 are retries in the same underlying
communication chain.

The chain contains 13 send attempts but only 10 distinct customers.

```
SELECT
    cl.communication_id,
    cl.customer_id,
    cl.delivery_status,
    cl.sent_time
FROM communication_log cl
WHERE cl.communication_id IN (9001, 9002, 9003)
ORDER BY cl.customer_id, cl.sent_time;
```

Screenshot:

<img width="490" height="336" alt="image" src="https://github.com/user-attachments/assets/fd8326ea-6cff-41c0-8b9d-13202e897f2f" />


### Result

26 → 23 (-3)

### Reason

A customer appearing multiple times within the same retry chain counts
once.

---

## Step 3 — Retry family 9201 → 9202

### Investigation

9202 is a retry of 9201.

There are 6 send attempts but only 5 distinct customers.
```
SELECT
    cl.communication_id,
    cl.customer_id,
    cl.delivery_status,
    cl.sent_time
FROM communication_log cl
WHERE cl.communication_id IN (9201, 9202)
ORDER BY cl.customer_id, cl.sent_time;
```
Screenshot:

<img width="424" height="234" alt="image" src="https://github.com/user-attachments/assets/a2e9ee47-7a57-407e-b7cf-f7155b1322cd" />


### Result

23 → 22 (-1)

---

## Final reconciliation

30 - 4 - 3 - 1 = 22

Therefore:

**target_base = 22**
