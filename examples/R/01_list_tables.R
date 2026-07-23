# ============================================================================
# Example 1: Connect + List Tables
# ============================================================================

rm(list = ls())
library(UZIMA)

# Connect (pick one):
conn <- fabric_connect(auth = "sp_vault")
# conn <- fabric_connect(auth = "device_code")
# conn <- fabric_connect(auth = "env")

# List tables
tables <- fabric_list_tables(conn)
cat("Tables found:", length(tables), "\n")
print(tables)

fabric_disconnect(conn)
