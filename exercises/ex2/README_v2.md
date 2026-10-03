# Exercise 2 — Predict fraud in financial transactions using SAP-RPT-1.6

In this exercise you will use **SAP-RPT-1.6** — SAP's tabular foundation model —
to predict fraud in financial payment transactions, directly from SAP HANA Cloud.

SAP-RPT-1.6 uses **in-context learning**: you provide labelled example rows at
runtime, the model learns the pattern on the fly, and immediately predicts the
target column for new unseen rows. No model training. No deployment pipeline.

<br>

> ⚠️ **Before you start**
> Complete [Exercise 0](../ex0/README.md) first — your database connection and
> `user.ini` must be working before continuing here.

<br>

---

## What you will achieve

- Verify the SAP AI Core remote source that serves SAP-RPT-1.6 is connected
- Explore 510,000 financial transactions — only 2% are fraudulent
- Predict fraud for 51 new transactions using in-context learning (no training)
- Measure model quality: row-by-row accuracy, AUC score, and ROC curve
- Calculate a confusion matrix and overall accuracy percentage

<br>

## Use case overview

You are given a dataset of **510,000 financial payment transactions**.
10,000 of them (2%) are fraudulent. The challenge: identify which ones.

| | |
|---|---|
| **Context rows** | 1,000 labelled transactions the model learns from at runtime |
| **Predict rows** | 51 new transactions to classify as fraud or clean |
| **Target column** | `FRAUD` — `0` = clean, `1` = fraudulent |
| **Expected accuracy** | 100% — all 51 correctly classified |

<br>

---

## Start the exercise

Choose one path — both cover the same steps:

### Option A — SQL (SAP HANA Database Explorer)

- Open the **SAP HANA Database Explorer** panel in VS Code
<br>![](/exercises/ex2/images/26_ex20-open_DBX.png)

- Select your database connection from the catalog
<br>![](/exercises/ex2/images/26_ex20-DBX_connection_catalog.png)

- Right-click your connection and open a **SQL Console**
<br>![](/exercises/ex0/images/26_ex0s2-4_open_SQLconsole.png)

- Open `exercises/ex2/ex02_predict_rpt1_v2.sql` and run each step in order

### Option B — Python Notebook

- Open `ex02_notebook_v2.ipynb` from the project explorer
- Select the **.venv-DA262** kernel when prompted
- Execute the cells step by step

<br>

> ⚠️ **DBeaver users — Bind Parameters dialog**
> If you run SQL from DBeaver (not the SAP HANA Database Explorer), a
> **"Bind parameters"** dialog appears when it encounters `:variablename`
> syntax inside `DO BEGIN` blocks. Click **Ignore** every time this dialog
> appears — do not enter any values. The SQL will run correctly after clicking
> Ignore.

<br>

---

## Exercise 2.1 — Verify the remote source for SAP-RPT-1.6

SAP-RPT-1.6 is served from SAP AI Core via a **remote source** configured in
your SAP HANA Cloud instance. Verify it is connected before running predictions.

```sql
SELECT * FROM REMOTE_SOURCES;
```

<br>![](/exercises/ex2/images/26_ex21-remotesource.png)

> ✅ **Expected result:** You see a row with
> `REMOTE_SOURCE_NAME = 'DA262_AICORE_RPT16'`.
> If this row is missing, contact the workshop instructor — the remote source
> must be set up by an administrator.

<br>

---

## Exercise 2.2 — Explore the transaction data

The fraud transaction dataset is stored in the shared schema `DA262_SHARED`.

```sql
SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT,
       OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN,
       DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD
FROM DA262_SHARED.TRANSACTIONS_FRAUD
ORDER BY TRANSACTION_ID;
```

<br>![](/exercises/ex2/images/26_ex22-gxdata.png)

> ✅ **Expected result:** 510,000 rows, 10 columns.
> The `FRAUD` column contains `0` (clean) or `1` (fraudulent).
> Fraudulent transactions account for roughly 2% of the total.

<br>

---

## Exercise 2.3 — Generate predictions with SAP-RPT-1.6

SAP-RPT-1.6 takes two inputs:

| Input | Rows | Purpose |
|-------|------|---------|
| **CONTEXT** | 1,000 | Labelled rows the model learns the fraud pattern from |
| **PREDICT** | 51 | Unlabelled rows to classify |

Run the prediction block:

```sql
DO BEGIN
    DECLARE PREDICTION TABLE (
        ID               NVARCHAR(5000),
        COLUMN_NAME      NVARCHAR(5000),
        PREDICTED_VALUE  NVARCHAR(5000),
        CONFIDENCE       DOUBLE
    );

    CONTEXT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT,
                     OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN,
                     DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD
              FROM DA262_SHARED.TRANSACTIONS_FRAUD
              WHERE TRANSACTION_ID < 1000;

    PREDICT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT,
                     OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN,
                     DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST
              FROM DA262_SHARED.TRANSACTIONS_FRAUD
              WHERE TRANSACTION_ID BETWEEN 1000 AND 1050;

    CALL SYS.AI_TABULAR_PREDICTION(
        REMOTE_SOURCE_SCHEMA_NAME => NULL,
        REMOTE_SOURCE_NAME        => 'DA262_AICORE_RPT16',
        CONTEXT_TABLE             => :CONTEXT,
        PREDICT_TABLE             => :PREDICT,
        ID_COLUMN_NAME            => 'TRANSACTION_ID',
        CONFIGURATION             => '{"target_columns": [{"name": "FRAUD", "task_type": "classification"}]}',
        PREDICT_RESULTS           => :PREDICTION
    );

    SELECT * FROM :PREDICTION;
END;
```

<br>![](/exercises/ex2/images/26_ex23-predictions.png)

> ✅ **Expected result:** 51 rows — one per transaction.
> Each row shows a `PREDICTED_VALUE` (`0` or `1`) and a `CONFIDENCE` score.
> Look for **transaction 1043** — it should have `PREDICTED_VALUE = 1`
> (the only fraud in the prediction set).

<br>

---

## Exercise 2.4 — Evaluate model quality

Now measure how well the model performed. Open
`exercises/ex2/ex02_model_evaluation.sql` in your SQL console and run each
`DO BEGIN ... END` block **one at a time** in order.

> ⚠️ **DBeaver users:** Click **Ignore** when the Bind Parameters dialog appears.

<br>

### Step 1 — Row-by-row comparison

Joins actual fraud labels with predicted values so you can see each transaction
side by side.

| Column | Meaning |
|--------|---------|
| `ID` | Transaction ID |
| `CLASS` | Actual fraud label (0 or 1) |
| `PCLASS` | Predicted fraud label (0 or 1) |
| `CONFIDENCE` | Model's confidence in its prediction |

> ✅ **Expected result:** 51 rows. Every row should show `CLASS = PCLASS`
> (actual matches predicted). Transaction 1043 shows `CLASS = 1`.

<br>

### Step 2 — AUC score

AUC (Area Under Curve) measures overall model quality as a single number:

| AUC value | Meaning |
|-----------|---------|
| 0.5 | No better than random guessing |
| 0.7 – 0.9 | Good model |
| 1.0 | Perfect — model separates fraud from clean flawlessly |

> ✅ **Expected result:** `AUC = 1.0` — the model perfectly separates
> fraudulent from clean transactions on this dataset.

<br>

### Step 3 — ROC curve

The ROC curve plots the **true positive rate** (fraud correctly caught) against
the **false positive rate** (clean transactions wrongly flagged) across 20
confidence thresholds.

> ✅ **Expected result:** 20 rows — one per threshold.
> A perfect model produces a curve that immediately reaches 1.0 true positive
> rate with 0.0 false positive rate.

<br>

### Step 4a — Confusion matrix

Shows exactly how many transactions fell into each category:

| ACTUAL | PREDICTED | COUNT | Meaning |
|--------|-----------|-------|---------|
| 0 | 0 | 50 | Clean transactions correctly identified |
| 1 | 1 | 1 | Fraud correctly caught |

> ✅ **Expected result:** Only 2 rows — no false positives, no missed fraud.

<br>

### Step 4b — Overall accuracy

| TOTAL | CORRECT | WRONG | ACCURACY_PCT |
|-------|---------|-------|--------------|
| 51 | 51 | 0 | 100.00 |

> ✅ **Expected result:** `ACCURACY_PCT = 100.00` — all 51 transactions
> correctly classified.

<br>

### Step 4c — Accuracy via stored procedure _(requires admin grant)_

Step 4c calls `DA262_SHARED.CLASSIFICATION_ACCURACY` which returns the confusion
matrix, per-class precision/recall/F1, and overall accuracy in one call.

> ⚠️ If you see `SQL Error [258]: insufficient privilege` — the execute
> permission has not been granted yet. Steps 4a and 4b above give you the same
> information without needing any permission. Contact the workshop instructor
> to have the following run by an administrator:
> ```sql
> GRANT EXECUTE ON "DA262_SHARED"."CLASSIFICATION_ACCURACY" TO PUBLIC;
> ```

<br>

---

## Summary

You have now used SAP-RPT-1.6 to predict fraud in financial transactions using
in-context learning — with no model training, no deployment, and no feature
engineering.

| Done | What |
|------|------|
| ✅ | Verified AI Core remote source `DA262_AICORE_RPT16` is connected |
| ✅ | Explored 510,000 transactions from `DA262_SHARED.TRANSACTIONS_FRAUD` |
| ✅ | Generated fraud predictions for 51 transactions — transaction 1043 flagged |
| ✅ | AUC = 1.0 — perfect model score on this dataset |
| ✅ | Confusion matrix: 50 clean + 1 fraud, all correct |
| ✅ | Accuracy: 51 / 51 = 100% |

Continue to — [Exercise 3 - Build multi-target neural network prediction models
for an order form autocompletion use case](../ex3/README.md)
