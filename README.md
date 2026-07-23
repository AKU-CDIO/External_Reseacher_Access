# UZIMA External Researcher Data Access

Access UZIMA study data from Microsoft Fabric on your personal machine.

> **No repo clone needed.** Copy any code block below and run it.

## Prerequisites

### Python
```bash
pip install "fabricpy[pandas,sql] @ git+https://github.com/AKU-CDIO/fabric-inbound-access.git#subdirectory=fabriconnectpy"
```

### R
```r
install.packages(c("httr", "jsonlite", "odbc", "DBI"))
remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect", force = TRUE)
```

## Auth Flow (Explicit)

Every connection follows this 4-step chain:

```
Device Code (browser)  →  Key Vault  →  Service Principal  →  ODBC SQL
     Step 1                 Step 2           Step 3              Step 4
```

| Step | What Happens | Why |
|------|--------------|-----|
| 1 | Browser opens → sign in with your email | MFA + external identity |
| 2 | Token fetches SP creds from Key Vault | Secrets never leave Azure |
| 3 | SP creds → SQL access token | Fabric SQL endpoint auth |
| 4 | SQL token → ODBC connection | Query data with standard SQL |

**No Azure CLI required.** The `fabriconnect` package handles device code flow internally.

## Python

```python
from fabricpy import FabricLakehouse

lh = FabricLakehouse()

# List tables
tables = lh.list_tables()
print(tables)

# Read a table
df = lh.to_pandas("dimenrolledparticipants")
print(df.head())

# SQL query
result = lh.sql("SELECT COUNT(*) AS total FROM dimenrolledparticipants")
print(result)
```

## R

```r
library(httr)
library(jsonlite)
library(odbc)
library(DBI)
library(fabriconnect)

# Step 1: Device code → browser login → get token
cfg <- jsonlite::fromJSON(system.file("config.json", package = "fabriconnect"))
token <- fabriconnect:::.get_fabric_token(cfg$fabric_tenant)

# Step 2: Token → Key Vault → get SP credentials
VAULT_URL <- "https://uzima-secrets-xfmh.vault.azure.net"
fetch_secret <- function(name) {
  url <- paste0(VAULT_URL, "/secrets/", name, "?api-version=7.4")
  resp <- GET(url, add_headers(Authorization = paste("Bearer", token)))
  stop_for_status(resp)
  content(resp)$value
}

tenant_id     <- fetch_secret("fabric-sp-tenant-id")
client_id     <- fetch_secret("fabric-sp-client-id")
client_secret <- fetch_secret("fabric-sp-client-secret")

# Step 3: SP credentials → SQL token
resp <- POST(
  paste0("https://login.microsoftonline.com/", tenant_id, "/oauth2/v2.0/token"),
  body = list(grant_type = "client_credentials", client_id = client_id,
              client_secret = client_secret, scope = "https://database.windows.net/.default"),
  encode = "form"
)
stop_for_status(resp)
sql_token <- content(resp)$access_token

# Step 4: SQL token → ODBC connection
con <- dbConnect(
  odbc::odbc(),
  Driver = "ODBC Driver 18 for SQL Server",
  Server = "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com,1433",
  Database = "uzima_db_backup",
  UID = 1, AccessToken = sql_token,
  Encrypt = "yes", TrustServerCertificate = "no", Timeout = 30
)

# Query
dbGetQuery(con, "SELECT COUNT(*) AS total FROM dbo.dimenrolledparticipants")
dbDisconnect(con)
```

## Available Data

| Database | Tables | Description |
|----------|--------|-------------|
| `uzima_db_backup` | 31+ | Fitbit, surveys, participants |
| `HCW_fitbit_data` | 5 | HCW fitbit activity logs |
| `Qualtrics` | 1 | HCW student survey |

To use a different database, change `Database = "HCW_fitbit_data"` in the connection.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Browser doesn't open | Run the script again — device code will re-issue |
| "Access denied" | Contact derick.imbati@aku.edu to get whitelisted |
| Install fails | Wait and retry (GitHub rate limit) |
| `rm(list = ls())` warning | Safe to ignore — clears old functions that mask package versions |

## Support

Contact **Derick Imbati** — derick.imbati@aku.edu
