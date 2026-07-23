# ============================================================================
# Example 3: HCW Student Survey Analysis
# Prerequisites: remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect")
# ============================================================================

rm(list = ls())
library(fabriconnect)
library(dplyr)

# Connect to HCW fitbit lakehouse (has the survey data)
conn <- connect_to_fabric(lakehouse = "HCW_fitbit_data")

# ---- Read HCW Student Survey ----
cat("Reading Qualtrics HCW Student Survey...\n\n")
baseline <- read_table(conn, "qualtrics_hcw_student_survey")
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

cat("\nDone.\n")
