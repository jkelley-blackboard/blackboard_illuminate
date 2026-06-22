[← Home](.)

# Blackboard Illuminate → Microsoft Power BI Integration Guide
### Snowflake Canonical Data Model — Power BI Connection

---

## Prerequisites

Before beginning, ensure the following are in place:

- Power BI Desktop installed (latest version recommended)
- Access to Illuminate with an administrator or developer role
- Service account credentials (username and password) for the Snowflake integration
- The service account must be enabled in Illuminate Settings (confirmed in Step 1)

---

## Step 1: Gather Your Snowflake Connection Details

1. Log in to [illuminate.blackboard.com](https://illuminate.blackboard.com).

2. Navigate to [illuminate.blackboard.com/settings](https://illuminate.blackboard.com/settings) and scroll to the **bottom of the page** to find the **Snowflake Account Settings** section.
   - The default service account name is typically `SVC_BLACKBOARD_DATA`.
   - Confirm the service account **Status** is **Enabled**.
   - If this is your first time connecting, you will need to **set a password** for the service account. Record and retain this password in a secure location — it is required for the Power BI connection and cannot be recovered if lost.

3. Navigate to [illuminate.blackboard.com/developer](https://illuminate.blackboard.com/developer).

4. Click **Launch Snowflake**.
   > ⚠️ If a new tab does not open on the first click, click **Launch Snowflake** again.

5. In the new Snowflake tab, look at the **browser address bar**. The hostname ending in `.snowflakecomputing.com` is your **Server** value (e.g., `oha52661.snowflakecomputing.com`). Copy this value.

6. Log into the Snowflake console using **Single Sign On (SSO)**.

7. Once logged in, click **Catalog** in the navigation.

8. The Catalog page will display two databases:
   - `Snowflake`
   - `BLACKBOARD_DATA_xxxxx` ← **This is your Database value for Power BI.** Copy the full name exactly as it appears.
   > 💡 Right-click the database name in Snowflake and select **Place Name in SQL** to copy it accurately without typos.

9. Your **Warehouse** value is found in the **Context section** at the top of the Snowflake UI. It will typically be `BLACKBOARD_DATA_WH`.

**Summary of values to collect:**

| Field | Where to Find It | Typical Value |
|---|---|---|
| **Server** | Browser address bar after launching Snowflake | `oha52661.snowflakecomputing.com` |
| **Warehouse** | Snowflake UI — Context section | `BLACKBOARD_DATA_WH` |
| **Database** | Snowflake UI — Catalog page | `BLACKBOARD_DATA_xxxxx` |

---

## Step 2: Connect to Snowflake in Power BI Desktop

1. Open **Power BI Desktop**.
2. Click **Home → Get Data → More…**
3. Search for **Snowflake**, select it, and click **Connect**.

---

## Step 3: Enter Connection Details

Fill in the dialog with the values gathered in Step 1:

| Power BI Field | Value |
|---|---|
| **Server** | Your Snowflake URL (e.g., `oha52661.snowflakecomputing.com`) |
| **Warehouse** | `BLACKBOARD_DATA_WH` |
| **Database** | Your full `BLACKBOARD_DATA_xxxxx` name |
| **Schema** | Leave blank to browse all schemas, or specify one |
| **Role** | Leave blank unless your Illuminate admin specifies otherwise |

Select your **Data Connectivity mode:**

- **Import** *(recommended)* — Data is loaded into Power BI and refreshed on a schedule. Best performance for most reporting use cases.
- **DirectQuery** — Queries Snowflake live on each report interaction. Use when real-time or near-real-time data is required.

Click **OK**.

---

## Step 4: Authenticate with the Service Account

1. When prompted, select **Database** authentication.
2. Enter the service account username (typically `SVC_BLACKBOARD_DATA`) and the password set in Step 1.
3. Click **Connect**.

---

## Step 5: Select Your Data

1. In the **Navigator** panel, expand the Illuminate database and schemas.
2. Select the tables or views relevant to your report (e.g., LMS activity, SIS enrollment, Telemetry data).
3. Click **Load** to import data as-is, or **Transform Data** to shape and clean it in Power Query first.

---

## Step 6: Publish & Schedule Refresh (Power BI Service)

1. Publish your report to **Power BI Service**.
2. Navigate to your dataset → **Settings → Data source credentials** and re-enter the service account credentials to authenticate the cloud connection.
3. Under **Scheduled refresh**, configure your refresh frequency. Align your schedule to the Illuminate data refresh cadences below:

| Data Source | Refresh Frequency |
|---|---|
| CDM_LMS (Blackboard) | Overnight, aligned to Blackboard instance time zone |
| CDM_SIS (Anthology Student) | Daily at 8:00 AM UTC |
| CDM_CLB (Class Collaborate) | Every 2 hours |
| CDM_TLM (Telemetry) | Every 30 minutes |
| CDM_MEDIA (Video Studio) | Near real-time |

> ⚠️ If your organization requires it, ensure an **On-premises Data Gateway** is installed and configured to broker the connection between Power BI Service and Snowflake.

---

## Important Notes

### Service Account Password Expiration

Service account passwords expire over time. Monitor the expiration date in Illuminate Settings (→ Snowflake Account Settings) and change the password **before** it lapses to avoid broken Power BI connections. If the password changes, update the credentials in Power BI Service as well.

> ⚠️ Antivirus or URL-scanning software may block the redirect to Snowflake when changing your service account password. If this occurs, try from a browser without that software enabled.

### IP Address Restrictions

If your institution has configured IP address restrictions on the Snowflake service account, ensure Power BI's outbound IP addresses are on the allowlist. Refer to the Illuminate documentation on [IP Address Restriction for Snowflake Service Accounts](https://help.anthology.com/illuminate/en/anthology-illuminate-developer/ip-address-restriction-for-snowflake-service-accounts.html) for details.

---

*For questions or issues, refer to the [Anthology Illuminate Developer documentation](https://help.anthology.com/illuminate/en/anthology-illuminate-developer.html).*
