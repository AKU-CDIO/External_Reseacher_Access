# ============================================================================
# Example 3: HCW Student Survey Analysis
#
# Usage:
#   conn <- fabric_connect(auth = "sp_vault", database = "HCW_fitbit_data")
#   conn <- fabric_connect(auth = "device_code")
#
# Prerequisites:
#   install.packages(c("httr", "jsonlite", "odbc", "DBI", "dplyr"))
#   remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect")
# ============================================================================

rm(list = ls())
source("fabric_connect.R")
library(dplyr)

# Choose your auth path + database:
conn <- fabric_connect(auth = "sp_vault", database = "HCW_fitbit_data")
# conn <- fabric_connect(auth = "device_code")

# ---- Read HCW Student Survey ----
cat("Reading Qualtrics HCW Student Survey...\n\n")
baseline <- dbReadTable(conn, "dbo.Qualtrics_HCW_Student_Survey_View")
cat("Rows:", nrow(baseline), " Cols:", ncol(baseline), "\n")

# ---- Filter consented participants ----
if ("Consent3" %in% names(baseline)) {
  baseline_filtered <- baseline %>%
    filter(Consent3 == 1)
  cat("Consented:", nrow(baseline_filtered), "participants\n\n")

  # Descriptives
  cat("Age summary:\n")
  print(summary(baseline_filtered$Age))

  cat("\nGender distribution:\n")
  print(table(baseline_filtered$Gender, useNA = "ifany"))
} else {
  cat("Column 'Consent3' not found. Available columns:\n")
  print(names(baseline))
}

dbDisconnect(conn)
cat("\nDone.\n")
