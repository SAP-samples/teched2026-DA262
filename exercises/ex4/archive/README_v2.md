# Exercise 4 — Classify travel service tickets using AutoML and text embeddings

In this exercise you will build a classifier that automatically categorises
travel service tickets into **complaint**, **compliment**, or **request** —
using raw ticket text as the only input feature.

SAP HANA Cloud embeds the text internally using a SAP NLP model. AutoML then
searches for the best classification pipeline automatically. No manual feature
engineering, no separate NLP service.

<br>

> ⚠️ **Before you start**
> Complete [Exercise 0](../ex0/README.md) first — your `user.ini` must be
> configured and the Python connection must return `True`.

<br>

> ⚠️ **Connection fix required before running the notebook**
> The notebook `teched2026_DA262_ex4_STI.ipynb` was originally developed with
> an instructor configuration file. Before running it as a student, find the
> connection cell at the top of the notebook and replace:
> ```python
> # REMOVE this line:
> Settings.load_config("../../config/e2edata.ini")
> ```
> with:
> ```python
> # ADD this line instead:
> %run "../ex0/ex0_connect2HANACloud.ipynb"
> ```
> Save the notebook after making this change, then run it from the top.

<br>

---

## What you will achieve

- Explore 3,780 travel service tickets and check the class distribution
- Train an AutoML classification model using raw ticket text as the only feature
- Evaluate the model: accuracy, AUC, and per-class F1 scores
- Predict the category of new, unseen tickets

<br>

## Use case overview

You are given **3,780 travel service tickets**, each with a free-text description
written by the customer and a category label.

| Category | Count | Example |
|----------|-------|---------|
| complaint | 1,327 | *"how can a morning flight already be delayed 40 minutes?"* |
| request | 1,280 | *"Can I change my seat assignment online before check-in?"* |
| compliment | 1,173 | *"The crew was absolutely wonderful, made the whole trip special"* |
| **Total** | **3,780** | |

The classes are roughly balanced — no special handling needed.

The only input to the model is the `Description` column — the raw text.
SAP HANA Cloud converts it to a numeric vector internally. You never need
to write a single line of text preprocessing.

<br>

![](/exercises/ex4/images/26ex40-outline.png)

<br>

---

## Start the exercise

- Open the notebook `teched2026_DA262_ex4_STI.ipynb` from the project explorer
<br>![](/exercises/ex4/images/26ex40-1_open_nbk.png)

- Select the **.venv-DA262** kernel when prompted
<br>![](/exercises/ex4/images/26ex40-2_select_kernel.png)
<br>![](/exercises/ex0/images/26_ex0s3-5_selectkernel2.png)

- Execute the cells step by step using the play icon next to each cell
<br>![](/exercises/ex1/images/26ex10-4_exec_cells.png)

<br>

---

## Ex. 4.0 — Connect to your SAP HANA Cloud instance

The first cells connect to SAP HANA Cloud using your `user.ini` credentials
and print the confirmed connection details.
<br>![](/exercises/ex4/images/26ex40-5_connect.png)

> ✅ **Expected result:** `Connection to SAP HANA Cloud successful is: True`
> and the current timestamp from the database.
> If you see an error here, check that you made the connection fix described
> at the top of this page.

<br>

---

## Exercise 4.1 — Explore the travel service ticket data

The dataset `travel.csv` is loaded into SAP HANA Cloud. It has two columns:

| Column | Content |
|--------|---------|
| `Description` | Free-text ticket written by the customer |
| `Category` | The label: complaint, compliment, or request |

Run the cells to load the data and inspect the class distribution.

> ✅ **Expected result:** A bar chart or count table showing:
>
> | Category | Count |
> |----------|-------|
> | complaint | 1,327 |
> | request | 1,280 |
> | compliment | 1,173 |
> | **Total** | **3,780** |
>
> The classes are roughly equal — this is a well-balanced dataset.

<br>

---

## Exercise 4.2 — Build an AutoML classification model

The data is split into **3,213 training rows (85%)** and **567 test rows (15%)**
using stratified sampling — each split keeps the same class proportions.

The only feature column passed to the model is `Description` — the raw text.

### What AutoML does

AutoML evaluates combinations of text transformers and classifiers automatically:

| Component | Options tried |
|-----------|--------------|
| Text transformer | TextEmbedding (SAP_GXY.20250407) · TFIDF |
| Classifier | HGBT (Gradient Boosting) · MLP (Neural Network) · RDT (Random Forest) |

AutoML searches across these combinations using a genetic algorithm over
**3 generations, 25 pipelines**. It keeps the best-performing one.

> ⏳ **Training takes approximately 100 seconds** — this is normal.
> You will see progress output as each pipeline is evaluated.

> ✅ **Expected result after training:**
> Best pipeline found: **TextEmbedding → HGBT Classifier**
> The TextEmbedding transformer (SAP_GXY.20250407) converts each ticket
> description into a vector of numbers that captures the meaning of the text.
> HGBT (Gradient Boosting Trees) then classifies based on those vectors.

<br>

---

## Exercise 4.3 — Evaluate the AutoML model accuracy

Apply the trained model to the 567-row hold-out test set and review the results.

> ✅ **Expected results:**
>
> | Metric | Value | Meaning |
> |--------|-------|---------|
> | **Accuracy** | **92.1%** | 9 out of 10 tickets correctly classified |
> | **AUC** | **0.985** | Near-perfect separation between classes |
> | F1 — complaint | 0.888 | |
> | F1 — compliment | 0.902 | |
> | F1 — request | 0.970 | |
>
> The model correctly classifies over 9 out of 10 tickets from raw text alone.
> The `request` category scores highest (0.970) — requests tend to use more
> distinct vocabulary than complaints and compliments.

<br>

---

## Exercise 4.4 — Predict with the AutoML model

Apply the trained model to new tickets using the `predict()` method.
The result shows the predicted category and confidence score for each ticket.

> ✅ **Expected result:** A prediction table with one row per ticket:
>
> | Ticket ID | Predicted Category | Confidence |
> |-----------|--------------------|------------|
> | 1008 | complaint | 0.999 |
> | 1011 | complaint | 1.000 |
> | 1014 | request | — |
> | 1016 | complaint | 0.999 |
>
> High confidence (close to 1.0) means the model is very certain.
> A lower confidence means the ticket could belong to more than one category.

<br>

---

## Summary

You have now built a travel service ticket classifier using AutoML with raw
text input — entirely inside SAP HANA Cloud.

| Done | What |
|------|------|
| ✅ | Explored 3,780 tickets across 3 balanced categories |
| ✅ | Trained AutoML — best pipeline: TextEmbedding → HGBT |
| ✅ | Evaluated on 567 unseen tickets: 92.1% accuracy, AUC 0.985 |
| ✅ | Predicted categories for new tickets with confidence scores |

SAP HANA Cloud handled the text embedding internally, AutoML found the best
pipeline automatically, and the model achieved **92.1% accuracy** — without
leaving the database or writing a single line of feature engineering code.

<br><br>

---
Congratulations — you have completed all exercises!

## Further reading
The appendix section of the notebook includes additional expert-level details
and references to the data and models used in this exercise.
