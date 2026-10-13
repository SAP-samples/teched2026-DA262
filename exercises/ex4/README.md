# Note this exercise is OPTIONAL 

# Exercise 4 - Build a service ticket intelligence classification model using AutoML and raw text features

This exercise builds upon a previous years SAP TechEd  Hands-on Workshop [github.com/SAP-archive/teched2020-INT260](https://github.com/SAP-archive/teched2020-INT260) around a __Service Ticket Intelligence__-use case on __travel agency service tickets__ [ex2-STI](https://github.com/SAP-archive/teched2020-INT260/blob/main/exercises/ex2-STI/ex2.2/README.md), resumed here leveraging capabilities purely out of SAP HANA Cloud __AI function library (AutoML with the Predictive Analysis Library PAL)__ and __Text Embedding Models from the NLP services__ in SAP HANA Cloud.

## Exercise 4 - Use case scenario overview
Building a Travel Service Ticket classification model using Text Embeddings and AutoML functions
- the scenario includes the following four tasks
<br>![](/exercises/ex4/images/ex4_scenario_overview.png)

## Start the exercise
- Open the notebook file __ex04_notebook.ipynb__ from the project explorer
<br>![](/exercises/ex4/images/26ex40-1_open_nbk.png) 
<br>  

- On the top right, if the default kernel is already detected as ![](/exercises/ex0/images/26_ex0s3-4_defaultkernel.png), proceed with Ex 4.0
  - Otherwise Select the Python KernelSelect the Python Kernel
<br>![](/exercises/ex4/images/26ex40-2_select_kernel.png)
<br>  

  - Select the prepared __.venv-DA262__ Python Kernel
<br>![](/exercises/ex0/images/26_ex0s3-5_selectkernel2.png)
<br>  

- Next, to pursue the exercise, execute the cells step by step, by clicking the __run cell-icon ">"__ as highlighted
<br>![](/exercises/ex1/images/26ex10-4_exec_cells.png)

Proceed through the exercise sections and run the cells from top to bottom.

<br> <br> 

The following exercise descriptions, just give a high-level exercise overview, all the instructions and explanations are part of the notebook file __ex04_notebook.ipynb__ itself.





## Ex. 4.0 - Connect to your SAP HANA Cloud instance
- The outline-view on the lower left in Visual Studio code, overviews the exercise sections and steps 
<br>![](/exercises/ex4/images/26ex40-outline.png)


- In __Step 0__ you first create the connection to SAP HANA Cloud, and shows successful message like
<br>![](/exercises/ex3/images/26ex30-3connect.png)



## Exercise 4.1 Exploring Travel Service Ticket data using SAP HANA Dataframes
- Steps in this exercise section 
<br>![](/exercises/ex4/images/26ex41-outline.png)

<br>

- In __Step 1__ you will load the travel-data csv file to a SAP HANA Cloud table and create a HANA dataframe and explore the data set, explore travel ticket catgory frequencies and more
<br>![](/exercises/ex4/images/26ex41-load_hdf.png)

<br>
<br>

## Exercise 4.2 Building a AutoML classification model for Travel Service Tickets
- Steps in this exercise section 
<br>![](/exercises/ex4/images/26ex42-outline.png)

<br>

- In __Step 2__  you will split the dataset and sample a hold-out dataset, for evaluating trained model later with data, not used during model training
<br>![](/exercises/ex4/images/26ex42-1_split.png)

<br>

- In __Step 3__ we will define the AutoML classification scenario, customize the relevant operators and its parameters, and then start the AutoML-fit task to determine the model for the travel service ticket category predictions
  - Define the AutoML classification scenario
<br>![](/exercises/ex4/images/26ex42-2_automl.png)
  - Review a customized list of algorithm operators to be considered for the model
<br>![](/exercises/ex4/images/26ex42-2_automl_operators.png)
  - Observe the fit-call with the __text_variable__ parameter the execution with PipelineProgressMonitor
    -  within the Generation Details-Tab and the very bottom you will see the details of the Best AutoML Pipeline model
<br>![](/exercises/ex4/images/26ex42-2_automl_progress.png)

## Exercise 4.3 Evaluate the AutoML model accuracy
- Steps in this exercise section 
<br>![](/exercises/ex4/images/26ex43-outline.png)

<br>

- In __Step 4__  you will evaluate the best AutoML pipeline model's prediction accuracy using the __score()-method__ and the hold-out sample
<br>![](/exercises/ex4/images/26ex43-1_score.png)

<br>

- The resulting accuracy metrics can be explored from the statistics output and the confusion matrix visualization
<br>![](/exercises/ex4/images/26ex43-2_acc_cm.png)


## Exercise 4.4 Predicting with the AutoML classification model
- Steps in this exercise section 
<br>![](/exercises/ex4/images/26ex44-outline.png)

<br>

- In __Step 5__  you will apply the trained pipeline model to predict the service ticket class to new service tickets (here sampled from the hold-out dataset) using the __predict()-method__.
<br>![](/exercises/ex4/images/26ex44-1_predict.png)

## Summary

You've now build a complete __travel service ticket classification ML model__, leveraging capabilities purely out of SAP HANA Cloud, the AutoML engine and algorithms from the Predictive Analysis Library (PAL) as well as automatically and implicitly the Text Embedding Models from the NLP services in SAP HANA Cloud converting the raw text service ticket column into vector-embedding feature within the AutoML modelling.

<br><br>
---
Congratulations, you've finished all exercises!

