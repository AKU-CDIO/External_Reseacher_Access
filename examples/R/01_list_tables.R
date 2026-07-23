# ============================================================================
# Example 1: Connect + List Tables
#
# Usage:
#   conn <- fabric_connect(auth = "sp_vault")     # ODBC SQL via Key Vault
#   conn <- fabric_connect(auth = "device_code")  # OneLake Delta Lake
#
# Prerequisites:
#   install.packages(c("httr", "jsonlite", "odbc", "DBI"))
#   remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect")
# ============================================================================

rm(list = ls())
source("fabric_connect.R")

# Choose your auth path:
conn <- fabric_connect(auth = "sp_vault")
# conn <- fabric_connect(auth = "device_code")

# List tables
tables <- dbGetQuery(conn, "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME")
cat("Tables found:", nrow(tables), "\n")
print(tables)

dbDisconnect(conn)
