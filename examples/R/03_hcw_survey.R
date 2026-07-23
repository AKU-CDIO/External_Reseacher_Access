# ============================================================================
# Example 3: HCW Student Survey Analysis
#
# Any auth method works — the exploration helpers detect the connection type.
# ============================================================================

rm(list = ls())
library(UZIMA)
library(dplyr)

# Choose your auth + database:
conn <- fabric_connect(auth = "sp_vault", database = "HCW_fitbit_data")
# conn <- fabric_connect(auth = "device_code", lakehouse = "HCW_fitbit_data")
# conn <- fabric_connect(auth = "env", database = "HCW_fitbit_data")

# Read HCW Student Survey
cat("Reading Qualtrics HCW Student Survey...\n\n")
baseline <- fabric_read_table(conn, "qualtrics_hcw_student_survey")
cat("Rows:", nrow(baseline), " Cols:", ncol(baseline), "\n")

# Filter consented participants
if ("Consent3" %in% names(baseline)) {
  baseline_filtered <- baseline %>%
    filter(Consent3 == 1)
  cat("Consented:", nrow(baseline_filtered), "participants\n\n")

  cat("Age summary:\n")
  print(summary(baseline_filtered$Age))

  cat("\nGender distribution:\n")
  print(table(baseline_filtered$Gender, useNA = "ifany"))
} else {
  cat("Column 'Consent3' not found. Available columns:\n")
  print(names(baseline))
}

fabric_disconnect(conn)
cat("\nDone.\n")
