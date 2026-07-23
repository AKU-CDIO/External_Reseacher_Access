# ============================================================================
# Example 2: Read Table + SQL Query
# ============================================================================

rm(list = ls())
library(UZIMA)

conn <- fabric_connect(auth = "sp_vault")

# Read a table
df <- fabric_read_table(conn, "dimenrolledparticipants")
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n")
print(head(df))

# SQL query
demo <- fabric_query(conn, "
  SELECT Gender, COUNT(*) AS total, AVG(Age) AS avg_age
  FROM dimenrolledparticipants
  WHERE Gender IS NOT NULL
  GROUP BY Gender
")
print(demo)

fabric_disconnect(conn)
