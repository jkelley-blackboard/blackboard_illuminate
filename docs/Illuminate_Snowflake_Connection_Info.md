[← Home](.)

# Illuminate — Snowflake Connection Information
### How to Locate the Details Needed to Connect External Systems

This guide walks through how to find your Snowflake connection details and service account credentials from within Illuminate. These values are required when connecting external tools such as BI platforms, data pipelines, or analytics applications.

---

## Step 1: Verify Your Service Account

1. Log in to [illuminate.blackboard.com](https://illuminate.blackboard.com).

2. Navigate to [illuminate.blackboard.com/settings](https://illuminate.blackboard.com/settings) and scroll to the **bottom of the page** to find the **Snowflake Account Settings** section.

3. Review your service account:
   - The default service account name is typically `SVC_BLACKBOARD_DATA`.
   - Confirm the **Status** is **Enabled**.
   - If this is your first time connecting an external system, you will need to **set a password** for the service account. Record and retain this password in a secure location — it cannot be recovered if lost and will be required by any external system connecting to Snowflake.

> ⚠️ Service account passwords expire over time. Monitor the expiration date in this same settings page and change the password before it lapses to avoid disruption to connected systems.

> ⚠️ Antivirus or URL-scanning software may block the redirect to Snowflake when changing your service account password. If this occurs, try from a browser without that software enabled.

---

## Step 2: Find Your Server (Account URL)

1. Navigate to [illuminate.blackboard.com/developer](https://illuminate.blackboard.com/developer).

2. Click **Launch Snowflake**.
   > ⚠️ If a new tab does not open on the first click, click **Launch Snowflake** again.

3. In the new Snowflake tab, look at the **browser address bar**. The hostname ending in `.snowflakecomputing.com` is your **Server / Account URL**.

   **Example:** `oha52661.snowflakecomputing.com`

4. Copy and save this value.

---

## Step 3: Find Your Database Name

1. From the Snowflake console (opened in Step 2), log in using **Single Sign On (SSO)**.

2. Click **Catalog** in the navigation.

3. The Catalog page will display two databases:
   - `Snowflake`
   - `BLACKBOARD_DATA_xxxxx` ← **This is your Database name.**

4. Copy the full `BLACKBOARD_DATA_xxxxx` name exactly as it appears.

   > 💡 Right-click the database name and select **Place Name in SQL** to copy it accurately without typos.

---

## Step 4: Find Your Warehouse Name

While still in the Snowflake console, locate the **Context section** at the top of the UI. The warehouse name displayed there is your **Warehouse** value.

It will typically be: `BLACKBOARD_DATA_WH`

---

## Summary

After completing the steps above, you will have all the information needed to connect an external system to your Illuminate Snowflake instance:

| Field | Typical Value | Where to Find It |
|---|---|---|
| **Server** | `oha52661.snowflakecomputing.com` | Browser address bar after launching Snowflake |
| **Database** | `BLACKBOARD_DATA_xxxxx` | Snowflake UI — Catalog page |
| **Warehouse** | `BLACKBOARD_DATA_WH` | Snowflake UI — Context section |
| **Username** | `SVC_BLACKBOARD_DATA` | Illuminate Settings — Snowflake Account Settings |
| **Password** | *(set by your admin)* | Illuminate Settings — Snowflake Account Settings |

---

## Data Refresh Cadences

When configuring refresh schedules in your external system, align to Illuminate's data update frequency:

| Data Source | Refresh Frequency |
|---|---|
| CDM_LMS (Blackboard) | Overnight, aligned to Blackboard instance time zone |
| CDM_SIS (Anthology Student) | Daily at 8:00 AM UTC |
| CDM_CLB (Class Collaborate) | Every 2 hours |
| CDM_TLM (Telemetry) | Every 30 minutes |
| CDM_MEDIA (Video Studio) | Near real-time |

---

## Additional Resources

- [Anthology Illuminate Developer Documentation](https://help.anthology.com/illuminate/en/anthology-illuminate-developer.html)
- [Anthology Illuminate Settings](https://help.anthology.com/illuminate/en/anthology-illuminate-developer/anthology-illuminate-settings.html)
- [IP Address Restriction for Snowflake Service Accounts](https://help.anthology.com/illuminate/en/anthology-illuminate-developer/ip-address-restriction-for-snowflake-service-accounts.html)
