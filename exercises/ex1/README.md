# Exercise 1 - Generate time series forecasts on-the-fly using using SAP-RPT-TS from SAP HANA Cloud

In this exercise you will use **SAP-RPT-TS** — SAP's new __tabular AI foundation model__ specifically targeted for __time series forecasting__ —
to generate bike sales forecasts directly inside SAP HANA Cloud.

**SAP-RPT-TS** is a Relational Pre-trained Transformer model, developed and maintained by SAP, and extends the RPT family from static tabular data to temporal, sequential data.
- It aims to achieve the highest forecast quality and lowest error rates for predictions on business time series data such as demand, sales, and operational metrics. 
- It uses in-context learning to solve forecasting tasks out-of-the-box — with a target series' recent history provided as input, optionally alongside related series of covariates, and the model returns the forecast directly, without any training, parameter selection or fine-tuning. 
- Forecasts are expressed as full predictive distributions rather than single point estimates, SAP-RPT-TS quantifies uncertainty out-of-the-box. Due to its time-series-native architecture, prediction quality on enterprise data is typically very high, mostly ahead of state-of-the-art narrow AI forecast models for such tasks.

SAP-RPT-TS key features include:
- **Pretrained Model**: Removes the need to collect training datasets, manage compute infrastructure, or wait weeks for model training cycles. Deploy immediately with production-ready accuracy across any forecast horizon.
- **Fast and Lightweight**: A compact, efficient architecture delivers low-latency forecasts and runs comfortably on standard CPUs, making it cost-effective to consume and scale across many time series.
- **In-Context Learning**: Accepts a series' recent history at inference time to return instant forecasts, without setup or per-series model building.
- **Flexible Data Structures**: Handles time series of different shapes — univariate and multivariate series, multiple targets, and both past and known-future covariates — letting you incorporate related series and external drivers to improve accuracy wherever related data is available.
- **Probabilistic and Grounded**: Produces forecasts grounded in the provided history, returning calibrated prediction intervals — not just point estimates — reducing the risk of costly over- or under-prediction decisions.
- **Available In-Database or AI Core**: The model can flexibly be consumed directly within SAP HANA Cloud, co-located to application business data or can be consumed vis SAP AI Core.

<br>

In this exercise, we will consume SAP-RPT-TS directly from within SAP HANA Cloud
- to access and consume the model, the HANA Cloud instance configuration requires to have the __NLP services__  enabled
- with the 2026 Q3 HANA Cloud release, usage of SAP-RPT-TS is unlocked with the [**TSFM operator** for PAL **AutoML / Pipeline models**](https://help.sap.com/docs/hana-cloud-database/sap-hana-cloud-sap-hana-database-predictive-analysis-library/tsfm) ([TSFM in hana_ml 2.30](https://help.sap.com/doc/cd94b08fe2e041c2ba778374572ddba9/2026_3_QRC/en-US/pal/topics/pipeline_operator_tsfm.html))
  - **TSFM** is a pipeline operator node for __zero-shot time series forecasting__. It joins the PAL Pipeline framework alongside classic time-series operators (ARIMA, BSTS, AMTSA, HGBT-TS, MLR-TS, …) and can be selected by AutoML or invoked directly from Pipeline SQL functions.
- __Zero-shot time series forecasting__ implies here 
  - **No model training step**, if used `PAL_PIPELINE_FIT` snapshots the historical `[ID, TARGET, COV...]` table into the model. No gradient   descent, no epochs.
  - **All actual inference happens at predict time.** `PAL_PIPELINE_PREDICT`   produces the forecast from the snapshot + future-covariate context.
  - A **skip-fit mode** lets you do both in a single SQL call: pass an empty   model table plus a unified `[ID, TARGET (NULL for future rows), COV...]`   table; the operator infers in one round trip.


## Exercise - Use case scenario overview

In this exercise, you will explore how to apply SAP-RPT-TS to generate bike sales forecast predictions in SAP HANA Cloud

![](/exercises/ex1/images/ex1_scenario_overview.png)
- You will explore and familiarize with the Bike Sharing data using HANA dataframes and time series visualizations
- Next you apply SAP-RPT-TS using Pipeline skip-fit functions for direct forecasts with and without covariate data and review the forecast accuracy. 
- You apply the massive pipeline functions to generate zero-shot forecasts using SAP-RPT-TS for multiple Bike Sharing subsidiaries in parallel

  
<br>

**Use case dataset reference:**

Fanaee-T, H. (2013). Bike Sharing [Dataset](https://archive.ics.uci.edu/dataset/275/bike+sharing+dataset). UCI Machine Learning Repository. https://doi.org/10.24432/C5W894.<br>

<br>

## Start the exercise
- Open the notebook file __ex01_notebook.ipynb__ from the project explorer
<br>![](/exercises/ex1/images/26ex10-1_open_nbk.png) 

<br>  

- Select the Python Kernel
<br>![](/exercises/ex1/images/26ex10-2_select_kernel.png)

<br>  

- Select the prepared __.venv-DA262__ Python Kernel
<br>![](/exercises/ex0/images/26_ex0s3-5_selectkernel2.png)

<br>  

- Next, to pursue the exercise, execute the cells step by step, by clicking the __run cell-icon ">"__ as highlighted
<br>![](/exercises/ex1/images/26ex10-4_exec_cells.png)

Proceed through the exercise sections and run the cells from top to bottom.

<br> <br> 

The following exercise descriptions, just give a high-level exercise overview, all the instructions and explanations are part of the notebook file __ex01_notebook.ipynb__ itself.


<br> 

## Ex. 1.0 - Connect to your SAP HANA Cloud instance
- The outline-view on the lower left in Visual Studio code, overviews the exercise sections and steps 
<br>![](/exercises/ex1/images/26ex10-outline.png)

- In __Step 0__ you first create the connection to SAP HANA Cloud, and shows successful message like
<br>![](/exercises/ex1/images/26ex10-5_connect.png)

## Exercise 1.1 Explore the Bike Sharing time series data
- Steps in this exercise section 
<br>![](/exercises/ex1/images/26ex11-outline.png)

- In __Step 1__ you will create a HANA dataframe against the preloaded tables
<br>![](/exercises/ex1/images/26ex11-s1-1-hdf.png)

  and review bike sharing dataset column details using the **describe-method**
  <br>![](/exercises/ex1/images/26ex11-s1-2-describe.png)

<br>

- In __Step 2__ you will plot the time series data over time to get a first visual impression of the data and its overall trend and seasonalities
<br>![](/exercises/ex1/images/26ex11-1_ts_data.png)


<br><br>

## Exercise 1.2 Forecast with "SAP-RPT-TS"
- Steps in this exercise section 
<br>![](/exercises/ex1/images/26ex12-outline.png)

<br>

- In __Step 3__ you will create a first forecast prediction of the hourly bike count data using SAP-RPT-TS without any covariates
  - The columns passed in to forecast model includes only DATE_HOUR and CNT
  - TSFM incl. some parameter we may adjust like min and max value cutoffs wanted for the forecast (CLIP_MIN / CLIP_MAX) and most important how many hours do we want to forecast, here it is 2 weeks so a FORECAST_LENGTH of 336

Key parameters explained:
| Parameter | Value | What it means |
|-----------|-------|---------------|
| `FORECAST_LENGTH` | 336 | Forecast the next 336 time periods |
| `POINT_FORECAST` | `"median"` | Use the median as the central forecast value |
| `CLIP_MIN` | 0 | Never predict negative CNT value |
| `confidence_level` | 0.9 | 90% prediction interval — upper and lower bounds |

<br>

Python hana_ml code example would look like
```python
from hana_ml.algorithms.pal.pipeline import Pipeline
pipe = Pipeline(pipeline={"TSFM": {"args": {"BATCH_SIZE": [128], "OUTPUT_QUANTILE": 0, "POINT_FORECAST": ["median"], "CLIP_MIN": 0, "CLIP_MAX": 1500, "FORECAST_LENGTH": 336}, "inputs": {"data": "ROWDATA"}}})

result = pipe.predict(bike_hist_hdf.select('DATE_HOUR', 'CNT'),
                      key='DATE_HOUR', 
                      output_prediction_interval=True, confidence_level=0.9)
```
- The forecasted value are captured by the result HANA dataframe
<br>![](/exercises/ex1/images/26ex12-s3-1-results.png)

- Using the [forecast_line_plot](https://help.sap.com/doc/cd94b08fe2e041c2ba778374572ddba9/2026_3_QRC/en-US/hana_ml.visualizers.html) we can nicely visualize the forecast predictions, including the prediction confidence intervals
<br>![](/exercises/ex1/images/26ex12-s3-2-plot.png)

<br>

- In __Step 4__ you will repeat to create a forecast prediction of the hourly bike count data using SAP-RPT-TS however include the covariate columns, for an higher accurate forecast prediction
  - Note, the columns need to be passed in the following logical order  
   **key-column**, **target-column**, **covarite-columns**  
        <br>![](/exercises/ex1/images/26ex12-s4-1-hdf.png)
  - The forecast_line_plot respectively adjusts to the influence of the covariates and improves in accuracy
        <br>![](/exercises/ex1/images/26ex12-s4-2-plot.png)

<br><br>

## Exercise 1.3 Forecast multiple time series with "SAP-RPT-TS"
- Steps in this exercise section 
<br>![](/exercises/ex1/images/26ex13-outline.png)

<br>

- In __Step 5__ you will use the **MassivePipeline-method** to initiate the __forecast predictions in-parallel__ for __any of the Bike Rental subsidiaries__, identified by the column __LOCATION__
  - The input dataframe includes the LOCATION column
<br>![](/exercises/ex1/images/26ex12-s5-1-hdf.png)

<br>

- The **MassivePipeline-method** can as simply be applied as the regular Pipeline-Predict method, just by using the additional **group_key parameter**
<br>![](/exercises/ex1/images/26ex12-s5-2-forecast.png)

<br>

- And also the accuracy_measure allows us to be applied in massive, data-parallel mode using __massive=True__, calculation the accuracy for each LOCATION individually
<br>![](/exercises/ex1/images/26ex12-s5-3-accuracy.png)


## Summary

You've now successfully
- your first use of SAP-RPT-TS in SAP HANA Cloud to forecast Bike Sharing rental counts in a variety of flavors
  - using the Pipeline Predict function in skip-fit mode, forecasting with and without covariates
  - calculation forecast accuracy and visualizing foreast line plots
  - executed forecast calculations in parallel for multiple bike sharing locations using the massive-methods


Continue to - [Exercise 2 - Generate business data predictions using SAP-RPT-1.6 from SAP AI Core](../ex2/README.md)


---

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