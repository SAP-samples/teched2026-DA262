# Exercise 0 — Getting Started: prepare your local VS Code environment

In this SAP TechEd 2026 Hands-on Workshop **"Get hands-on with tabular AI- and
forecasting-models in SAP HANA Cloud"** (DA262), you will work with Python Jupyter
Notebooks and the SAP HANA Database Explorer, both inside Visual Studio Code.

This exercise sets up your local environment in three steps so you are ready for
Exercises 1 through 4.

<br>

> ⚠️ **Your desk number**
> Every screen in this workshop shows `DA262_###`.
> Replace `###` with **your desk number** (printed on your desk card) everywhere you
> see it — in the database connection, in the `user.ini` file, and in any SQL console.

<br>

> ⚠️ **Workspace trust prompt**
> When you first open the student workspace, VS Code may ask whether you trust the
> folder. Click **Yes, I trust the authors** on all prompts — the notebooks will not
> run otherwise.
> <br>![](/exercises/ex0/images/26_ex0_workspacetrust_1.png)
> <br>![](/exercises/ex0/images/26_ex0_workspacetrust_2.png)
> <br>![](/exercises/ex0/images/26_ex0_workspacetrust_3.png)
> <br>![](/exercises/ex0/images/26_ex0_workspacetrust_4.png)

<br>

---

## What you will achieve

- Extract the student workspace and link the Python virtual environment
- Install the SAP HANA Database Explorer extension in VS Code
- Connect to the shared SAP HANA Cloud database instance
- Confirm Python can connect to SAP HANA Cloud and returns `True`

<br>

## Your technical environment

| What | Detail |
|------|--------|
| SAP HANA Cloud database | Centrally provided — shared for all workshop participants |
| Your personal schema | `DA262_###` — full access to create and manage your own objects |
| Shared data schema | `DA262_SHARED` — read-only, contains all exercise datasets |
| Tools | SAP HANA Database Explorer (VS Code extension) + Python Jupyter Notebooks |
| Python package | hana-ml 2.30 |

<br>

---

## Step 1 — Prepare VS Code

- Download [DA262 Student Workspace.zip](https://github.com/SAP-samples/teched2026-DA262/blob/main/exercises/ex0/setup/DA262%20Student%20Workspace.zip)
<br>![](/exercises/ex0/images/26_ex0-1_download_workspace.png)

- Copy the downloaded zip from your **Downloads** folder to your **Documents** folder
  in Windows Explorer

- Right-click the zip file and select **Extract all**
<br>![](/exercises/ex0/images/26_ex0-2_extract_workspace.png)

- Accept the default path `C:\Users\<user>\Documents\DA262 Student Workspace`
  and click **Extract**

- The extracted folder looks like this:
<br>![](/exercises/ex0/images/26_ex0-3_extracted_workspace.png)

- Open a **Command Prompt as Administrator**
<br>![](/exercises/ex0/images/26_ex0-4_open_cmd.png)

- Click **Yes** when asked to allow changes

- Run the following command to link the Python virtual environment:
```cmd
mklink /d "%USERPROFILE%\Documents\DA262 Student Workspace\.venv-DA262\Lib" "C:\Software\DA262\.venv-DA262\Lib"
```
<br>![](/exercises/ex0/images/26_ex0-5_create_link.png)

- Open **Visual Studio Code**
<br>![](/exercises/ex0/images/26_ex0-6_open_vscode.png)

- Open the **Extensions** panel (Ctrl+Shift+X)
<br>![](/exercises/ex0/images/26_ex0-7_vsc_extensions.png)

- Search for **SAP HANA Database Explorer** and click **Install**
<br>![](/exercises/ex0/images/26_ex0-8_inst_dbx.png)

- Open the student workspace: **File → Open Workspace from File**
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace1.png)
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace2.png)
<br>![](/exercises/ex0/images/26_ex0-9_open_workspace3.png)

<br>

---

## Step 2 — Connect to the SAP HANA Database Explorer

- Open the **SAP HANA Database Explorer** panel in VS Code
<br>![](/exercises/ex0/images/26_ex0s2-1_open_dbx.png)

- Click **Add Database** and select **Add a local database connection**
<br>![](/exercises/ex0/images/26_ex0s2-1_local_conn.png)

- Enter your connection details exactly as shown below:

| Field | Value |
|-------|-------|
| Host | `6fe84328-0463-41c5-b0ee-90461d77272b.hna3.prod-eu10.hanacloud.ondemand.com` |
| Port | `443` |
| User | `DA262_###` _(replace ### with your desk number)_ |
| Password | `welCome!26` |

<br>![](/exercises/ex0/images/26_ex0s2-3_conn_details.png)

- Click **Add Database** — your connection appears under **Local Connections**

- Right-click your connection and select **Open SQL Console**
<br>![](/exercises/ex0/images/26_ex0s2-4_open_SQLconsole.png)

- Paste the following SQL and click **Run** (▶):
```sql
SELECT * FROM REMOTE_SOURCES;
```
<br>![](/exercises/ex0/images/26_ex0s2-5_runSQL.png)

<br>

> ✅ **Expected result:** You should see at least one row. Look for a row with
> `REMOTE_SOURCE_NAME = 'DA262_AICORE_RPT16'` — this confirms the AI Core
> connection is ready for Exercise 2.
> <br>![](/exercises/ex0/images/26_ex0s2-6_query_result.png)

<br>

---

## Step 3 — Validate the Python connection to SAP HANA Cloud

- Open `exercises/ex0/user.ini` in VS Code

- Replace `###` with your desk number and save the file:
```ini
[hana]
url=6fe84328-0463-41c5-b0ee-90461d77272b.hna3.prod-eu10.hanacloud.ondemand.com
user=DA262_###
passwd=welCome!26
port=443
```
<br>![](/exercises/ex0/images/26_ex0s3-1_userini.png)

- Open the notebook `ex0 - check Python setup and SAP HANA Cloud connection.ipynb`
  from the project explorer
<br>![](/exercises/ex0/images/26_ex0s3-2_opencheckpythonnb.png)

- The notebook opens in VS Code
<br>![](/exercises/ex0/images/26_ex0s3-3_checkpythonnb.png)

- When prompted to select a kernel, choose **.venv-DA262**
<br>![](/exercises/ex0/images/26_ex0s3-4_selectkernel.png)
<br>![](/exercises/ex0/images/26_ex0s3-5_selectkernel2.png)

- Click **Run All** to execute every cell
<br>![](/exercises/ex0/images/26_ex0s3-6_run_cells.png)

<br>

> ✅ **Expected result:** All three checks must pass:
> - hana-ml version printed (2.30)
> - `Connection to SAP HANA Cloud successful is: True`
> - Current timestamp from the database
>
> <br>![](/exercises/ex0/images/26_ex0s3-7_check_result1.png)
> <br>![](/exercises/ex0/images/26_ex0s3-7_check_result2.png)
> <br>![](/exercises/ex0/images/26_ex0s3-7_check_result3.png)
>
> If you see `False` or an error, double-check the `user.ini` file —
> the most common cause is a typo in the user name or password.

<br>

---

## Navigating notebooks

Once a notebook is open, click **Outline** in the notebook header to open the
outline panel on the left — useful for navigating longer notebooks.
<br>![](/exercises/ex0/images/26_ex0s3-8_overview.png)

Run cells individually with the **play icon** next to each cell, or run all
cells at once with the **Run All** button in the toolbar.
<br>![](/exercises/ex0/images/26_ex0s3-9_nbk_edit.png)

<br>

---

## Summary

Your environment is now ready. You have:

| Done | What |
|------|------|
| ✅ | Extracted the student workspace and linked the Python virtual environment |
| ✅ | Installed the SAP HANA Database Explorer extension in VS Code |
| ✅ | Connected to SAP HANA Cloud and verified the AI Core remote source |
| ✅ | Confirmed Python returns `True` with hana-ml 2.30 |

Continue to — [Exercise 1 - Generate time series forecasts on-the-fly using
SAP-RPT-TS from SAP HANA Cloud](../ex1/README.md)
