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
install.packages(c("httr", "jsonlite", "odbc", "DBI", "processx"))
remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect", force = TRUE)
remotes::install_github("AKU-CDIO/External_Reseacher_Access", ref = "feature/uzima-package")
```

---

## Step 2: Authenticate

Pick **one** method:

### R
```r
library(UZIMA)

# Option A: SP + Key Vault (recommended — full SQL access)
conn <- fabric_connect(auth = "sp_vault")

# Option B: Device Code only (browser login — OneLake access)
conn <- fabric_connect(auth = "device_code")

# Option C: Existing token
conn <- fabric_connect(auth = "token", token = "eyJ...")

# Option D: Environment variable
conn <- fabric_connect(auth = "env")
```

### Python
```python
from fabricpy import FabricLakehouse

# Option A: Device Code (browser login)
lh = FabricLakehouse()

# Option B: Existing token
lh = FabricLakehouse(access_token="eyJ...")
```

| Method | What happens | Best for |
|--------|--------------|----------|
| `sp_vault` | az CLI → Key Vault → SP → ODBC SQL | Full SQL access |
| `device_code` | Browser login → OneLake | Simple, quick |
| `token` | Skip login, use your own token | Automation |
| `env` | Read from env var | CI/CD |

---

## Step 3: Explore Data

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
  FROM dimenrolledparticipants
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

```r
fabric_disconnect(conn)
```

---

## Available Data

| Database | Key Tables | Description |
|----------|------------|-------------|
| `uzima_db_backup` | `dimenrolledparticipants`, `factfitbitsleeplogs`, `dimsurveyresults` | Main study data |
| `HCW_fitbit_data` | `factfitbitactivitieslogs`, `factfitbitdailydata` | HCW fitbit logs |
| `Qualtrics` | `qualtrics_hcw_student_survey` | HCW student survey |

**Switch database:**
```r
conn <- fabric_connect(auth = "sp_vault", database = "HCW_fitbit_data")
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Browser doesn't open | Run the script again |
| "Access denied" | Contact derick.imbati@aku.edu |
| "Invalid object name" | Table names are lowercase: `dimenrolledparticipants` not `DimEnrolledParticipants` |

## Support

Contact **Derick Imbati** — derick.imbati@aku.edu
