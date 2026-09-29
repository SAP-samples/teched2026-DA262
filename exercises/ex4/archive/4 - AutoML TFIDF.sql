
/*****************************************************************************************************************************************************************/
/*** Use case demo - Service Ticket Classification from Ticket Text **********************************************************************************************/
/*****************************************************************************************************************************************************************/
SET SCHEMA MLLAB_03;

/*** Explore the Service Ticket data set *************************************************************************************************************************/
SELECT Top 100 ID, LABEL_STR, TICKET_TEXT FROM   "IT_SERVICE_TICKETS_TRAIN" order by ID;
SELECT LABEL_STR, count(*) FROM "IT_SERVICE_TICKETS_TRAIN" GROUP BY LABEL_STR;













/*** Build a AutoML pipeline model for Service Ticket Classification - semantically understanding Ticket_Text using Text Feature Embeddings ***********************/
DO BEGIN
  DECLARE lt_param TABLE(name NVARCHAR(50), int_value INTEGER, double_value DOUBLE, string_value NVARCHAR(5000));
  :lt_param.INSERT(('PIPELINE_TYPE', null, null, 'classifier'));
  :lt_param.INSERT(('HAS_ID', 1, null, null));
  :lt_param.INSERT(('DEPENDENT_VARIABLE', null, NULL, 'LABEL_STR'));
  :lt_param.INSERT(('TEXT_VARIABLE', null, NULL, 'TICKET_TEXT'));
  :lt_param.INSERT(('CONFIG_DICT', null, null, '{"HGBT_Classifier": {"ITER_NUM": [100, 50], "MAX_DEPTH": {"range": [1, 1, 11]}, "ETA": [0.01, 0.1, 0.05], "NODE_SIZE": {"range": [1, 1, 21]}}, 
                                               "MLP_M_TASK_Classifier": {"NETWORK_TYPE": [0], "HIDDEN_LAYER_ACTIVE_FUNC": [1, 2], "HIDDEN_LAYER_SIZE": ["5, 5", "10, 10, 10"], "TRAINING_STYLE": [0, 1], "LEARNING_RATE": [0.001, 0.01, 0.1, 0.5, 0.99], "NORMALIZATION": [1], "OPTIMIZER": [0, 2], "MAX_ITERATION": [1000]}, 
                                               "RDT_Classifier": {"TREES_NUM": [100], "NODE_SIZE": {"range": [1, 1, 21]}, "CALCULATE_OOB": [0], "SAMPLE_FRACTION": [0.75, 1.0]}, 
                                               "TextEmbedding": {"MODEL_VERSION": ["SAP_GXY.20250407"], "PCA_DIM_NUM": [64, 128, 256]}, 
                                               "TFIDF": {"LANGUAGE": ["EN"], "EMBED_DIM": [64, 128, 256]}}'));
  :lt_param.INSERT(('VERIFY_CONFIG', 1, null, null));
  :lt_param.INSERT(('SEARCH_METHOD', null, null,'GA'));
  :lt_param.INSERT(('GENERATIONS', 10, null, null));
  :lt_param.INSERT(('POPULATION_SIZE', 100, null, null));
  :lt_param.INSERT(('OFFSPRING_SIZE', 25, null, null));
  :lt_param.INSERT(('MAX_EVAL_TIME_MINS', null, 1.0, null));
  :lt_param.INSERT(('SUCCESSIVE_HALVING', 1, null, null)); 
  :lt_param.INSERT(('EARLY_STOP', 5, null, null));

  :lt_param.INSERT(('RESAMPLING_METHOD', null, null,'stratified_cv'));
  :lt_param.INSERT(('FOLD_NUM', 3, null, null));
  :lt_param.INSERT(('RANDOM_SEED', 1234, null, null));  
  
  :lt_param.INSERT(('SCORINGS', null, null,'{"ACCURACY": 1.0, "AUC": 1.0}'));
  :lt_param.INSERT(('ELITE_NUMBER', 15, null, null));
  
  lt_data = SELECT ID,  TICKET_TEXT, LABEL_STR FROM "IT_SERVICE_TICKETS_TRAIN_MINI" ;

  CALL _SYS_AFL.PAL_AUTOML_FIT(:lt_data, :lt_param, lt_pipelines, lt_model, lt_stats);
 
  SELECT * FROM :lt_pipelines;
  SELECT * FROM :lt_model;
  SELECT * FROM :lt_stats;
  --CREATE COLUMN TABLE "AUTOML_MODEL_TBL_TICKET_TEXT_CLASSIFIER2" AS (SELECT * FROM :lt_model);
END; --51secs;





/*** Evaluate the predictive quality of the Service Ticket Classification pipeline model (utilizing Text Feature Embeddings) ******************************************/
DO (IN in_pipeline_model TABLE ("ROW_INDEX" INT, "MODEL_CONTENT" NVARCHAR(5000)) => "AUTOML_MODEL_TBL_TICKET_TEXT_CLASSIFIER2")
BEGIN
  DECLARE lt_param TABLE(name NVARCHAR(50), int_value INTEGER, double_value DOUBLE, string_value NVARCHAR(5000));
  :lt_param.INSERT(('HAS_ID', 1, null, null));
  lt_data = SELECT  "ID", "TICKET_TEXT", "LABEL_STR"  FROM "IT_SERVICE_TICKETS_TEST_MINI" ;

  CALL _SYS_AFL.PAL_PIPELINE_SCORE(:lt_data, :in_pipeline_model, :lt_param, lt_prediction, lt_stats, out_misc1, out__misc2);
  --SELECT ID, SCORE, CONFIDENCE FROM :lt_prediction;
  SELECT pred."ID", "LABEL_STR", SCORE AS "PRED_LABEL", "CONFIDENCE", "TICKET_TEXT" 
		FROM :lt_prediction pred, :lt_data act
    	WHERE pred."ID"=act."ID";
	SELECT * FROM :lt_stats;
END;












/*** Predict the Service Ticket Class using the Service Ticket Classification pipeline model (utilizing Text Feature Embeddings) ****************************************/
DO (IN in_pipeline_model TABLE ("ROW_INDEX" INT, "MODEL_CONTENT" NVARCHAR(5000)) => "AUTOML_MODEL_TBL_TICKET_TEXT_CLASSIFIER2")
BEGIN
  DECLARE lt_param TABLE(name NVARCHAR(50), int_value INTEGER, double_value DOUBLE, string_value NVARCHAR(5000));
  lt_data = SELECT "ID", "TICKET_TEXT" FROM  "IT_SERVICE_TICKETS_TEST_MINI";

  CALL _SYS_AFL.PAL_PIPELINE_PREDICT(:lt_data, :in_pipeline_model, :lt_param, lt_prediction, lt_info);
  SELECT * FROM :lt_prediction;
  --SELECT * FROM :lt_info;
END;

