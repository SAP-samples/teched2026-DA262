# Exercise 2 - Generate business data predictions using SAP-RPT-1.6 from SAP AI Core

In this exercise, utilize the SAP tabular AI foundation model SAP-RPT-1.6, to generate classification predictions on-the-fly using the new [SAP HANA Cloud procedure AI_TABULAR_PREDICTION](https://help.sap.com/docs/hana-cloud/sap-hana-cloud-sap-hana-database-ai-development-guide/ai-tabular-prediction-built-in-procedure) which calls out to a SAP AI Core service for the SAP-RPT-1.6 model.


## Exercise - Use case scenario overview

In this exercise, you will explore how to apply SAP-RPT-1.6  to generate classification prediction for fraudulent transaction data. Only a rather small fraction of the over 500000 rows are flagged with FRAUD column value 1 as fraudulent. The other columns in the table, shall help the model to reason about the pattern in order to identify the fraudulent transactions.
- Exercise overview
<br>![](/exercises/ex2/images/26_ex2_overview.png)


<br>

## Start the exercise
- open DBX
<br>![](/exercises/ex2/images/26_ex20-open_DBX.png)
- verify connection, select connection from database list
<br>![](/exercises/ex2/images/26_ex20-DBX_connection_catalog.png)

- Select Open SAP HANA SQL Console
-  Open a SQL editor
<br>![](/exercises/ex0/images/26_ex0s2-4_open_SQLconsole.png)


## Exercise 2.1 Review the remote source for "SAP-RPT-1.6"

In this first __Step 1__ 
- you will, simply execute a first simple query, to explore if our system with the remote source for SAP-RPT-1.6 is prepared.

- __Copy__ the following SQL statement, 
  - __Paste__ insert into the SQL Console
  - then __Run__ the statement and review the result
```sql
SELECT * FROM REMOTE_SOURCES;
```
- The result should show the remote source named __DA262_AICORE_RPT16__ 
    <br>![](/exercises/ex2/images/26_ex2_remotesource_result.png)


## Exercise 2.2 Explore the transaction fraud data

In the next __Step 2__
- you will explore the transaction data with identifies the fraudulent transations by the flag-column FRAUD

- __Copy__ the following SQL statement, 
  - __Paste__ insert into the SQL Console
  - then __Run__ the statement and review the result
```sql
SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD
FROM DA262_SHARED.TRANSACTIONS_FRAUD ORDER BY TRANSACTION_ID;
```
- The result should show some transactions are marked with FRAUD = 1, indicating those are fraudulent.
<br>![](/exercises/ex2/images/26_ex22_list_transactions.png)


## Exercise 2.3 Generate predictions with "SAP-RPT-1.6"

In the next __Step 3__
- you will now use the new SAP HANA Cloud procedure __AI_TABULAR_PREDICTION__ which calls out to SAP-RPT-1.6 (via the remote source) to generate classification predictions on-the-fly for us, without any model training and without requiring any expert ML knowledge from us using it
  - we are passing CONTEXT data to SAP-RPT-1.6, so it understands the nature of our table
  - and we are passing the rows, for which we want FRAUD values to get predicted
  - we use some random sampling for the CONTEXT data as well as the prediction rows to make the scenario a bit more dynamic
  - finally the script evaluates the accuracy of the predictions using a custom procedure (its DDL can be found in the appendix reference section)
- Note, as we use some random sampling, the results with not exactly match with the screenshots below

First __Copy__ the following SQL statement block to select CONTEXT and PREDICT rows, 
  - __Paste__ insert into the SQL Console
  - then __Run__ the statement block as a whole and review the result
```sql
-- selecting CONTEXT and TRANSACTIONS to PREDICT FRAUD;
DO BEGIN 
    /*** Select a stratified random sample for ~2039 rows, of which ~39 are fraudulent flagged transaction, as context to be forwarded to SAP-RPT-1.6 with the prediction call *******/
    CONTEXT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD 
    		  FROM DA262_SHARED.TRANSACTIONS_FRAUD TABLESAMPLE BERNOULLI (1.0) WHERE FRAUD = 0 AND TRANSACTION_ID < 200000  
    		  UNION 
    		  SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD 
    		  FROM DA262_SHARED.TRANSACTIONS_FRAUD TABLESAMPLE BERNOULLI (1.0) WHERE FRAUD = 1 AND TRANSACTION_ID < 200000 ;
    
    /*** Select rows where to predict Fraud, which we also prepare as a stratified sample of ~104rows, which 8 are fraudulent in the test data *******************/
    PREDICT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST 
    		  FROM DA262_SHARED.TRANSACTIONS_FRAUD TABLESAMPLE BERNOULLI (0.03) WHERE FRAUD = 0  AND TRANSACTION_ID > 200000 
    		  UNION 
              SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST 
    		  FROM DA262_SHARED.TRANSACTIONS_FRAUD TABLESAMPLE BERNOULLI (0.2) WHERE FRAUD = 1  AND TRANSACTION_ID > 200000;
 
    IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#CONTEXT' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #CONTEXT;
	END IF;
    CREATE LOCAL TEMPORARY COLUMN TABLE "#CONTEXT" AS (SELECT * FROM :CONTEXT);
    IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PREDICT' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PREDICT;
	END IF;
    CREATE LOCAL TEMPORARY COLUMN TABLE "#PREDICT" AS (SELECT * FROM :PREDICT);
END;
```
<br>

Next __Copy__ the following SQL statement block to execute the AI_TABULAR_PREDICTION call, 
  - __Paste__ insert into the SQL Console
  - then __Run__ the statement block as a whole and review the result
```sql
DO BEGIN
    DECLARE PREDICTION TABLE(ID NVARCHAR(5000), COLUMN_NAME NVARCHAR(5000), PREDICTED_VALUE NVARCHAR(5000), CONFIDENCE DOUBLE);
 
    /*** Select a context  sample rows **********************/
    CONTEXT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD FROM "#CONTEXT" ;
    
    /*** Select rows where to predict FRAUD for (target column omitted) **********************************/
    PREDICT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST FROM "#PREDICT";
 
    
    /*** Predict with SAP-RPT-1.6 using the SYS.AI_TABULAR_PREDICTION Procedure in SAP HANA CLoud *******/
    CALL SYS.AI_TABULAR_PREDICTION (
        REMOTE_SOURCE_SCHEMA_NAME => NULL,
        REMOTE_SOURCE_NAME => 'DA262_AICORE_RPT16',
        CONTEXT_TABLE => :CONTEXT,
        PREDICT_TABLE => :PREDICT,
        ID_COLUMN_NAME  => 'TRANSACTION_ID', 
        CONFIGURATION => '{"target_columns": [ {"name": "FRAUD", "task_type": "classification"}]}',
        PREDICT_RESULTS => :PREDICTION
    );
    
    SELECT * FROM :PREDICTION;
    IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PREDICTION_RESULT' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PREDICTION_RESULT;
	END IF;
    CREATE LOCAL TEMPORARY COLUMN TABLE "#PREDICTION_RESULT" AS (SELECT * FROM :PREDICTION);
END;
```  
- review the predictions results from AI_TABULAR_PREDICTION using SAP-RPT-1.6
<br>![](/exercises/ex2/images/26_ex23-predictions0.png)

<br>

Finally __Copy__ the following SQL statement block to evaluate the accuracy of the AI_TABULAR_PREDICTION results, 
  - __Paste__ insert into the SQL Console
  - then __Run__ the statement block as a whole and review the result
```sql
DO BEGIN
    /*** Compare actuals with predicted one-by-one in a query ******************************************************************************************************/
    lt_PREDICT_IN = SELECT  TO_FIXEDCHAR(ID, 8) AS "ID", TO_INT(PREDICTED_VALUE)  AS CLASS, CONFIDENCE FROM #PREDICTION_RESULT;
    lt_ACTUALS_IN = SELECT  TO_FIXEDCHAR(A.TRANSACTION_ID, 8) AS "ID", TO_INT(FRAUD) AS CLASS FROM #PREDICTION_RESULT AS P, DA262_SHARED.TRANSACTIONS_FRAUD AS A WHERE P.ID=A.TRANSACTION_ID;
    
    SELECT A.ID, A.CLASS AS ACTUAL_CLASS, P.CLASS AS PREDICTED_CLASS, CONFIDENCE 
           FROM :lt_PREDICT_IN AS P, :lt_ACTUALS_IN AS A WHERE A.ID=P.ID;
    

    /*** Calculate binary classification accuracy metrics, and the confusion matrix using a custom SQL procedure ****************************************************/
    -- What is the F1_SCORE for fraudulent transactions?;
    CALL DA262_SHARED.CLASSIFICATION_ACCURACY(:lt_ACTUALS_IN, :lt_PREDICT_IN,  lt_cm, lt_cm_stats, lt_stats );
    select * from :lt_cm;
    select * from :lt_stats ORDER BY STAT_NAME;
END;
```


- SAP-RPT-1 provides us with the predicted value in the column PREDICTED_CLASS and a CONFIDENCE value, indicating how sure RPT is about the predicted value is right.
<br>![](/exercises/ex2/images/26_ex23-predictions.png)

- This next table shows the so-called "confusion matrix" mapping the combinations of original versus predicted values and its count value
  - As we care about that FRAUD = 1 values are mostly correct (the fraudulent transactions), our interest is those should ideally all be correctly predicted as 1 
<br>![](/exercises/ex2/images/26_ex23-cm.png)  

- The classification accuracy statistics computed by the custom procedure, show a set common metrics, helping you in evaluating the result
  - the F1_SCORE_1 (_1 = for our case 1 fraudulent) provides us with a balanced metric summarizing over falsely classified rows as 1 as well as overseen original fraudulent rows the model didn't predict correctly
<br>![](/exercises/ex2/images/26_ex23-stats.png)


<br>

The OPTIONAL __Step 4__ includes a code example, when __predicting multiple targets at once__, like 
- classification with column FRAUD
- regression with column AMOUNT (also omitted from the PREDICT input table)
- explore for yourself.

```sql
DO BEGIN
    DECLARE PREDICTION TABLE(ID NVARCHAR(5000), COLUMN_NAME NVARCHAR(5000), PREDICTED_VALUE NVARCHAR(5000), CONFIDENCE DOUBLE);
 
       /*** Select a stratified random sample for ~2039 rows, of which ~39 are fraudulent flagged transaction, as context to the SAP-RPT-1.6 prediction call *******/
    CONTEXT = SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD 
    		  FROM DA262_SHARED.TRANSACTIONS_FRAUD TABLESAMPLE BERNOULLI (1.0) WHERE FRAUD = 0 AND TRANSACTION_ID < 200000  
    		  UNION 
    		  SELECT TRANSACTION_ID, ORIGIN, CLASS, AMOUNT, OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST, FRAUD 
    		  FROM DA262_SHARED.TRANSACTIONS_FRAUD TABLESAMPLE BERNOULLI (1.0) WHERE FRAUD = 1 AND TRANSACTION_ID < 200000 ;
    
    /*** Select rows where to predict Fraud, which we also prepare as a stratified sample of ~104rows, which 8 are fraudulent in the test data *******************/
    PREDICT = SELECT TRANSACTION_ID, ORIGIN, CLASS,  OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST 
    		  FROM DA262_SHARED.TRANSACTIONS_FRAUD TABLESAMPLE BERNOULLI (0.03) WHERE FRAUD = 0  AND TRANSACTION_ID > 200000 
    		  UNION 
              SELECT TRANSACTION_ID, ORIGIN, CLASS,  OLD_BALANCE_ORIGIN, NEW_BALANCE_ORIGIN, DESTINATION, OLD_BALANCE_DEST, NEW_BALANCE_DEST 
    		  FROM DA262_SHARED.TRANSACTIONS_FRAUD TABLESAMPLE BERNOULLI (0.2) WHERE FRAUD = 1  AND TRANSACTION_ID > 200000;

 
    CALL SYS.AI_TABULAR_PREDICTION /*FOUNDATION_MODEL_PREDICT_DEV*/(
        REMOTE_SOURCE_SCHEMA_NAME => NULL,
        REMOTE_SOURCE_NAME => 'DA262_AICORE_RPT16',
        CONTEXT_TABLE => :CONTEXT,
        PREDICT_TABLE => :PREDICT,
        ID_COLUMN_NAME /* INDEX_COLUMN_NAME */ => 'TRANSACTION_ID', 
        /*PREDICT_SCHEMA => '{"FRAUD": "classification"}', */
        CONFIGURATION => '{"target_columns": [ {"name": "FRAUD", "task_type": "classification"}, 
                                               {"name": "AMOUNT", "task_type": "regression"}]}',
        PREDICT_RESULTS => :PREDICTION
    );
    SELECT * FROM :PREDICTION;
END;
```
- The output will include separate rows for each target column predicted
 <br>![](/exercises/ex2/images/26_ex24-multitarget-predict.png)

## Summary

You've now successfully applied SAP-RPT-1.6 to classify fraudulent transaction based our the transaction data in SAP HANA Cloud using the new procedure AI_TABULAR_PREDICTION.

Continue to - [Exercise 3 - Build multi-target neural network prediction models for an order form autocompletion use case](../ex3/README.md) 

<br><br>

## Appendix

### Reference Information - Transaction Fraud scenario and data
- The use case is outlined in more detail in this SAP Community blog post [Hands-On Tutorial: Leverage AutoML in SAP HANA Cloud with the Predictive Analysis Library](https://community.sap.com/t5/technology-blog-posts-by-sap/hands-on-tutorial-leverage-automl-in-sap-hana-cloud-with-the-predictive/ba-p/13556400) 
- Note, the fraudulent transaction data has been artificially generated by the blog post owner and can be downloaded [here BB_data.csv](https://github.com/SAP-samples/hana-ml-samples/blob/main/Python-API/usecase-examples/fraud-detection/BB_data.csv)

### Reference Information - Setup of AI Core for SAP-RPT-1.6 and the REMOTE SOURCE in SAP HANA Cloud

The following tutorial [Set up and use the Data Exploration Tools ](https://developers.sap.com/tutorials/hana-cloud-data-exploration-tools/)
- explains in details how create an SAP AI Core instance by example of an orchestration model instance and references on how to add an additional model to support SAP-RPT-1.   

Further step-by-step setup details are documented in the [SAP HANA Database AI Development Guide](https://help.sap.com/docs/hana-cloud/sap-hana-cloud-sap-hana-database-ai-development-guide/connecting-to-sap-ai-core).
- a rough example to the SQL setup steps in HANA Cloud for the connection certificates and the remote source are shown in the following example
```sql
/** Some prep-steps would be required: Define RPT-1 Remote Source **************/
--CREATE PSE BTP_EMBEDDING_PSE;
--ALTER PSE BTP_EMBEDDING_PSE SET OWN CERTIFICATE '
-----BEGIN RSA PRIVATE KEY-----123...-----END RSA PRIVATE KEY-----
-----BEGIN CERTIFICATE-----ABC...-----END CERTIFICATE-----
--';

-- Create remote source for RPT-1
/*CREATE REMOTE SOURCE DA262_AICORE_RPT16 ADAPTER "sapgenaihub" CONFIGURATION
    'aiApiUrl=https://api.ai.internalprod.eu-central-1.aws.ml.hana.ondemand.com;
     authUrl=https://ai-core-wklw5w1s.authentication.cert.sap.hana.ondemand.com;
     resourceGroup=default;
     deploymentId=XYZ;
     clientId=1a2b###'
WITH CREDENTIAL TYPE 'X509' PSE BTP_EMBEDDING_PSE;*/

--privileges
--GRANT EXECUTE ON REMOTE SOURCE DA262_AICORE_RPT16 TO <USER>;
--GRANT EXECUTE ON SYS.AI_TABULAR_PREDICTION TO <USER>;
```

### Reference Information - CLASSIFICATION_ACCURACY procedure
- The SQL procedure code behind CLASSIFICATION_ACCURACY 
```sql
CREATE OR REPLACE PROCEDURE DA262_SHARED.CLASSIFICATION_ACCURACY (
       IN it_actuals TABLE  (ID INTEGER, CLASS INTEGER),
       IN  it_predicted TABLE  (ID INTEGER, CLASS INTEGER, CONFIDENCE DOUBLE),
       OUT  out_cm TABLE (ORIGINAL INTEGER, PREDICT INTEGER, COUNT DOUBLE),
       OUT  out_cm_metric TABLE (CLASS NVARCHAR(100), "PRECISION" DOUBLE, RECALL DOUBLE, F1_SCORE DOUBLE, SUPPORT INTEGER),
       OUT  ot_stats TABLE (STAT_NAME NVARCHAR(100), STAT_VALUE DOUBLE))
AS 
 begin
	DECLARE lt_auc_param TABLE("PARAM_NAME" NVARCHAR(256), "INT_VALUE" INTEGER, "DOUBLE_VALUE" DOUBLE, "STRING_VALUE" NVARCHAR (1000));
    DECLARE lt_cm_param TABLE("PARAM_NAME" NVARCHAR(256), "INT_VALUE" INTEGER, "DOUBLE_VALUE" DOUBLE, "STRING_VALUE" NVARCHAR (1000));
    DECLARE lv_dt_auc           DOUBLE;
      declare TP, TN, FP, FN bigint;
	  declare lv_accuracy, lv_recall, lv_specificity, lv_precision, lv_FPR, lv_FNR, lv_F1, lv_MCC, lv_KI double;
	 declare VAL_AUC, lv_obsAcc, lv_class1_marginfreq, lv_class0_marginfreq, lv_expAcc, lv_KAPPA double;

    lt_actual_data = SELECT ID, CLASS FROM :it_actuals;
    --confidence for each class and id;
    lt_predicted_data = SELECT "ID", "CLASS", CONFIDENCE 
    					FROM :it_predicted
                        UNION ALL
                        SELECT "ID",
                               1 - "CLASS" AS CLASS,
                               1.0 - CONFIDENCE AS CONFIDENCE
                        FROM :it_predicted
                        ORDER BY "ID";
    

    lt_auc_param.PARAM_NAME[1] = 'NTILES';
    lt_auc_param.INT_VALUE[1] = 20;
    
    CALL _SYS_AFL.PAL_MULTICLASS_AUC(:lt_actual_data, :lt_predicted_data, :lt_auc_param, lt_auc, lt_roc);
    SELECT TO_DOUBLE(stat_value) INTO lv_dt_auc FROM :lt_auc WHERE stat_name = 'AUC';
    
    ---CM;
    lt_predicted_result = SELECT "ID", "CLASS", CONFIDENCE 
    					FROM :it_predicted ;
    lt_cm_param.PARAM_NAME[1] = 'BETA';
    lt_cm_param.DOUBLE_VALUE[1] = 1; -- F1 Score
    lt_dt_max_prob = SELECT result."ID" AS "ID", "CLASS" 
    					FROM :lt_predicted_result AS result 
    						INNER JOIN 
    					(SELECT "ID", MAX(confidence) AS confidence FROM :lt_predicted_result GROUP BY "ID") AS max_prob
                            ON result."ID" = max_prob."ID" AND result.confidence = max_prob.confidence;
    --select * from   :lt_dt_max_prob;                                                         
    lt_dt_cm_data = SELECT actual."ID" AS "ID", TO_INTEGER(actual."CLASS") AS original, TO_INTEGER(pred."CLASS") AS predict
                      FROM :lt_actual_data AS actual INNER JOIN :lt_dt_max_prob AS pred ON actual."ID" = pred."ID";
    CALL _SYS_AFL.PAL_CONFUSION_MATRIX(:lt_dt_cm_data, :lt_cm_param, lt_dt_confusion_matrix, lt_dt_measure);
    
    out_cm = SELECT * FROM :lt_dt_confusion_matrix;

    out_cm_metric = SELECT /*:lv_dt_auc   AS "AUC",  */ class, precision, recall, f_measure AS f1_score, support FROM :lt_dt_measure;
       
    -- binary classification - target class "1";
    select SUM("COUNT") INTO TP from :lt_dt_confusion_matrix where "ORIGINAL"='1' and "PREDICT"='1';
    select SUM("COUNT") INTO FP from :lt_dt_confusion_matrix where "ORIGINAL"='0' and "PREDICT"='1';
    select SUM("COUNT") INTO TN from :lt_dt_confusion_matrix where "ORIGINAL"='0' and "PREDICT"='0';
    select SUM("COUNT") INTO FN from :lt_dt_confusion_matrix where "ORIGINAL"='1' and "PREDICT"='0';

  
    --	Accuracy: Percentage of total items classified correctly- (TP+TN)/(N+P);
    lv_accuracy := (:TP + :TN) / NULLIF(:TP + :TN + :FP + :FN, 0);
    -- Recall or Sensitivity or TPR (True Positive Rate): Number of items correctly identified as positive out of total true positives- TP/(TP+FN) ;
    -- Recall indicates how many of the failures were detected (Recall = TP / (TP + FN));
    lv_recall := :TP / NULLIF(:TP + :FN, 0);
    -- Specificity or TNR (True Negative Rate): Number of items correctly identified as negative out of total negatives- TN/(TN+FP) ;
    lv_specificity := :TN / NULLIF(:TN + :FP, 0);
    -- Precision: Number of items correctly identified as positive out of total items identified as positive- TP/(TP+FP) ;
    -- Precision denotes the rate of false alarms (Precision = TP / (TP + FP) );
    lv_precision := :TP / NULLIF(:TP + :FP, 0);
    --False Positive Rate or Type I Error: Number of items wrongly identified as positive out of total true negatives- FP/(FP+TN) ;
    lv_FPR := NULLIF(NULLIF(:FP, 0) / NULLIF(:FP + :FN, 0), 0);
    --lv_FPR := :FP / (:FP+:FN);
    -- False Negative Rate or Type II Error: Number of items wrongly identified as negative out of total true positives- FN/(FN+TP) ;
    lv_FNR := :FN / NULLIF(:FN+:TP, 0);
    --F1 Score: It is a harmonic mean of precision and recall given by- F1 = 2*Precision*Recall/(Precision + Recall);
    --  F1 considers both precision and recall rates and can give a more balanced view. ;
    --  F1 = 2 * ((Precision * Recall) / (Precision + Recall)) ;
    lv_F1 := ((2 * :lv_precision * :lv_recall) / (:lv_precision / :lv_recall));
  
    -- MCC;
    lv_MCC := ((:TP * :TN)-(:FP * :FN)) / SQRT ( (:TP + :FP) * (:TP + :FN) * (:TN + :FP) * (:TN + :FN));

    -- Predictive Power (KI);
    -- KI =  (Area of model performance on validation data (blue bump))/(Area of wizard model performance (green triangle)) = 2 * AUC – 1;
    VAL_AUC := :lv_dt_auc;
    lv_KI := (2 * :VAL_AUC) - 1;


   --Kappa = (observed accuracy - expected accuracy)/(1 - expected accuracy);
   lv_obsAcc := :lv_accuracy  ; /*:TP + :TN;*/
   lv_class1_marginfreq := (:TP + :FN) * (:TP + :FP) / (:TP + :TN + :FP + :FN);
   lv_class0_marginfreq := (:TN + :FP) * (:TN + :FN) / (:TP + :TN + :FP + :FN);
   lv_expAcc := (:lv_class1_marginfreq + :lv_class0_marginfreq) / (:TP + :TN + :FP + :FN);
   lv_KAPPA := (:lv_obsAcc - :lv_expAcc ) / (1 - :lv_expAcc );

  
   -- 'Classification debrief statistics, target class: 1';
   lt_cm_stats= SELECT * FROM :out_cm_metric;
   ot_stats = SELECT STAT_NAME, STAT_VALUE FROM (
    select  1 AS ID, 'AUC' AS STAT_NAME, :VAL_AUC as STAT_VALUE FROM dummy UNION 
    select  2 AS ID,  'Accuracy' AS STAT_NAME,  :lv_accuracy AS STAT_VALUE FROM dummy UNION 
    select  3 AS ID,  'RECALL (Sensitivity, TPR)' AS STAT_NAME , :lv_recall AS STAT_VALUE FROM dummy UNION 
     select  4 AS ID, 'Specificity (TNR)' AS STAT_NAME , :lv_specificity AS STAT_VALUE FROM dummy UNION 
     select  5 AS ID, 'Precision (TP/(TP+FP))' AS STAT_NAME , :lv_precision AS STAT_VALUE FROM dummy UNION 
     select  6 AS ID,  'FPR' AS STAT_NAME , :lv_FPR AS STAT_VALUE FROM dummy UNION 
     select   7 AS ID,  'FNR' AS STAT_NAME, :lv_FNR AS STAT_VALUE FROM dummy UNION 
     /*select  8 AS ID,   'F1' AS STAT_NAME, :lv_F1 AS STAT_VALUE FROM dummy UNION */
     select   9 AS ID,  'MCC' AS STAT_NAME, :lv_MCC STAT_VALUE FROM dummy UNION 
     select   10 AS ID,  'KI (Predictive Power)' AS STAT_NAME, :lv_KI STAT_VALUE FROM dummy UNION 
     select   11 AS ID,  'KAPPA' AS STAT_NAME, lv_KAPPA AS STAT_VALUE FROM dummy 
     ORDER BY ID)
     UNION
      select 'PRECISION_0' AS STAT_NAME, PRECISION AS STAT_VALUE from :lt_cm_stats WHERE CLASS = '0' 
    UNION 
    select 'PRECISION_1' AS STAT_NAME, PRECISION AS STAT_VALUE from :lt_cm_stats WHERE CLASS = '1'
    UNION
    select 'RECALL_0' AS STAT_NAME, RECALL AS STAT_VALUE from :lt_cm_stats WHERE CLASS = '0' 
    UNION 
    select 'RECALL_1' AS STAT_NAME, RECALL AS STAT_VALUE from :lt_cm_stats WHERE CLASS = '1'
    UNION
    select 'F1_SCORE_0' AS STAT_NAME, F1_SCORE AS STAT_VALUE from :lt_cm_stats WHERE CLASS = '0' 
    UNION 
    select 'F1_SCORE_1' AS STAT_NAME, F1_SCORE AS STAT_VALUE from :lt_cm_stats WHERE CLASS = '1'
    UNION
    select 'SUPPORT_0' AS STAT_NAME, SUPPORT AS STAT_VALUE from :lt_cm_stats WHERE CLASS = '0' 
    UNION 
    select 'SUPPORT_1' AS STAT_NAME, SUPPORT AS STAT_VALUE from :lt_cm_stats WHERE CLASS = '1';   
   
END;

```