# UZIMA External Researcher Data Access

Access UZIMA study data from Microsoft Fabric on your personal machine — **no VM needed**.

## Quick Start

### Python (Jupyter / VS Code)

```bash
pip install pandas pyodbc azure-identity azure-keyvault-secrets
```

```python
from examples.python.fabric_helpers import get_connection, list_tables, read_table

conn = get_connection()
tables = list_tables(conn)
print(tables)

df = read_table(conn, "dbo.DimenrolledParticipants")
print(df.head())
```

### R / RStudio

```r
install.packages(c("httr", "jsonlite", "odbc", "DBI", "AzureAuth", "dplyr"))
```

Open `connect_fabric.Rmd` in RStudio and click **Knit**. A browser window will open for login.

## How It Works

1. You log in with your browser (one-time)
2. The script fetches service credentials from Azure Key Vault
3. Those credentials connect you to Fabric SQL
4. You query data like any other database

**No passwords stored on your machine. No special software to install.**

## What's Included

| File | What it does |
|------|-------------|
| `connect_and_read.py` | Python — connect and list tables |
| `connect_fabric.Rmd` | R — connect and query data |
| `examples/python/` | More Python examples (read tables, SQL queries, JOINs) |
| `examples/R/` | More R examples (JOINs, demographics, survey analysis) |
| `docs/FABRIC_SP_ACCESS_SETUP.md` | Admin setup documentation |

## Examples

### List all tables
```python
# Python
from examples.python.fabric_helpers import get_connection, list_tables
conn = get_connection()
print(list_tables(conn))
```

### Read a specific table
```python
from examples.python.fabric_helpers import get_connection, read_table
conn = get_connection()
df = read_table(conn, "dbo.DimenrolledParticipants", columns=["ParticipantIdentifier", "Gender", "Age"])
print(df.head())
```

### Run a SQL query
```python
from examples.python.fabric_helpers import get_connection, query_sql
conn = get_connection()
result = query_sql(conn, "SELECT COUNT(*) FROM dbo.DimenrolledParticipants")
print(result)
```

### SQL JOIN across tables
```python
from examples.python.fabric_helpers import get_connection, query_sql
conn = get_connection()
df = query_sql(conn, """
    SELECT p.ParticipantIdentifier, p.Gender,
           AVG(s.MinutesAsleep) AS avg_sleep
    FROM dbo.DimenrolledParticipants p
    JOIN dbo.FactFitBitSleepLog s ON p.ParticipantIdentifier = s.ParticipantIdentifier
    GROUP BY p.ParticipantIdentifier, p.Gender
""")
print(df.head(10))
```

## Available Data

| Lakehouse | Tables | Description |
|-----------|--------|-------------|
| `uzima_db_backup` | 31 | Fitbit, surveys, participants |
| `HCW_fitbit_data` | 5 | HCW fitbit activity logs |
| `Qualtrics` | 1 | HCW student survey (256 columns) |

## Prerequisites

- **ODBC Driver 18** for SQL Server ([install guide](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server))
- **Python** 3.8+ or **R** 4.0+
- Your email must be whitelisted by the admin

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Browser doesn't open | Make sure you have a default browser set |
| "ODBC Driver not found" | Install ODBC Driver 18 from [Microsoft](https://learn.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server) |
| "Access denied" | Contact Derick (derick.imbati@aku.edu) to get whitelisted |
| Connection timeout | Check your internet connection and try again |

## Support

Contact **Derick Imbati** — derick.imbati@aku.edu
