

```

WITH RECURSIVE
eligible_campaigns AS (
 SELECT id
 FROM campaign
 WHERE creation_status = 'approved'
 AND processing_status = 'processed'
),
campaign_tree AS (
 SELECT id AS campaign_id, id AS root_id
 FROM campaign
 WHERE parent_id IS NULL
 UNION ALL
 SELECT c.id, t.root_id
 FROM campaign c
 JOIN campaign_tree t
 ON c.parent_id = t.campaign_id
),
scoped_logs AS (
 SELECT cl.*, t.root_id
 FROM communication_log cl
 JOIN eligible_campaigns ec ON ec.id = cl.communication_id
 JOIN campaign_tree t ON t.campaign_id = cl.communication_id
 WHERE cl.merchant_id = 501
 AND cl.communication_type = '2'
 AND cl.sent_time >= '2026-10-01'
 AND cl.sent_time < '2026-11-01'
),
standalone_roots AS (
 SELECT c.id
 FROM campaign c
 WHERE c.parent_id IS NULL
 AND NOT EXISTS (
 SELECT 1 FROM campaign child
 WHERE child.parent_id = c.id
 )
),
standalone_count AS (
 SELECT COUNT(*) AS n
 FROM scoped_logs s
 JOIN standalone_roots r ON r.id = s.root_id
),
retry_count AS (
 SELECT COUNT(*) AS n
 FROM (
 SELECT DISTINCT root_id, customer_id
 FROM scoped_logs
 WHERE root_id NOT IN (SELECT id FROM standalone_roots)
 )
)
SELECT
 (SELECT n FROM standalone_count) +
 (SELECT n FROM retry_count) AS target_base;

```
