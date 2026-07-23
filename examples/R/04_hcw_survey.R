# ============================================================================
# Example 4: HCW Student Survey
# ============================================================================

rm(list = ls())
library(UZIMA)
library(dplyr)

conn <- fabric_connect(auth = "sp_vault", database = "HCW_fitbit_data")

baseline <- fabric_read_table(conn, "qualtrics_hcw_student_survey")
cat("Rows:", nrow(baseline), " Cols:", ncol(baseline), "\n")

if ("Consent3" %in% names(baseline)) {
  consented <- baseline %>% filter(Consent3 == 1)
  cat("Consented:", nrow(consented), "participants\n")
  print(summary(consented$Age))
}

fabric_disconnect(conn)
