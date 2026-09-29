# Exercise 3 - Build multi-target neural network prediction models for an order form autocompletion use cas

In this exercise, we will create...


## Exercise - Use case scenario overview

In real SAP sales order processing, some fields are often left blank when an order is created — for example, which plant to ship from, what payment terms to use, or which shipping point to use. Filling these in correctly requires experience and takes time. If they are filled in wrong, it causes errors in downstream processes.

In this exercise, you will use a **machine learning model** that has already been trained on **1.9 million historical sales orders** stored inside SAP HANA Cloud. The model has learned the patterns from those past orders and can automatically predict the blank fields for any new order — without moving data out of HANA.

![SAP S/4HANA Sales Order App](images/SAP_S4HANA_SalesOrder_App.png)

*Example input screen of a Sales Order in SAP S/4HANA — the model predicts the blank fields automatically.*

---

__The Sales Autocompletion Linked Business Tables (aka SALT)__

The data used in this exercise comes from the **SALT** (Sales Autocompletion Linked Business Tables) dataset — a real enterprise dataset from an ERP system, designed to support machine learning research on tabular business data.

- huggingface link

![SALT Dataset](images/SALT.png)

Each record in the dataset is a SAP sales order with **27 fields** split into two groups:

| Group | Count | Examples |
|---|---|---|
| Always-known inputs | 19 | Sales org, product, sold-to party, billing country/region |
| Fields to predict | 8 | Sales office, sales group, plant, payment terms, incoterms, shipping condition, shipping point |

The model was trained on **1.9 million** past orders. The exercise tests it on **1,000 orders it has never seen before** — this is how we measure whether the model truly learned the patterns or just memorised the training data.

**Dataset reference:**

> Tassilo Klein, Clemens Biehl, Margarida Costa, Andre Sres, Jonas Kolk, Johannes Hoffart.
> *SALT: Sales Autocompletion Linked Business Tables Dataset.*
> NeurIPS 2024 Third Table Representation Learning Workshop.
> https://openreview.net/forum?id=UZbELpkWIr

<br><br>

## Start the exercise
- open the notebook file ex1_notebook.ipynb from the project explorer
<br>![](/exercises/ex3/images/26ex30-1_open_nbk.png)
<br>![](/exercises/ex3/images/26ex30-2_select_kernel.png)
<br>![](/exercises/ex0/images/26_ex0s3-5_selectkernel2.png)
- to pursue the exercise, execute the cells step by step
<br>![](/exercises/ex1/images/26ex10-4_exec_cells.png)

Open the Notebook and connect to SAP HANA Cloud
Open the file **`ex03_student.ipynb`** in Jupyter and run the cells from top to bottom.

> **No setup needed.** The `hana_ml` library is already installed. The model is already trained and stored in SAP HANA Cloud. You only need to open the notebook and run the cells.




## Ex. 3.0 - Connect to your SAP HANA Cloud instance
<br>![](/exercises/ex3/images/26ex30-outline.png)
<br>![](/exercises/ex3/images/26ex30-5_connect.png)

The first step opens a connection to SAP HANA Cloud using a saved **userkey** — a shortcut stored on this machine that holds your database address and login details. No passwords appear in the notebook.

After this cell runs you will see `Connected: True` — this means the connection is open and you are ready to work.


## Ex. 3.1 - Access and Explore the sales order data

### Step 1 — 

---

### Step 2 — Create the HANA dataframes and explore the Sales Order Data

This step creates **HANA DataFrames** — lightweight pointers to tables that already live inside SAP HANA Cloud. No data is downloaded to Python at this point. The data stays in the database.

You will work with:
- **Training set** — 1.9 million past orders, used to train the model
- **Test set** — 1,000 orders the model has never seen, used to measure accuracy

The output shows `shape: [1000, 28]` — 1,000 orders and 28 columns.


Before using the model it is good practice to understand the data first.

You will:
- **Preview a few rows** — see what a real sales order looks like
- **Count unique values per field** — fields with more unique values are harder to predict. For example, SALESOFFICE has only 4 possible values (easy), while SALESGROUP has 260 possible values (harder). You will see this difference clearly in the accuracy results.
- **Run a statistical summary** — check for nulls, min and max values, and data quality
<br><br>

## Ex. 3.2 - Train a "multi-target" classification model for sales order form autocompletion

Training a model from scratch on 1.9 million rows takes about **2.5 hours**. You do not need to wait — the model has already been trained and its learned weights are saved permanently inside SAP HANA Cloud as a regular table.

This step simply points to that saved model. No training happens here.

The model is a **Multi-Task MLP** (Multi-Layer Perceptron — a type of neural network). "Multi-Task" means it predicts all 8 missing fields at the same time in a single pass, rather than running 8 separate models. This makes it faster and lets the fields help each other during prediction.

The output shows `Model table rows: 14,864` — these are the saved neural network weights stored as rows in HANA.

| What | Detail |
|---|---|
| Model type | Multi-Task MLP (neural network) |
| Training rows | 1,900,000 |
| Input columns | 19 always-known fields |
| Fields predicted | 8 (all at the same time) |
| Training time | ~2.5 hours |
| Stored in | `SOAC_MODEL_FULL_27COL_TBL` — a column table in SAP HANA Cloud |

---

<br><br>

## Ex. 3.3 - Predict missing fields to autocomplete new sales orders
Now the model is put to work on real orders.

4 orders are taken from the test set and the 8 target fields are hidden by replacing them with a special marker called `PAL_MLP_MASK` — this tells the model: *"this field is blank — please predict it."*

The model looks at the 19 known input fields (product, customer, country, etc.) and predicts all 8 blank fields at once. Because we already know the true values for these 4 orders, we can immediately check whether the predictions are correct.

The result table shows each order, each field, the true value, the predicted value, and whether they match.
<br><br>

## Ex 3.4 - Measure prediction accuracy
4 orders gave a first impression. This step tests the model on all **1,000 orders** to get reliable accuracy numbers.

The model does not just give one answer — it gives its **top 3 guesses** ranked by confidence. Three metrics are reported:

| Metric | What it means |
|---|---|
| **Top-1** | The model's first guess is exactly correct |
| **Top-3** | The correct answer appears somewhere in the top 3 guesses |
| **MRR** | Mean Reciprocal Rank — how highly the correct answer is ranked on average (1.000 = always rank 1, perfect) |

**Example results for SALESGROUP** (the hardest field with 260 possible values):
- Top-1: **90.7%** — the model's first guess was correct for 907 out of 1,000 orders
- Top-3: **99.1%** — the correct answer was in the top 3 guesses for 991 out of 1,000 orders
- MRR: **0.949** — the correct answer is almost always the model's first guess

**Why Top-3 matters:** In a real SAP application, the user sees a dropdown with the top 3 suggestions and picks the right one. A Top-3 score of 99% means the correct answer is in the dropdown almost every time.

You will also see **confidence scores** — the model tells you how sure it is about each prediction. When confidence is high, the field can be auto-filled. When it is low, the application can ask the user to confirm.
<br><br>

## Appendix - Option
### Improve prediction latency with stateful models (optional)

The model is accurate. Now the goal is to make it **production-ready**.

**The problem with standard predict:** Every time a prediction runs, SAP HANA loads the full model from disk into memory, runs the prediction, then removes the model from memory. For a model with 14,864 rows of weights, this disk-load step takes hundreds of milliseconds — too slow for real-time order processing.

**The solution — Stateful Predict:** Load the model into HANA server memory **once**, keep it there, and reuse it for every prediction. The model stays in memory between calls, so each prediction only does the actual computation — no disk loading.

This section proves two things with real numbers:
1. **Accuracy** — stateful predict gives exactly the same results as standard predict
2. **Speed** — stateful predict is approximately **10x faster** per order

| Mode | Speed | Orders per minute |
|---|---|---|
| Standard predict | ~600 ms per order | ~100 orders/min |
| Stateful predict | ~60 ms per order | ~1,000 orders/min |

<br><br>

## Summary

In this exercise you used a machine learning model to automatically predict 8 missing fields on SAP sales orders — entirely inside SAP HANA Cloud, without moving any data to Python.

| Concept | What it means |
|---|---|
| **ML inside HANA** | The model runs where the data lives — no data export, no extra infrastructure |
| **Pre-trained model** | Training took 2.5 hours once; after that predictions take milliseconds |
| **Stateful predict** | Load the model into memory once, reuse it for every order — same accuracy, much faster |

<br><br>
---
Continue to - [Exercise 4 - Build a service ticket intelligence classification model using AutoML and raw text features](exercises/ex4/)
