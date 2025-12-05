Solution to the Query 1 : Purchases per month (exclude refunded)
SELECT
    DATE_TRUNC('month', purchase_time) AS month,
    COUNT(*) AS purchases_count
FROM transactions
WHERE refund_time IS NULL
GROUP BY 1
ORDER BY 1;
| Month   | Purchases Count |
| ------- | --------------- |
| 2019-09 | 2               |
| 2020-04 | 2               |
| 2020-09 | 1               |
| 2020-10 | 1               |





Solution to the query 2 :How many stores have ≥5 transactions in Oct 2020?
SELECT COUNT(*) AS stores_with_5_or_more
FROM (
    SELECT store_id, COUNT(*) AS tx_count
    FROM transactions
    WHERE purchase_time >= '2020-10-01'
      AND purchase_time <  '2020-11-01'
    GROUP BY store_id
    HAVING COUNT(*) >= 5
) t;

| Metric                | Value |
| --------------------- | ----- |
| stores_with_5_or_more | **0** |





Solution to the query 3: Shortest interval (minutes) from purchase → refund
SELECT
    store_id,
    MIN(EXTRACT(EPOCH FROM (refund_time - purchase_time)) / 60) AS shortest_refund_minutes
FROM transactions
WHERE refund_time IS NOT NULL
GROUP BY store_id
ORDER BY store_id;

| Store | Shortest Interval (min) |
| ----- | ----------------------- |
| b     | 7320.79                 |
| f     | 1262.33                 |
| g     | 3625.45                 |





Solution to the query 4 : Gross value of FIRST order per store
WITH parsed AS (
  SELECT *,
         NULLIF(regexp_replace(gross_transaction_value, '[^0-9.]', '', 'g'), '')::numeric AS gross_val
  FROM transactions
),
first_per_store AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY purchase_time) AS rn
  FROM parsed
)
SELECT store_id, item_id, purchase_time, gross_val AS gross_transaction_value
FROM first_per_store
WHERE rn = 1
ORDER BY store_id;
| Store | Item ID | Purchase Time       | Gross Value |
| ----- | ------- | ------------------- | ----------- |
| a     | a1      | 2019-09-19 21:19:06 | 58          |
| b     | b2      | 2019-12-10 20:10:14 | 475         |
| d     | d3      | 2020-04-30 21:19:06 | 250         |
| e     | e7      | 2020-04-16 21:10:22 | 24          |
| f     | f9      | 2020-09-01 23:59:46 | 33          |
| g     | g6      | 2019-09-23 12:09:35 | 61          |






Solution to the query 5 :  Most popular item on FIRST purchase for buyers
WITH first_tx AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions
)
SELECT it.item_name
FROM first_tx f
JOIN items it USING (store_id, item_id)
WHERE rn = 1
GROUP BY it.item_name
ORDER BY COUNT(*) DESC
LIMIT 1;

| Most Popular Item Name |
| ---------------------- |
| **denim pants**        |







Solution to the query 6 : Refund processable flag (within 72 hours)
SELECT
    buyer_id,
    purchase_time,
    refund_time,
    store_id,
    item_id,
    gross_transaction_value,
    CASE
        WHEN refund_time IS NULL THEN FALSE
        WHEN EXTRACT(EPOCH FROM (refund_time - purchase_time)) <= 72*3600
             THEN TRUE
        ELSE FALSE
    END AS refund_processable
FROM transactions;
| Buyer | Purchase Time | Refund Time | Processable? |
| ----- | ------------- | ----------- | ------------ |
| 12    | 2019-12-10    | 2019-12-15  |  No         |
| 3     | 2020-09-01    | 2020-09-02  |  Yes        |
| 5     | 2019-09-23    | 2019-09-27  |  No         |
--Only 1 refund was processable (within 72 hours)






Solution to the query 7 : Only SECOND purchase per buyer (ignore refunds)
WITH purchases AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS purchase_rank
    FROM transactions
    WHERE refund_time IS NULL
)
SELECT buyer_id, purchase_time, store_id, item_id, gross_transaction_value
FROM purchases
WHERE purchase_rank = 2
ORDER BY buyer_id;
| Buyer ID | Second Purchase Time | Store | Item |
| -------- | -------------------- | ----- | ---- |
| **3**    | 2020-10-05           | a     | a2   |
--Expected Output Correct: Only buyer_id 3 has a valid second purchase.






Solution to the query 8 : Second transaction time per buyer
WITH ranked AS (
    SELECT buyer_id,
           purchase_time,
           ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time) AS rn
    FROM transactions
)
SELECT buyer_id, purchase_time AS second_transaction_time
FROM ranked
WHERE rn = 2
ORDER BY buyer_id;
| Buyer ID | Second Transaction Time                        |
| -------- | ---------------------------------------------- |
| 3        | 2019-09-23                                     |
| 8        | — *(only 1 transaction)*                       |
| 12       | — *(refund row counted separately if present)* |
| 2        | — *(only 1 transaction)*                       |
(Only buyers with ≥2 transactions appear in final output.)

