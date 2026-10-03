# Exercise 1 — Generate time series forecasts on-the-fly using SAP-RPT-TS

In this exercise you will use **SAP-RPT-TS** — SAP's time series foundation model —
to generate bike sales forecasts directly inside SAP HANA Cloud.

No model training, no separate service. You give it historical sales data and it
immediately produces a forecast with prediction intervals — this is called
**zero-shot forecasting**.

<br>

> ⚠️ **Before you start**
> Complete [Exercise 0](../ex0/README.md) first — your `user.ini` file must be
> configured and the Python connection must return `True` before continuing here.

<br>

> ℹ️ **Notebook file**
> This exercise uses the notebook `ex1_notebook.ipynb`. Confirm the file is
> present in your `exercises/ex1/` folder before opening it.

<br>

---

## What you will achieve

- Load the Bike Sharing sales dataset from SAP HANA Cloud into a Python dataframe
- Visualise sales trends for individual stores using line charts
- Forecast 48 days of future sales for a single store with 90% prediction intervals
- Forecast all stores simultaneously in one call using the Massive Pipeline

<br>

## The key idea — zero-shot forecasting

A traditional forecasting model needs weeks of data preparation and training before
it can predict anything. SAP-RPT-TS works differently:

1. You pass it a table of historical sales figures
2. It reads the pattern — trend, seasonality, spikes
3. It immediately returns a forecast — no training step, no waiting

The model runs **entirely inside SAP HANA Cloud**. Your data never leaves the database.

<br>

![](/exercises/ex1/images/26_ex1_overview.png)

<br>

---

## Start the exercise

- Open the notebook file `ex1_notebook.ipynb` from the project explorer
<br>![](/exercises/ex1/images/26ex10-1_open_nbk.png)

- When prompted to select a kernel, choose **.venv-DA262**
<br>![](/exercises/ex1/images/26ex10-2_select_kernel.png)
<br>![](/exercises/ex0/images/26_ex0s3-5_selectkernel2.png)

- Execute the cells step by step using the play icon next to each cell
<br>![](/exercises/ex1/images/26ex10-4_exec_cells.png)

<br>

---

## Ex. 1.0 — Connect to your SAP HANA Cloud instance

The first cell connects to SAP HANA Cloud using your `user.ini` credentials and
prints confirmation that the connection is active.
<br>![](/exercises/ex1/images/26ex10-outline.png)
<br>![](/exercises/ex1/images/26ex10-5_connect.png)

> ✅ **Expected result:** `Connection to SAP HANA Cloud successful is: True`
> and a current timestamp from the database.

<br>

---

## Exercise 1.1 — Explore the Bike Sharing time series data

The dataset `DA262_SHARED.BIKESHARING` contains weekly sales figures for multiple
stores. Each row has three columns: **Date**, **Sales**, and **Store**.
<br>![](/exercises/ex1/images/26ex11-outline.png)

### Step 1 — Load the data

Run the cell to load the dataset into a HANA dataframe and print its shape.
<br>![](/exercises/ex1/images/26ex11-s1-1-hdf.png)

> ✅ **Expected result:** The dataframe prints its row count and column names
> (`Date`, `Sales`, `Store`). No data has moved to Python yet — a HANA dataframe
> is just a pointer to the table inside the database.

<br>

### Step 2 — Visualise sales patterns

The code below plots weekly sales over time for two stores:

```python
hdf_data_plot = data_hdf.select('Sales', 'Date', 'Store').sort('Date')
import plotly.express as px
fig = px.line(hdf_data_plot.filter('"Store" in (\'84\')').collect(),
              x='Date', y='Sales', title='Sales by Store')
fig.show()
fig = px.line(hdf_data_plot.filter('"Store" in (\'53\')').collect(),
              x='Date', y='Sales', title='Sales by Store')
fig.show()
```

<br>![](/exercises/ex1/images/26ex11-s2-1-explore.png)
<br>![](/exercises/ex1/images/26ex11-1_ts_data.png)

> ✅ **Expected result:** Two interactive line charts appear — one for Store 84
> and one for Store 53. You can see the seasonal pattern in the sales data.

<br>

---

## Exercise 1.2 — Forecast with SAP-RPT-TS (single store)

Use the `Pipeline` class to run SAP-RPT-TS on Store 84's sales history.
The model produces a **48-day forecast** (the next 48 time periods after the
last date in the data) together with a 90% prediction interval — a lower and
upper bound that the true value should fall within 90% of the time.
<br>![](/exercises/ex1/images/26ex12-outline.png)

### Step 1 — Configure and run the forecast

```python
from hana_ml.algorithms.pal.pipeline import Pipeline

pipe = Pipeline(pipeline={"TSFM": {"args": {
                    "BATCH_SIZE": [128],
                    "OUTPUT_QUANTILE": 0,
                    "POINT_FORECAST": ["median"],
                    "CLIP_MIN": 0,
                    "CLIP_MAX": 999999,
                    "FORECAST_LENGTH": 48},
                "inputs": {"data": "ROWDATA"}}})

result = pipe.predict(
    data_hdf.filter('"Store" in (\'84\')').select('DATE', 'Sales'),
    key='DATE',
    output_prediction_interval=True,
    confidence_level=0.9)
```

**Key parameters explained:**

| Parameter | Value | What it means |
|-----------|-------|---------------|
| `FORECAST_LENGTH` | 48 | Forecast the next 48 time periods |
| `POINT_FORECAST` | `"median"` | Use the median as the central forecast value |
| `CLIP_MIN` | 0 | Never predict negative sales |
| `confidence_level` | 0.9 | 90% prediction interval — upper and lower bounds |

> ✅ **Expected result:** `result` is a HANA dataframe with 48 rows — one per
> forecast period. Columns include the forecast date, the predicted value, and
> the lower and upper bounds of the prediction interval.

<br>

---

## Exercise 1.3 — Forecast all stores at once with SAP-RPT-TS

Use the `MassivePipeline` class to forecast **every store in parallel** in a
single call. This is the production pattern when you have many time series to
forecast simultaneously.
<br>![](/exercises/ex1/images/26ex13-outline.png)

### Step 1 — Run the massive forecast

```python
from hana_ml.algorithms.pal.massive_pipeline import MassivePipeline

mpipe = MassivePipeline(pipeline={"TSFM": {"args": {
                            "BATCH_SIZE": [128],
                            "OUTPUT_QUANTILE": 0,
                            "POINT_FORECAST": ["median"],
                            "CLIP_MIN": 0,
                            "CLIP_MAX": 30000},
                        "inputs": {"data": "ROWDATA"}}})

result = mpipe.predict(
    predall_imputet,
    group_key='Store',
    key='DATE',
    output_prediction_interval=True,
    confidence_level=0.9)

result.collect()
```

**The difference from Exercise 1.2:**

| | Pipeline (Ex 1.2) | MassivePipeline (Ex 1.3) |
|---|---|---|
| Stores | 1 (Store 84 only) | All stores at once |
| `group_key` | Not used | `'Store'` — splits data by store |
| Result rows | 48 | 48 × number of stores |

> ✅ **Expected result:** The result table contains forecasts for every store,
> each with 48 forecast periods. The `group_key='Store'` column identifies which
> store each row belongs to.
> <br>![](/exercises/ex1/images/26ex13-1_forecast_result.png)

<br>

---

## Summary

You have now used SAP-RPT-TS to generate bike sales forecasts directly from
SAP HANA Cloud — with no model training and no external service.

| Done | What |
|------|------|
| ✅ | Loaded and visualised the Bike Sharing time series data |
| ✅ | Forecast 48 days of sales for Store 84 with 90% prediction intervals |
| ✅ | Forecast all stores simultaneously using MassivePipeline |

The same foundation model handled both a single-store forecast and a
parallel forecast across all stores in one call.

Continue to — [Exercise 2 - Predict fraud in financial transactions using
SAP-RPT-1.6 from SAP AI Core](../ex2/README.md)
