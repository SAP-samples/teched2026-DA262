# Exercise 1 - Generate time series forecasts on-the-fly using using SAP-RPT-TS from SAP HANA Cloud

In this exercise, we will create time series forecasts on-the-fly on XYZ data stored in SAP HANA Cloud, using the new time series forecasting tabular foundation model from SAP, SAP-RPT-TS, served locally from within the SAP HANA Cloud environment.

## Exercise - Use case scenario overview

In this exercise, you will explore how to apply SAP-RPT-TS to generate bike sales forecast predictions in SAP HANA Cloud

1. You will explore on how to call the SAP-RPT-TS model to generate and evaluate forcasts using pipeline- and AutoML-methods in Python or SQL, depending on your preference. 
2. You will further learn how to create forecasts with and without covariate data, and how to forecast multiple time series at once using the massive, data-parallel methods
<br>

![](/exercises/ex1/images/26_ex1_overview.png)

<br>

## Exercise 1.1 Explore the Bike Sharing time series data

After completing these steps you will have created...

1. Click here.
<br>![](/exercises/ex1/images/26ex11-1_ts_data.png)

2.	Insert this line of code.
```python
hdf_data_plot = data_hdf.select('Sales', 'Date', 'Store').sort('Date') #,\'64\',\'25\'
import plotly.express as px
fig = px.line(hdf_data_plot.filter('"Store" in (\'84\')').collect() , x='Date', y='Sales', title='Sales by Store')
fig.show()
fig = px.line(hdf_data_plot.filter('"Store" in (\'53\')').collect() , x='Date', y='Sales', title='Sales by Store')
fig.show()
```



## Exercise 1.2 Forecast with "SAP-RPT-TS"

After completing these steps you will have...

1.	Enter this code.
```python
from hana_ml.algorithms.pal.pipeline import Pipeline
#pipe = Pipeline(pipeline={"TSFM": {"args": {}, "inputs": {"data": "ROWDATA"}}})
pipe = Pipeline(pipeline={"TSFM": {"args": {"BATCH_SIZE": [128], "OUTPUT_QUANTILE": 0, "POINT_FORECAST": ["median"], "CLIP_MIN": 0, "CLIP_MAX": 999999, 
                                            "FORECAST_LENGTH": 48}, 
                                   "inputs": {"data": "ROWDATA"}}})

result = pipe.predict(data_hdf.filter('"Store" in (\'84\')').select('DATE', 'Sales'), key='DATE', 
                                             output_prediction_interval=True, confidence_level=0.9)#, endog="HOTELNIGHTS")

```

## Exercise 1.3 Forecast multiple time series with "SAP-RPT-TS"

After completing these steps you will have...

1.	Enter this code.
```python
from hana_ml.algorithms.pal.massive_pipeline import MassivePipeline
mpipe = MassivePipeline(pipeline={"TSFM": {"args": {"BATCH_SIZE": [128], "OUTPUT_QUANTILE": 0, "POINT_FORECAST": ["median"], "CLIP_MIN": 0, "CLIP_MAX": 30000}, "inputs": {"data": "ROWDATA"}}})
#"FORECAST_LENGTH": 48
# Note, endog/target determined by column order: GROUP_ID, DATE_KEY, ENDOG/TARGET, <COVARIATES>
result=mpipe.predict(predall_imputet, group_key='Store', key='DATE', output_prediction_interval=True, confidence_level=0.9)  
        #categorical_variable=['Open', 'Promo', 'SchoolHoliday', 'Promo2'], exog=covariates
result.collect()
```
<br>![](/exercises/ex1/images/26ex13-1_forecast_result.png)

## Exercise 1.4 Utilize "SAP-RPT-TS" with AutoML for time series (optional)
- AutoML TimeSeries Fit¶
- Predict with RPT-TS, using pipeline determined from AutoML-Fit
- Explicit back-testing of the RPT-TS forecast

## Exercise 1.5 Utilize PAL SQL functions for "SAP-RPT-TS" (optional)

2.	Click here.
```sql
```

## Summary

You've now ...

Continue to - [Exercise 2 - Generate business data predictions using SAP-RPT-1.6 from SAP AI Core](../ex2/README.md)

