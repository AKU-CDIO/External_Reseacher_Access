# ============================================================================
# Example 2: SQL JOIN + Demographics
# Prerequisites: remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect")
# ============================================================================

rm(list = ls())
library(fabriconnect)

conn <- connect_to_fabric()

# ---- SQL JOIN: Sleep summary per participant ----
cat("Sleep summary per participant (top 10):\n\n")
result <- query_tables(conn, "
  SELECT p.ParticipantIdentifier, p.Gender, p.Age,
         COUNT(*) AS sleep_logs,
         AVG(s.MinutesAsleep) AS avg_min_asleep,
         AVG(s.TimeInBed) AS avg_min_in_bed
  FROM dimenrolledparticipants p
  JOIN factfitbitsleeplogs s
    ON p.ParticipantIdentifier = s.ParticipantIdentifier
  GROUP BY p.ParticipantIdentifier, p.Gender, p.Age
  ORDER BY sleep_logs DESC
")
print(head(result, 10))

# ---- Demographics ----
cat("\nDemographics:\n\n")
demo <- query_tables(conn, "
  SELECT Gender, COUNT(*) AS total, AVG(Age) AS avg_age,
         MIN(Age) AS min_age, MAX(Age) AS max_age
  FROM dimenrolledparticipants
  WHERE Gender IS NOT NULL
  GROUP BY Gender
")
print(demo)

cat("\nDone.\n")
