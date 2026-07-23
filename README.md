# UZIMA External Researcher Data Access

Access UZIMA study data from Microsoft Fabric on your personal machine.

> **No repo clone needed.** Copy any code block below and run it.

---

## Step 1: Install

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

## Step 2: Authenticate

Pick **one** method that works for you:

### R — Pick a method

```r
source("fabric_connect.R")

# Option A: SP + Key Vault (recommended — full SQL access)
conn <- fabric_connect(auth = "sp_vault")

# Option B: Device Code only (simpler — browser login)
conn <- fabric_connect(auth = "device_code")

# Option C: Existing token (if you already have one)
conn <- fabric_connect(auth = "token", token = "eyJ...")
```

### Python — Pick a method

```python
from fabricpy import FabricLakehouse

# Option A: Device Code (browser login)
lh = FabricLakehouse()

# Option B: Existing token
lh = FabricLakehouse(access_token="eyJ...")
```

| Method | What happens | Best for |
|--------|--------------|----------|
| `sp_vault` | Browser login → Key Vault → SP → ODBC | Full SQL access |
| `device_code` | Browser login → OneLake | Simple, quick |
| `token` | Skip login, use your own token | Automation, sharing |

---

## Step 3: Explore Data

These examples work **regardless** of which auth method you chose.

### List Tables

**R:**
```r
tables <- fabric_list_tables(conn)
print(tables)
```

**Python:**
```python
tables = lh.list_tables()
print(tables)
```

### Read a Table

**R:**
```r
df <- fabric_read_table(conn, "dimenrolledparticipants")
head(df)
```

**Python:**
```python
df = lh.to_pandas("dimenrolledparticipants")
print(df.head())
```

### Run SQL

**R:**
```r
result <- fabric_query(conn, "
  SELECT Gender, COUNT(*) AS total
  FROM dbo.dimenrolledparticipants
  GROUP BY Gender
")
print(result)
```

**Python:**
```python
result = lh.sql("SELECT Gender, COUNT(*) AS total FROM dimenrolledparticipants GROUP BY Gender")
print(result)
```

### Disconnect

**R:**
```r
fabric_disconnect(conn)
```

**Python:**
```python
# No disconnect needed — Python handles cleanup automatically
```

---

## Available Data

| Database | Tables | Description |
|----------|--------|-------------|
| `uzima_db_backup` | 31+ | Fitbit, surveys, participants |
| `HCW_fitbit_data` | 5 | HCW fitbit activity logs |
| `Qualtrics` | 1 | HCW student survey |

**Switch database in R:**
```r
conn <- fabric_connect(auth = "sp_vault", database = "HCW_fitbit_data")
# or
conn <- fabric_connect(auth = "device_code", lakehouse = "HCW_fitbit_data")
```

**Switch database in Python:**
```python
lh = FabricLakehouse(lakehouse="HCW_fitbit_data")
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Browser doesn't open | Run the script again — it will re-issue a device code |
| "Access denied" | Contact derick.imbati@aku.edu to get whitelisted |
| Install fails | Wait and retry (GitHub rate limit) |
| `rm(list = ls())` warning | Safe to ignore — clears old functions |

## Support

Contact **Derick Imbati** — derick.imbati@aku.edu
