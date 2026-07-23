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
remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect", force = TRUE)
```

## Auth Flow

1. Run any example → browser opens automatically
2. Sign in with your **external email** (e.g. Gmail, Outlook.com)
3. Complete MFA if prompted
4. Token cached locally — subsequent runs skip sign-in
5. Token expires after ~1 hour → re-authenticate automatically

**No Azure CLI, no Service Principal, no Key Vault required.**

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
library(fabriconnect)

conn <- connect_to_fabric()

# List tables
tables <- list_tables(conn)
print(tables)

# Read a table
df <- read_table(conn, "dimenrolledparticipants")
print(head(df))

# SQL query
result <- query_tables(conn, "SELECT COUNT(*) AS total FROM dimenrolledparticipants")
print(result)
```

## Available Data

| Database | Tables | Description |
|----------|--------|-------------|
| `uzima_db_backup` | 31+ | Fitbit, surveys, participants |
| `HCW_fitbit_data` | 5 | HCW fitbit activity logs |
| `Qualtrics` | 1 | HCW student survey |

To use a different database:

```python
lh = FabricLakehouse(lakehouse="HCW_fitbit_data")
```

```r
conn <- connect_to_fabric(lakehouse = "HCW_fitbit_data")
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| "No authentication method available" | Run the script again — browser will open for sign-in |
| "Access denied" | Contact derick.imbati@aku.edu to get whitelisted |
| Install fails | Wait and retry (GitHub rate limit) |
| `rm(list = ls())` warning | Safe to ignore — clears old functions that might mask package versions |

## Support

Contact **Derick Imbati** — derick.imbati@aku.edu
