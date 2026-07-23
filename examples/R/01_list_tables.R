# ============================================================================
# Example 1: Connect + List Tables
#
# Any auth method works — the exploration helpers detect the connection type.
# ============================================================================

rm(list = ls())
source("fabric_connect.R")

# Choose your auth:
conn <- fabric_connect(auth = "sp_vault")
# conn <- fabric_connect(auth = "device_code")

# List tables (works with any connection)
tables <- fabric_list_tables(conn)
cat("Tables found:", length(tables), "\n")
print(tables)

fabric_disconnect(conn)
