# ============================================================================
# Example 1: Connect + List Tables
#
# Any auth method works — the exploration helpers detect the connection type.
# ============================================================================

rm(list = ls())
library(UZIMA)

# Choose your auth:
conn <- fabric_connect(auth = "sp_vault")
# conn <- fabric_connect(auth = "device_code")
# conn <- fabric_connect(auth = "env")

# List tables (works with any connection)
tables <- fabric_list_tables(conn)
cat("Tables found:", length(tables), "\n")
print(tables)

fabric_disconnect(conn)
