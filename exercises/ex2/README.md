# Exercise 2 - Generate business data predictions using SAP-RPT-1.6 from SAP AI Core

In this exercise, we will create time series forecasts on-the-fly on XYZ data stored in SAP HANA Cloud, using the new time series forecasting tabular foundation model from SAP, SAP-RPT-TS, served locally from within the SAP HANA Cloud environment.

## Exercise - Use case scenario overview

In this exercise, you will explore how to apply SAP-RPT-TS to generate bike sales forecast predictions in SAP HANA Cloud

1. You will explore on how to call the SAP-RPT-TS model to generate and evaluate forcasts using pipeline- and AutoML-methods in Python or SQL, depending on your preference. 
2. You will further learn how to create forecasts with and without covariate data, and how to forecast multiple time series at once using the massive, data-parallel methods
<br>

## Exercise 2.1 Review the remote source for "SAP-RPT-1.6"

After completing these steps you will have created...

2.	Insert this line of code.
```sql
SELECT * FROM REMOTE_SOURCES;
```
- review 

<br>![](/exercises/ex2/images/26_ex21-remotesource.png)


## Exercise 2.2 Explore the GX transaction fraud data

After completing these steps you will have...

1.	Enter this code.
```sql
SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD
FROM MLLAB_SHARE.GX_TRANSACTIONS ORDER BY TRANSACTION_ID;

```
2.	Click here.
<br>![](/exercises/ex2/images/26_ex22-gxdata.png)


## Exercise 2.3 Generate predictions with "SAP-RPT-1.6"

After completing these steps you will have...

1.	Enter this code.
```sql
DO BEGIN
    DECLARE PREDICTION TABLE(ID NVARCHAR(5000), COLUMN_NAME NVARCHAR(5000), PREDICTED_VALUE NVARCHAR(5000), CONFIDENCE DOUBLE);
 
    CONTEXT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD 
    		  FROM MLLAB_SHARE.GX_TRANSACTIONS WHERE TRANSACTION_ID < 1000 ;
    PREDICT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST
    		 FROM MLLAB_SHARE.GX_TRANSACTIONS WHERE TRANSACTION_ID between 1000 AND 1050;
 
    CALL SYS.AI_TABULAR_PREDICTION /*FOUNDATION_MODEL_PREDICT_DEV*/(
        REMOTE_SOURCE_SCHEMA_NAME => NULL,
        REMOTE_SOURCE_NAME => 'AI_CORE_RPT',
        CONTEXT_TABLE => :CONTEXT,
        PREDICT_TABLE => :PREDICT,
        ID_COLUMN_NAME /* INDEX_COLUMN_NAME */ => 'TRANSACTION_ID', 
        /*PREDICT_SCHEMA => '{"FRAUD": "classification"}', */
        CONFIGURATION => '{"target_columns": [ {"name": "FRAUD", "task_type": "classification"}]}',
        PREDICT_RESULTS => :PREDICTION
    );
    SELECT * FROM :PREDICTION;
END;

```
2.	Click here.
<br>![](/exercises/ex2/images/26_ex23-predictions.png)


## Summary

You've now ...

Continue to - [Exercise 3 - Build multi-target neural network prediction models for an order form autocompletion use case](exercises/ex3/) 
