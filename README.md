1. Overview = 
This repository contains my solutions to the SQL Technical Assessment.
The goal of the exercise was to demonstrate SQL proficiency, analytical thinking, and ability to work with realistic datasets.
The file submission.sql includes all SQL answers for Questions 1 to 8.

2. Assumptions Made =
Based on the dataset snapshot shared:
| Column                  | Description                                     |
| ----------------------- | ----------------------------------------------- |
| buyer_id                | Unique identifier of the buyer                  |
| purchase_time           | Timestamp of purchase                           |
| refund_time             | Timestamp of refund (NULL if not refunded)      |
| store_id                | Store where the purchase was made               |
| item_id                 | Item associated with the transaction            |
| gross_transaction_value | Stored as a string containing `$` (e.g., "$58") |

| Column        | Description              |
| ------------- | ------------------------ |
| store_id      | Store identifier         |
| item_id       | Item identifier          |
| item_category | Category of the product  |
| item_name     | Human-readable item name |

General Logic Assumptions

A refund is considered valid only when refund_time IS NOT NULL.
Refund eligibility: refund_time - purchase_time ≤ 72 hours.
“First purchase” = earliest purchase_time for each buyer.
“First order per store” = earliest purchase_time for each store.
gross_transaction_value requires cleaning ($ removed) before numeric operations.



3. Approach Summary (per Question)= Execution Results (Based on Provided Dataset Snapshot)

Below are sample outputs obtained after running the SQL queries on the dataset.
Your actual results may vary depending on the full dataset in your environment.
Q1 — Monthly purchases (excluding refunds)


| Month   | Purchases Count |
| ------- | --------------- |
| 2019-09 | 2               |
| 2020-04 | 2               |
| 2020-09 | 1               |
| 2020-10 | 1               |

Count rows where refund_time IS NULL
Group by month using DATE_TRUNC

Q2 — Stores with ≥5 orders in October 2020

| Metric                | Value |
| --------------------- | ----- |
| stores_with_5_or_more | **0** |

Filter purchases between 2020-10-01 and 2020-11-01
Group by store
Apply HAVING COUNT(*) >= 5

Q3 — Shortest refund interval per store

| Store | Shortest Interval (min) |
| ----- | ----------------------- |
| b     | 7320.79                 |
| f     | 1262.33                 |
| g     | 3625.45                 |

Compute time difference between purchase_time and refund_time
Convert seconds → minutes
Take MIN() interval per store

Q4 — First order per store
| Store | Item ID | Purchase Time       | Gross Value |
| ----- | ------- | ------------------- | ----------- |
| a     | a1      | 2019-09-19 21:19:06 | 58          |
| b     | b2      | 2019-12-10 20:10:14 | 475         |
| d     | d3      | 2020-04-30 21:19:06 | 250         |
| e     | e7      | 2020-04-16 21:10:22 | 24          |
| f     | f9      | 2020-09-01 23:59:46 | 33          |
| g     | g6      | 2019-09-23 12:09:35 | 61          |

Use ROW_NUMBER() window function
Clean $ from gross_transaction_value
Return gross value of the earliest order

Q5 — Most popular first-purchase item

| Most Popular Item Name |
| ---------------------- |
| **denim pants**        |

Identify each buyer’s first purchase
Join with items table to get item_name
Count frequency → return most popular item

Q6 — Refund processable flag
| Buyer | Purchase Time | Refund Time | Processable? |
| ----- | ------------- | ----------- | ------------ |
| 12    | 2019-12-10    | 2019-12-15  | ❌ No         |
| 3     | 2020-09-01    | 2020-09-02  | ✅ Yes        |
| 5     | 2019-09-23    | 2019-09-27  | ❌ No         |
Refund is processable only if within 72 hours
Add boolean field refund_processable

Q7 — Return only second purchase per buyer (ignore refunds)
| Buyer ID | Second Purchase Time | Store | Item |
| -------- | -------------------- | ----- | ---- |
| **3**    | 2020-10-05           | a     | a2   |

Filter out refunded transactions
Use ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY purchase_time)
Select where rank = 2

Q8 — Second transaction time per buyer (without min/max)
| Buyer ID | Second Transaction Time                        |
| -------- | ---------------------------------------------- |
| 3        | 2019-09-23                                     |
| 8        | — *(only 1 transaction)*                       |
| 12       | — *(refund row counted separately if present)* |
| 2        | — *(only 1 transaction)*                       |

Use window function ROW_NUMBER
Select rn = 2 for each buyer

5. How to Execute

Load transactions and items tables into your SQL engine.
Run each SQL block from submission.sql in order.
Validate outputs against your local environment.
Include screenshots of executed queries (as requested in the test instructions).

6. Final Notes

All solutions follow best SQL practices (window functions, clean grouping logic, proper filtering).
No external data sources were used.
Queries were designed based on the dataset snapshot and problem constraints.
