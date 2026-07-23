# ============================================================================
# Example 2: SQL JOIN + Demographics
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

# ---- SQL JOIN: Sleep summary per participant ----
cat("Sleep summary per participant (top 10):\n\n")
result <- dbGetQuery(conn, "
  SELECT p.ParticipantIdentifier, p.Gender, p.Age,
         COUNT(*) AS sleep_logs,
         AVG(s.MinutesAsleep) AS avg_min_asleep,
         AVG(s.TimeInBed) AS avg_min_in_bed
  FROM dbo.dimenrolledparticipants p
  JOIN dbo.factfitbitsleeplogs s
    ON p.ParticipantIdentifier = s.ParticipantIdentifier
  GROUP BY p.ParticipantIdentifier, p.Gender, p.Age
  ORDER BY sleep_logs DESC
")
print(head(result, 10))

# ---- Demographics ----
cat("\nDemographics:\n\n")
demo <- dbGetQuery(conn, "
  SELECT Gender, COUNT(*) AS total, AVG(Age) AS avg_age,
         MIN(Age) AS min_age, MAX(Age) AS max_age
  FROM dbo.dimenrolledparticipants
  WHERE Gender IS NOT NULL
  GROUP BY Gender
")
print(demo)

dbDisconnect(conn)
cat("\nDone.\n")
