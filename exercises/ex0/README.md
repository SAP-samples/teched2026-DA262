# Getting Started - prepare your local VS Code environment

In this SAP TechEd 2026 Hands-on Workshop __Get hands-on with tabular AI- and forecasting-models in SAP HANA Cloud__ (DA262), the exercises are to be pursued by using the __SAP HANA Cloud Database Explorer__ , an __Python Jupyter Notebooks__ both in __Visual Studio Code__.
<br><br>

### You will work with the following technical environment
- a centrally provided __SAP HANA Cloud database system__ 
  - with your personal user-id and schema, with full access to the objects in your database user schema
  - shared data provided within a separate, read-only, schema __DA262_SHARE__
- a __SQL console__ and database tools within a provided __SAP HANA Cloud Database Explorer__ instance (referred to as __DBX__),
  - _The SAP HANA Cloud database explorer is a extension plug-in to Visual Studio Code for browsing and working with SAP HANA database objects such as tables, views, functions, stored procedures. In addition, DBX can be used to import and export data, execute SQL statements, create remote sources, work with multi-model data such as graph, spatial and JSON collections, view trace files, and any other SQL activity._
- and a __Python Jupyter Notebook environment__ within a provided __Visual Studio Code__ instance (referred to as __VS Code__)

The technical requirements to complete the exercises in this repository, including hardware and software specifications are taken care of by the provided systems used for the in-person Hands-on Workshop. 

The remaining  _setup and configuration tasks_ are outlined in the [Getting Started - prepare your local VS Code environment](exercises/ex0/) section below.

## Step 1 - Prepare VS Code
- Download [DA262 Student Workspace.zip](https://github.com/SAP-samples/teched2026-DA262/blob/main/exercises/ex0/setup/DA262%20Student%20Workspace.zip)
<br>![](/exercises/ex0/images/26_ex0-1_download_workspace.png)
- Copy from Downloads to Documents in Windows Explorer
- From the context menue, select __Extract all__ 
<br>![](/exercises/ex0/images/26_ex0-2_extract_workspace.png)
- Accept the default path __C:\Users\<user>\Documents\DA262 Student Workspace__ and confirm by clicking __extract__
- The extracted folder looks likes
<br>![](/exercises/ex0/images/26_ex0-3_extracted_workspace.png)
- open cmd
<br>![](/exercises/ex0/images/26_ex0-4_open_cmd.png)
- Confirm *to allow to make changes* with __Yes__
- Now 
sql
mklink /d "%USERPROFILE%\Documents\DA262 Student Workspace\.venv-DA262\Lib" "C:\Software\DA262\.venv-DA262\Lib"
'''
<br>![](/exercises/ex0/images/26_ex0-5_create_link.png)

- Now open VS Code
<br>![](/exercises/ex0/images/26_ex0-6_open_vscode.png)

- VS Code extensions
<br>![](/exercises/ex0/images/26_ex0-7_vsc_extensions.png)

- inst DBX
<br>![](/exercises/ex0/images/26_ex0-8_inst_dbx.png)

- open workspace
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace1.png)
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace2.png)
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace3.png)




## Step 2 - Prepare to work with the HANA database explorer
- __Open__ the SAP HANA Database Explorer  
- Open SAP HANA Database Explorer and create a SAP HANA database connection
<br>![](/exercises/ex0/images/26_ex0s2-1_open_dbx.png)
- select to add a local connection
<br>![](/exercises/ex0/images/26_ex0s2-1_local_conn.png)

-- In the next __Sign In__ step, __enter__ the __UserId__ and __password__ provided to you by the workshop instructor and __according to your desk-id__
  - User ID: \<as provided, example __AC######U##__\>
  - Password: \<as provided\> 
  - Then select __Continue__.
<br> 

Add connection
- Host 6fe84328-0463-41c5-b0ee-90461d77272b.hna3.prod-eu10.hanacloud.ondemand.com
- User DA262_###
- Password welCome!26

- specify conn details and then Add Database
<br>![](/exercises/ex0/images/26_ex0s2-3_conn_details.png)
- Review the connection shows up under local connections
- Now, once the login to SAP HANA Database Explorer application was successful
-  __Now, the SAP HANA Database Explorer is ready to be used__:
- Select Open SAP HANA SQL Console
-  Open a SQL editor
<br>![](/exercises/ex0/images/26_ex0s2-4_open_SQLconsole.png)
- Copy and paste the following SQL example into the SQL Console
- Execute the following SQL query
```sql
/*** Test SAP HANA Cloud connection and SQL console - Check for remote sources defined in the instance ***/
SELECT * FROM REMOTE_SOURCES;
```

- run the statement
<br>![](/exercises/ex0/images/26_ex0s2-5_runSQL.png)

- review the result
<br>![](/exercises/ex0/images/26_ex0s2-6_query_result.png)

## Step 3 - Prepare to work with the Python environment
During this step, you will prepare the connection details for the Python to SAP HANA Cloud connection and validate the connection.

<br><br>
### To start with the exercise

Prepare the HANA Cloud database connection properties
For our convenience, we will prepare the database connection credentials within a *.ini-file, which we can easily consume from the Python notebooks and avoid repeated crendential prompting.

- Edit the user connection details, therefore open the user.ini file in VS Code
- - Edit and enter the __user__ and the __password__ given to you by the instructor in __user.ini__-file 
   - save the file
<br>![](/exercises/ex0/images/26_ex0s3-1_userini.png)



- open the notebook file __ex1_notebook.ipynb__ from the project explorer
  - from the context menu, select open
  - ![](/exercises/ex0/images/26_ex0s3-2_opencheckpythonnb.png)
- The notbook then opens
  ![](/exercises/ex0/images/26_ex0s3-3_checkpythonnb.png)
<br><br>

- select kernel
![](/exercises/ex0/images/26_ex0s3-4_selectkernel.png)
![](/exercises/ex0/images/26_ex0s3-5_selectkernel2.png)

- run cells
![](/exercises/ex0/images/26_ex0s3-6_run_cells.png)

-check
![](/exercises/ex0/images/26_ex0s3-7_check_result1.png)
![](/exercises/ex0/images/26_ex0s3-7_check_result2.png)
![](/exercises/ex0/images/26_ex0s3-7_check_result3.png)

### Furthermore, throughout the exercise, 
- you will be asked to __review__ and __adjust/edit__ the python code within the notebook code-cells
    ![](/exercises/ex0/images/26_ex0s3-9_nbk_edit.png)  

and then execute the notebook cells
- you should start executing each cell individually using the Play-icon to the left of the cell, , 
    ![](/exercises/ex0/images/26_ex0s3-6_run_cells.png)
- at a later point, you may execute all cells following the current one, using the Play-icon with the Top-Down-arrow in the right upper corner of the cell.

<br>

### Keep the overview
Once the notebook file is opened,
- you can open the __Outline-View__ by clicking __Outline__ in the header of the notebook, 
- the notebook __Outline-View__ then opens to the left, and is helpful for oversight and navigation through the content of the notebook-file 
- You can arrange the size of outline-view to your needs.
<br>![](/exercises/ex0/images/26_ex0s3-8_overview.png)




## Summary

Now that you have ...  
Continue to - [Exercise 1 - Generate time series forecasts on-the-fly using using SAP-RPT-TS from SAP HANA Cloud](../ex1/README.md)
