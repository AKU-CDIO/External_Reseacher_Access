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

---

## Choose Your Auth Path

| | **Path A: SP + Key Vault** | **Path B: Device Code Only** |
|---|---|---|
| **Best for** | Full control, explicit flow | Simple, hands-off |
| **Steps** | 4-step chain (see below) | 1-step browser login |
| **Access** | ODBC SQL (full SQL Server) | OneLake Delta Lake |
| **Requires** | `httr`, `jsonlite`, `odbc`, `DBI`, `fabriconnect` | `fabricpy` (Python) or `fabriconnect` (R) |
| **SQL Support** | Full T-SQL via ODBC | Limited (via duckdb) |

---

## Path A: SP + Key Vault (Explicit 4-Step Chain)

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

### Path A — Python

```python
# pip install "fabricpy[pandas,sql] @ git+https://github.com/AKU-CDIO/fabric-inbound-access.git#subdirectory=fabriconnectpy"

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

### Path A — R

```r
# install.packages(c("httr", "jsonlite", "odbc", "DBI"))
# remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect", force = TRUE)

library(httr)
library(jsonlite)
library(odbc)
library(DBI)
library(fabriconnect)

# ---- Config ----
VAULT_URL <- "https://uzima-secrets-xfmh.vault.azure.net"
SERVER    <- "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"
DATABASE  <- "uzima_db_backup"

# Step 1: Device code → browser login → get token
cfg <- jsonlite::fromJSON(system.file("config.json", package = "fabriconnect"))
token <- fabriconnect:::.get_fabric_token(cfg$fabric_tenant)

# Step 2: Token → Key Vault → get SP credentials
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
  Server = paste0(SERVER, ",1433"),
  Database = DATABASE,
  UID = 1, AccessToken = sql_token,
  Encrypt = "yes", TrustServerCertificate = "no", Timeout = 30
)

# Query
dbGetQuery(con, "SELECT COUNT(*) AS total FROM dbo.dimenrolledparticipants")
dbDisconnect(con)
```

---

## Path B: Device Code Only (Simple)

### Path B — Python

```python
from fabricpy import FabricLakehouse

lh = FabricLakehouse()

# List tables
tables = lh.list_tables()
print(tables)

# Read a table
df = lh.to_pandas("dimenrolledparticipants")
print(df.head())
```

### Path B — R

```r
library(fabriconnect)

conn <- connect_to_fabric()

# List tables
tables <- list_tables(conn)
print(tables)

# Read a table
df <- read_table(conn, "dimenrolledparticipants")
print(head(df))

# SQL query (via duckdb)
result <- query_tables(conn, "SELECT COUNT(*) AS total FROM dimenrolledparticipants")
print(result)
```

---

## Available Data

| Database | Tables | Description |
|----------|--------|-------------|
| `uzima_db_backup` | 31+ | Fitbit, surveys, participants |
| `HCW_fitbit_data` | 5 | HCW fitbit activity logs |
| `Qualtrics` | 1 | HCW student survey |

**Path A:** Change `Database = "HCW_fitbit_data"` in the connection.
**Path B:** Change `connect_to_fabric(lakehouse = "HCW_fitbit_data")`.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Browser doesn't open | Run the script again — device code will re-issue |
| "Access denied" | Contact derick.imbati@aku.edu to get whitelisted |
| Install fails | Wait and retry (GitHub rate limit) |
| `rm(list = ls())` warning | Safe to ignore — clears old functions that mask package versions |

## Support

Contact **Derick Imbati** — derick.imbati@aku.edu
