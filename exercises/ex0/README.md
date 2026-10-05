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
  Path to direct download of the Workspace file is: https://github.com/SAP-samples/teched2026-DA262/blob/main/exercises/ex0/setup/DA262%20Student%20Workspace.zip
<br>![](/exercises/ex0/images/26_ex0-1_download_workspace.png)

<br>

- Copy the __DA262 Student Workspace.zip-file__ from the ![](/exercises/ex0/images/26_ex0-1_downloads_folder.png) folder in the Windows Explorer to the Windows ![](/exercises/ex0/images/26_ex0-1_documents_folder.png) folder

<br>

- From the context menue (right mouse button), select __Extract all__ 
<br>![](/exercises/ex0/images/26_ex0-2_extract_workspace.png)

<br>

- Accept the default path __C:\Users\<user>\Documents\DA262 Student Workspace__ and confirm by clicking __extract__

<br>

- The extracted folder looks likes
<br>![](/exercises/ex0/images/26_ex0-3_extracted_workspace.png)

<br>

- Next, open windows default __cmd__-prompt AND select __Run as Administrator__ from the context menue (right mouse button)
<br>![](/exercises/ex0/images/26_ex0-4_open_cmd.png)

<br>

- Confirm `*to allow to make changes*` with __Yes__

<br>

- Now COPY the following command and PASTE it into the cmd-prompt. 
```cmd
mklink /d "%USERPROFILE%/Documents/DA262 Student Workspace/.venv-DA262/Lib" "C:/Software/DA262/.venv-DA262/Lib"
```
- Execute the command by pressing the RETURN- or ENTER-key
<br>![](/exercises/ex0/images/26_ex0-5_create_link.png)

<br>

- Now open **VS Code**
<br>![](/exercises/ex0/images/26_ex0-6_open_vscode.png)

<br>

- Validate the **VS Code extensions**, select **Extensions** from the left menue bar
<br>![](/exercises/ex0/images/26_ex0-7_vsc_extensions.png)

- In the **Extensions Marketplace** search prompt, search for **SAP HANA Database Explorer**, and select **Install** on the right, if the plug-in in not yet installed
<br>![](/exercises/ex0/images/26_ex0-8_inst_dbx.png)

<br>

- Finally, from the **File**-menue, select **Open Workspace from File**
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace1.png)

<br>

- Select the file **DA262 Student Workspace.code-workspace**
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace2.png)

<br>

- Now your **DA262 Student Workspace** is prepared and open in VS Code
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace3.png)




## Step 2 - Prepare to work with the HANA database explorer
- In __VS Code__, __open__ the SAP HANA Database Explorer  
- Open SAP HANA Database Explorer by **clicking** on the **icon** on the left menue bar, then in the **Database List** view select **+** to **Add SAP HANA Database** connection
<br>![](/exercises/ex0/images/26_ex0s2-1_open_dbx.png)

<br>

- When prompted, select to **add a Local Connection**, which are stored locally in the VS Code storage
<br>![](/exercises/ex0/images/26_ex0s2-1_local_conn.png)

<br>

- In the **Add a SAP HANA Database** details windows, __enter__ the __UserId__ and __password__ provided to you by the workshop instructor and __according to your desk-id__
  - Select Database Type as **SAP HANA Cloud**
  - Host **6fe84328-0463-41c5-b0ee-90461d77272b.hna3.prod-eu10.hanacloud.ondemand.com**
  - User **DA262_###** (replace ### accordingly with a 3-digit desk-id)
  - Password **welCome!26**
  - Select **Save Password**
  - Select **Connect to database securly using TLS/SSL***

- specify connection details and once finished select **Add Database** on the top right corner
<br>![](/exercises/ex0/images/26_ex0s2-3_conn_details.png)

<br>

- The new connection will now show up under local connections

-  __Now, the SAP HANA Database Explorer is ready to be used__ and can be tested, therefore:
   - Select **Open SAP HANA SQL Console** to open a SQL editor
<br>![](/exercises/ex0/images/26_ex0s2-4_open_SQLconsole.png)

<br>

- Copy and paste the following SQL example into the SQL Console
```sql
/*** Test SAP HANA Cloud connection and SQL console - Check for remote sources defined in the instance ***/
SELECT * FROM REMOTE_SOURCES;
```
- Execute the following SQL query, by selecting **Run** or pressing **F8** key
<br>![](/exercises/ex0/images/26_ex0s2-5_runSQL.png)

- Finally, review the result of the SQL query
<br>![](/exercises/ex0/images/26_ex0s2-6_query_result.png)

<br>
<br>

## Step 3 - Prepare to work with the Python environment
During this step, you will prepare the connection details for the Python to SAP HANA Cloud connection and validate the connection.

__Prepare the HANA Cloud database connection properties__  
For our convenience, we will prepare the database connection credentials within a **user.ini-file**, which we can easily consume from the Python notebooks and avoid repeated credential prompting.

- Switch back to the **project explorer** in the left menue bar on the left, 
<br>![](/exercises/ex0/images/26_ex0s3-0.png)
- then from project-tree **/ex0**-folder, open the **user.ini file** by **Clicking** on it, when it then opens to edit the user connection details
- Edit the __user__ and the __password__ given to you in the __user.ini__-file 
  -  User **DA262_###** (replace ### accordingly with a 3-digit desk-id)
  - Password **welCome!26**
<br>![](/exercises/ex0/images/26_ex0s3-1_userini.png)
 - **Save** the file (menue File>save)

<br>

- Now, in order to validate the connection, open the notebook file __ex0 - check Python setup and SAP HANA Cloud connection.ipynb__ from the project explorer
  - from the context menu, select open
  - ![](/exercises/ex0/images/26_ex0s3-2_opencheckpythonnb.png)
- The notbook then opens
  ![](/exercises/ex0/images/26_ex0s3-3_checkpythonnb.png)
<br><br>

- On the top right, click select **Select Kernel**
<br>![](/exercises/ex0/images/26_ex0s3-4_selectkernel.png)
- Select the prepared __.venv-DA262__ Python Kernel
<br>![](/exercises/ex0/images/26_ex0s3-5_selectkernel2.png)

<br>

- In order to **execute** the **Python Code-cells** step by step, best **click** the __run cell-icon ">"__ as highlighted **left** to the cell
![](/exercises/ex0/images/26_ex0s3-6_run_cells.png)

<br>

- Now, execute the **Python Code-cells** in the opened notebook __ex0 - check Python setup and SAP HANA Cloud connection.ipynb__, and validate that
  - **hana_ml** package is successfully loaded
![](/exercises/ex0/images/26_ex0s3-7_check_result1.png)
  - **user.ini-file** has been successfully processed
![](/exercises/ex0/images/26_ex0s3-7_check_result2.png)
   - **SAP HANA Cloud connection** has been successfully established
![](/exercises/ex0/images/26_ex0s3-7_check_result3.png)


<br>

__Keep the OVERVIEW__ in the Python Notebook
- Once a notebook file is opened,
- you can open the __Outline-View__ by clicking ![](/exercises/ex0/images/26_ex0s3-8_overview2.png) in the header of the notebook, 
- the notebook __Outline-View__ then opens to the left, and is helpful for **oversight** and **navigation** through the content of the notebook-file 
- You can arrange the size of outline-view to your needs.
<br>![](/exercises/ex0/images/26_ex0s3-8_overview.png)


### Troubleshoot Workspace Trust
- If it happens, that you see **Manage workspace trust** or **Restricted Mode** messages and popups
  - "Restricted Mode messages"
![](/exercises/ex0/images/26_ex0_workspacetrust_1.png)
  - you can manage to set workspace trust to the **DA262 Workspace**-folders as following, click **Restricted Mode** at the lower left
![](/exercises/ex0/images/26_ex0_workspacetrust_2.png)
  - Click **Trust**
![](/exercises/ex0/images/26_ex0_workspacetrust_3.png)
  - Review Folder and **Close** on the top-right **X**
<br>![](/exercises/ex0/images/26_ex0_workspacetrust_4.png)

## Summary

Now that you have successfully prepared all the setup steps, continue to - [Exercise 1 - Generate time series forecasts on-the-fly using using SAP-RPT-TS from SAP HANA Cloud](../ex1/README.md)
