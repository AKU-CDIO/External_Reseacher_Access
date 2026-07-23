# UZIMA Fabric SQL Access via Service Principal + Key Vault

## Overview

This document describes how the UZIMA team accesses the Fabric SQL database
using an Azure AD service principal (SP) whose credentials are stored in
Azure Key Vault. Users authenticate to Key Vault via interactive browser login,
retrieve the SP credentials, and use them to connect to Fabric SQL from their local machines.

## Architecture

```
Personal Machine
  └─ connect_and_read.py / connect_fabric.Rmd
       ├─ Interactive browser login ──> Key Vault (fetch SP creds)
       ├─ ClientSecretCredential ──> Fabric SQL token
       └─ pyodbc / odbc ──> Fabric SQL Database (uzima_db_backup)
```

## Azure Resources

| Resource          | Details                                                        |
|-------------------|----------------------------------------------------------------|
| **Key Vault**     | `uzima-secrets-xfmh` (Resource Group: `CDIOUZIMA`)            |
| **Subscription**  | `a5d4ffbe-d287-4dd1-86c9-f1214fe751d6` (Microsoft Azure Enterprise) |
| **Tenant (Key Vault)** | `4fde8ff3-4dd5-42e1-a25a-e42905610d66`                   |
| **Tenant (Fabric SP)** | `a5d4252a-02f9-4e60-96f0-9733baae4919`                   |
| **Fabric Server** | `fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com` |
| **Database**      | `uzima_db_backup`                                               |

## Secrets Stored in Key Vault

| Secret Name               | Description                          |
|---------------------------|--------------------------------------|
| `fabric-sp-tenant-id`     | Azure AD tenant ID for the SP        |
| `fabric-sp-client-id`     | Application (client) ID of the SP    |
| `fabric-sp-client-secret` | Client secret for the SP             |

## Whitelisted Users (Key Vault Secrets User role)

| Name              | Email                      | Object ID                                 |
|-------------------|----------------------------|--------------------------------------------|
| Derick Imbati     | derick.imbati@aku.edu      | `9fca19e0-0ce6-46b3-8829-84a0109c02d8`    |
| Rais Muhammad     | rais.muhammad@aku.edu      | `c6a4dc6e-9474-40c9-94ca-2a58d6cf680a`    |
| Dorcas            | dorcasm@umich.edu          | `e9840bc5-341f-4c04-a2b8-aaf58d6c7bdf`    |
| Kim, Ye Chan      | yechank@med.umich.edu      | `27287e67-7602-44a4-909d-a8055ab0002f`    |
| Brooke Kenney     | nannab@med.umich.edu       | `4bc9cee3-c600-4585-a1a8-ea4ffd2e2154`    |

All users are B2B guests in the Key Vault tenant (`4fde8ff3-...`).
Role: **Key Vault Secrets User** (`4633458b-17de-408a-b874-0445c86b69e6`)

## Prerequisites

### Python
1. **ODBC Driver 18** for SQL Server installed
2. **Python packages:**
   ```bash
   pip install pandas pyodbc azure-identity azure-keyvault-secrets
   ```
3. Run the script — browser opens automatically for Key Vault login:
   ```bash
   python connect_and_read.py
   ```

### R / RStudio
1. **ODBC Driver 18** for SQL Server installed
2. **R packages:**
   ```r
   install.packages(c("httr", "jsonlite", "odbc", "DBI", "AzureAuth", "dplyr"))
   ```
3. Open `connect_fabric.Rmd` in RStudio and knit — browser opens automatically for Key Vault login

## How It Works

Both Python and R follow the same flow:

1. **Browser login** opens for Key Vault tenant (`4fde8ff3-...`)
2. **SP credentials** fetched from Key Vault:
   - `fabric-sp-tenant-id`
   - `fabric-sp-client-id`
   - `fabric-sp-client-secret`
3. **SP token** acquired for Fabric SQL (`https://database.windows.net/.default`)
4. **ODBC connection** established to Fabric SQL using the token

No secrets are stored locally — everything is fetched from Key Vault at runtime.

## Available Tables (uzima_db_backup)

| Table                                      | Schema |
|--------------------------------------------|--------|
| AdheranceForEnrolledParticipantsView       | dbo    |
| Anxiety                                    | dbo    |
| CovidExperiences                           | dbo    |
| Depression                                 | dbo    |
| DepressionAnalysis                         | dbo    |
| DimEnrolledParticipants                    | dbo    |
| DimSleepDetailsLogs                        | dbo    |
| DimSurveyDictionary                        | dbo    |
| DimSurveyQuestionResult                    | dbo    |
| DimSurveyResults                           | dbo    |
| DimSurveyStepResults                       | dbo    |
| DimSurveyTask                              | dbo    |
| EFE                                        | dbo    |
| FactFitBitActivitiesLogs                   | dbo    |
| FactFitBitDailyData                        | dbo    |
| FactFitBitRestingHeartRates                | dbo    |
| FactFitBitSleepLog                         | dbo    |
| FactFitbitIntraDayCombined                 | dbo    |
| Feasibility_Study_Baseline                 | dbo    |
| FitBitDailyDataBetween0AND120              | dbo    |
| FitBitDailyDataBetween121AND210            | dbo    |
| FitBitDailyDataBetween211AND300            | dbo    |
| IndividualFactors                          | dbo    |
| LifeExperiences                            | dbo    |
| MedicalError                               | dbo    |
| Mood                                       | dbo    |
| Neuroticsm                                 | dbo    |
| PTSD                                       | dbo    |
| Qualtrics_HCW_Student_Survey_View          | dbo    |
| Quarter1Survey                             | dbo    |

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `DefaultAzureCredential failed` | az CLI not detected by Python | Already switched to `InteractiveBrowserCredential` |
| `AADSTS700016` | Wrong tenant or client ID | Verify SP credentials against Fabric tenant |
| `Insufficient privileges` | User not assigned Key Vault role | Run `az role assignment create` for the user |
| `ODBC Driver not found` | ODBC Driver 18 not installed | Install from [Microsoft docs](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server) |
| `pandas UserWarning` | Using raw DBAPI2 connection | Use SQLAlchemy engine or suppress warning |
| `Unauthorized AKV10000` | Not logged into Key Vault tenant | Run script again — browser login will open |
