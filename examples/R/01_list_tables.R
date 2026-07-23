# ============================================================================
# Example 1: Connect + List Tables
# Prerequisites: remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect")
# ============================================================================

rm(list = ls())
library(fabriconnect)

conn <- connect_to_fabric()
tables <- list_tables(conn)
cat("Tables found:", length(tables), "\n")
print(tables)
