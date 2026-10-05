/****************************************************************************************************************************************************************************/
SET SCHEMA GUIDEDEXP;


/**************************************************************************************************************************************************************************************/
-- Step 0 - Prepare Tables and Data;

CREATE OR REPLACE VIEW TRANSACTIONSV as
SELECT "TRANSACTION_ID", "ORIGIN", "CLASS", CAST("AMOUNT" AS DOUBLE) AS "AMOUNT", CAST("OLD_BALANCE_ORIGIN" AS DOUBLE) AS "OLD_BALANCE_ORIGIN", CAST("NEW_BALANCE_ORIGIN" AS DOUBLE) AS "NEW_BALANCE_ORIGIN", 
       "DESTINATION", CAST("OLD_BALANCE_DEST" AS DOUBLE) AS "OLD_BALANCE_DEST",  CAST("NEW_BALANCE_DEST" AS DOUBLE) AS "NEW_BALANCE_DEST", CAST("FRAUD" AS NVARCHAR(20)) AS "FRAUD" 
       FROM  "GUIDEDEXP"."GX_TRANSACTIONS";
  
 SELECT Top 10 * FROM TRANSACTIONSV;
 SELECT count(TRANSACTION_ID)  FROM TRANSACTIONSV ; 
 SELECT count(*) AS N, "FRAUD" FROM TRANSACTIONSV GROUP BY "FRAUD";

/******************************************************************************************************************************************************************************************/
-- We are sampling down the data, and sampling out a test data set, so we can benchmark the (best) fitted model against unseen data;
-- Step 1 - Partitioning;

DO
BEGIN
  	/*** Parameters *****/
	IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_PARAMETER_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_PARAMETER_TBL;
	END IF;
	CREATE LOCAL TEMPORARY COLUMN TABLE #PAL_PARAMETER_TBL ("PARAM_NAME" VARCHAR (256),"INT_VALUE" INTEGER,"DOUBLE_VALUE" DOUBLE,"STRING_VALUE" VARCHAR (5000));
    
    /*** Downsampling ***/
    truncate TABLE #PAL_PARAMETER_TBL;
	INSERT INTO #PAL_PARAMETER_TBL VALUES ('SAMPLING_METHOD',8,null,null); -- stratified_wor;
   	INSERT INTO #PAL_PARAMETER_TBL VALUES ('RANDOM_SEED', 1234, null,null);
	INSERT INTO #PAL_PARAMETER_TBL VALUES ('COLUMN_CHOOSE', null,NULL, 'FRAUD');
	INSERT INTO #PAL_PARAMETER_TBL VALUES ('PERCENTAGE', null,0.05,null);

  	/*** Table variables *****/
    lt_parms = SELECT * FROM #PAL_PARAMETER_TBL;
    lt_inputdata = SELECT * FROM TRANSACTIONSV;

   /*** PAL function call *****/
   CALL "_SYS_AFL"."PAL_SAMPLING"(:lt_inputdata, :lt_parms, downsample_out);

    /*** Outsampling train and testdata ***/
    truncate TABLE #PAL_PARAMETER_TBL;
  	INSERT INTO #PAL_PARAMETER_TBL VALUES ('PARTITION_METHOD',1,null,null); -- stratified;
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('STRATIFIED_COLUMN', null,NULL, 'FRAUD');
   	INSERT INTO #PAL_PARAMETER_TBL VALUES ('RANDOM_SEED', 1234, null,null);
	INSERT INTO #PAL_PARAMETER_TBL VALUES ('TRAINING_PERCENT', null,0.7,null);
	INSERT INTO #PAL_PARAMETER_TBL VALUES ('TESTING_PERCENT', null,0.3,null);
	INSERT INTO #PAL_PARAMETER_TBL VALUES ('VALIDATION_PERCENT', null,0.0,null);

   /*** Table variables *****/
    lt_parms = SELECT * FROM #PAL_PARAMETER_TBL;
    lt_inputdata = SELECT * FROM :downsample_out;
   CALL _SYS_AFL.PAL_PARTITION(:lt_inputdata, :lt_parms, out_0);
  
  /*** results *****/
  	IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_PARTITION_RESULT_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_PARTITION_RESULT_TBL;
	END IF;
   CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_PARTITION_RESULT_TBL" AS (SELECT * FROM :out_0);
   SELECT TOP 10 * FROM "#PAL_PARTITION_RESULT_TBL";
END;
SELECT Count(*) AS N, T."FRAUD" FROM #PAL_PARTITION_RESULT_TBL AS P, TRANSACTIONSV AS T WHERE P.TRANSACTION_ID = T.TRANSACTION_ID   GROUP BY T."FRAUD";


/*********************************************************************************************************************************************************************************/
-- Step 2 - Prepare the AutoML scenario configuration with wanted operators (algorithms) and their parameter values, value-range to search for the best model pipeline;

DO BEGIN
	  truncate TABLE #PAL_PARAMETER_TBL;
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('PIPELINE_TYPE',null,NULL,'classifier');
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('VERIFY_CONFIG',1,null,null);
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_DICT',null,NULL,'light'); -- Uses a lightweight DEFAULT AutoML classifier operator dictionary;
	 
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_REMOVE', null, null, 'NB_Classifier');
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_REMOVE', null, null, 'MLP_Classifier');
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_REMOVE', null, null, 'TomekLinks');
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_REMOVE', null, null, 'SMOTETomek');
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_MODIFY', null, null, '{"RDT_Classifier":{"TREES_NUM":[101]}}');
	  INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_MODIFY', null, null, '{"HGBT_Classifier": {"ITER_NUM": [50, 100], "MAX_DEPTH": {"range": [1, 1, 6]}, "ETA": [0.1, 0.5, 1.0]}}');
	  --INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_ADD', null, null, 'MYSUPER_Classifier'); --Verify config: shows exception error;
	 
	  lt_parms = SELECT * FROM #PAL_PARAMETER_TBL;

      call _SYS_AFL.PAL_AUTOML_CONFIG(:lt_parms, lt_config, lt_info);
      IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_AUTOML_CONFIG_TAB' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_AUTOML_CONFIG_TAB;
	      END IF;
          CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_AUTOML_CONFIG_TAB" AS (SELECT * FROM :lt_config);
      IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_AUTOML_CONFIGINFO_TAB' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_AUTOML_CONFIGINFO_TAB;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_AUTOML_CONFIGINFO_TAB" AS (SELECT * FROM :lt_info);
END;

select * from #PAL_AUTOML_CONFIG_TAB;
select * from #PAL_AUTOML_CONFIGINFO_TAB;



/**********************************************************************************************************************************************************************************/
-- Step 3 - Now run the AutoML Classification Model fitting, searching for the best pipeline of algorithms and best parameter settings;
DO
BEGIN
	/*** Parameters *****/
	declare tvar timestamp;
    DECLARE myuser NVARCHAR(12);
    select CURRENT_TIMESTAMP INTO tvar from dummy;
    select CURRENT_USER INTO myuser from dummy;
    truncate TABLE #PAL_PARAMETER_TBL;
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('PIPELINE_TYPE',null,NULL,'classifier');
   	INSERT INTO #PAL_PARAMETER_TBL VALUES ('HAS_ID',1,null,null);
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('DEPENDENT_VARIABLE',null,null, 'FRAUD');
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('FOLD_NUM',5,null,null);
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('RESAMPLING_METHOD',null,null, 'stratified_cv');
   
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('THREAD_RATIO',null,0.8,null);
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('RANDOM_SEED',1234,null,null);
     
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('GENERATIONS',2,null,null);
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('POPULATION_SIZE',5,null,null);
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('OFFSPRING_SIZE',5,null,null);

    INSERT INTO #PAL_PARAMETER_TBL VALUES ('SUCCESIVE_HALVING',1,null,null);  
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONNECTIONS',null,NULL, 'default');
 
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('MAX_EVAL_TIME_MINS',null, 1.0, NULL);
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('EARLY_STOP',3,null,null);
   
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('SCORINGS',null,NULL, '{"F1_SCORE_1": 1.0}');
  	INSERT INTO #PAL_PARAMETER_TBL VALUES ('ELITE_NUMBER',5,null,null);

    -- Retrieve AutoML configuration prepared before, or start with a clean system configuration;  
       -- INSERT INTO #PAL_PARAMETER_TBL VALUES ('CONFIG_DICT',null,NULL,'light');  -- 'default';
    INSERT INTO #PAL_PARAMETER_TBL SELECT 'CONFIG_DICT', NULL, NULL, CONTENT FROM #PAL_AUTOML_CONFIG_TAB WHERE ROW_INDEX = 0;  
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('VERIFY_CONFIG',1,null,null);

    INSERT INTO #PAL_PARAMETER_TBL VALUES ('EXECUTION_ID',null,NULL, 'AutoMLFit-Fraud_ClassModel-'||:tvar||'-'||:myuser);
    INSERT INTO #PAL_PARAMETER_TBL VALUES ('RETENTION_PERIOD',1,null,null);
   
     /*** Table variables *****/
    lt_parms = SELECT * FROM #PAL_PARAMETER_TBL;
    lt_fitdata = select D.*   from TRANSACTIONSV as D,  "#PAL_PARTITION_RESULT_TBL" AS P  where D.TRANSACTION_ID = P.TRANSACTION_ID and P.PARTITION_TYPE = 1;

    /*** PAL function call *****/
    CALL _SYS_AFL.PAL_AUTOML_FIT(:lt_fitdata, :lt_parms, out_0, out_1, out_2);
  
     /*** results *****/
  	IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_AUTOML_BEST_PIPELINE_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_AUTOML_BEST_PIPELINE_TBL;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_AUTOML_BEST_PIPELINE_TBL" AS (SELECT * FROM :out_0);
    IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_AUTOML_MODEL_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_AUTOML_MODEL_TBL;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_AUTOML_MODEL_TBL" AS (SELECT * FROM :out_1);
    IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_AUTOML_INFO' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_AUTOML_INFO;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_AUTOML_INFO" AS (SELECT * FROM :out_2);
      
END /*WITH HINT (WORKLOAD_CLASS("<my workload class>"))*/;

SELECT * FROM #PAL_AUTOML_BEST_PIPELINE_TBL;
SELECT * FROM #PAL_AUTOML_MODEL_TBL;




/******************************************************************************************************************************************************************************/
-- Step 4 - Score/benchmark the (best) fitted model against unseen test data, evaulate the quality performance of the model;

DO (IN IN_MODELT TABLE ("ROW_INDEX" INT, "MODEL_CONTENT" NVARCHAR(5000)) => "#PAL_AUTOML_MODEL_TBL")
BEGIN
	/*** Parameters *****/
    truncate TABLE #PAL_PARAMETER_TBL;
	INSERT INTO #PAL_PARAMETER_TBL VALUES ('THREAD_RATIO',null,0.8,null);

    /*** Table variables *****/
    lt_parms = SELECT * FROM #PAL_PARAMETER_TBL;
    lt_testdata = select D.*   from TRANSACTIONSV as D,  "#PAL_PARTITION_RESULT_TBL" AS P  where D.TRANSACTION_ID = P.TRANSACTION_ID and P.PARTITION_TYPE = 2;
    lt_model = SELECT * FROM :IN_MODELT;
   
   /*** PAL function call *****/
   CALL _SYS_AFL.PAL_PIPELINE_SCORE(:lt_testdata, :lt_model, :lt_parms, out_0, out_1, out_2, out_3);
  
   /*** Results *****/
  	IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_PIPELINE_SCORE_RESULT_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_PIPELINE_SCORE_RESULT_TBL;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_PIPELINE_SCORE_RESULT_TBL" AS (SELECT * FROM :out_0);
    IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_PIPELINE_SCORE_STATS_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_PIPELINE_SCORE_STATS_TBL;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_PIPELINE_SCORE_STATS_TBL" AS (SELECT * FROM :out_1);

END /*WITH HINT (WORKLOAD_CLASS("<my workload class>"))*/;
SELECT * FROM  #PAL_PIPELINE_SCORE_STATS_TBL;
SELECT TOP 10 * FROM  #PAL_PIPELINE_SCORE_RESULT_TBL;



/************************************************************************************/
-- Step 5 - Predict using the (best) fitted, scored model with new data (here, in the demo we use again the test data;

DO (IN IN_MODELT TABLE ("ROW_INDEX" INT, "MODEL_CONTENT" NVARCHAR(5000)) => "#PAL_AUTOML_MODEL_TBL")
BEGIN
/*** Parameters *****/
    truncate TABLE #PAL_PARAMETER_TBL;
	INSERT INTO #PAL_PARAMETER_TBL VALUES ('THREAD_RATIO',null,0.8,null);

    /*** Table variables *****/
    lt_parms = SELECT * FROM #PAL_PARAMETER_TBL;
    lt_predictdata = select D."TRANSACTION_ID", "ORIGIN", "CLASS", "AMOUNT", "OLD_BALANCE_ORIGIN", "NEW_BALANCE_ORIGIN", "DESTINATION", "OLD_BALANCE_DEST", "NEW_BALANCE_DEST"
                     from TRANSACTIONSV as D,  "#PAL_PARTITION_RESULT_TBL" AS P  where D.TRANSACTION_ID = P.TRANSACTION_ID and P.PARTITION_TYPE = 2;
    lt_model = SELECT * FROM :IN_MODELT;
   
   /*** PAL function call *****/
   CALL _SYS_AFL.PAL_PIPELINE_PREDICT(:lt_predictdata, :lt_model, :lt_parms, out_0, out_1);
   
     /*** Results *****/
  	IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_AUTOML_RESULT_RESULT_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_AUTOML_RESULT_RESULT_TBL;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_AUTOML_RESULT_RESULT_TBL" AS (SELECT * FROM :out_0);
    IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_AUTOML_INFO_RESULT_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_AUTOML_INFO_RESULT_TBL;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_AUTOML_INFO_RESULT_TBL" AS (SELECT * FROM :out_1);

END /*WITH HINT (WORKLOAD_CLASS("<my workload class>"))*/;

SELECT * FROM #PAL_AUTOML_RESULT_RESULT_TBL;
SELECT Count(*), SCORES FROM #PAL_AUTOML_RESULT_RESULT_TBL GROUP BY SCORES;


/***********************************************************************************************************************************************************/
-- Step 6 - We could, now also only re-fit the best found pipeline, instead of running the full AutoML ;

DO BEGIN
	/*** Parameters *****/
    truncate TABLE #PAL_PARAMETER_TBL;
	INSERT INTO #PAL_PARAMETER_TBL select 'PIPELINE', NULL, NULL, PIPELINE from  #PAL_AUTOML_BEST_PIPELINE_TBL WHERE ID = 0;

    /*** Table variables *****/
    lt_parms = SELECT * FROM #PAL_PARAMETER_TBL;
    lt_fitdata = select D.*   from TRANSACTIONSV as D,  "#PAL_PARTITION_RESULT_TBL" AS P  where D.TRANSACTION_ID = P.TRANSACTION_ID and P.PARTITION_TYPE = 1;

	CALL _SYS_AFL.PAL_PIPELINE_FIT(:lt_fitdata, :lt_parms, lt_model, lt_pinfo);
    IF EXISTS(SELECT * FROM M_TEMPORARY_TABLES WHERE TABLE_NAME = '#PAL_AUTOML_REFIT_MODEL_TBL' AND SCHEMA_NAME = CURRENT_SCHEMA AND CONNECTION_ID = CURRENT_CONNECTION) 
	      THEN DROP TABLE #PAL_AUTOML_REFIT_MODEL_TBL;
	   END IF;
       CREATE LOCAL TEMPORARY COLUMN TABLE "#PAL_AUTOML_REFIT_MODEL_TBL" AS (SELECT * FROM :lt_model);
      
END /*WITH HINT (WORKLOAD_CLASS("<my workload class>"))*/;

select * from #PAL_AUTOML_REFIT_MODEL_TBL;


/***********************************************************************************************************************************************************/
-- Appendix - Monitoring AutoML executions ;

-- Runtime Monitoring views (emptied after execution finished)
SELECT * 	FROM _SYS_AFL.FUNCTION_PROGRESS_IN_AFLPAL  
			ORDER BY PROGRESS_TIMESTAMP DESC, PROGRESS_ELAPSEDTIME DESC, PROGRESS_CURRENT ASC
            /*WHERE EXECUTION_ID = 'AutoMLFit-Transaction_Fraud_ClassModel-<my-userid>'*/;

-- PAL Content, persisted manageable execution log views;
SELECT * 	FROM	     PAL_CONTENT.AUTOML_LOG;
SELECT * 	FROM		 PAL_CONTENT.EXECUTION_FACT;

-- PAL Content, cleanup of individual executions;
DO
BEGIN
	DECLARE param_tbl TABLE(PARAM_NAME NVARCHAR(256), INT_VALUE INTEGER, DOUBLE_VALUE DOUBLE, STRING_VALUE NVARCHAR(1000));
	DECLARE removed_execution_info TABLE(EXECUTION_ID NVARCHAR(128), CREATED_BY NVARCHAR(256), CREATED_AT TIMESTAMP, IS_FINISHED INTEGER);
	:param_tbl.INSERT(('REMOVE_MODE', 0, NULL, NULL));
	:param_tbl.INSERT(('EXECUTION_ID', NULL, NULL, 'AutoMLFit-Fraud_ClassModel-<my-userid> 2024-09-26 18:56:58.3370000'));
	:param_tbl.INSERT(('IS_FORCE', 0, NULL, NULL));
	
	CALL _SYS_AFL.PAL_REMOVE_AUTOML_LOG(:param_tbl, removed_execution_info);
	SELECT * FROM :removed_execution_info;
END;

