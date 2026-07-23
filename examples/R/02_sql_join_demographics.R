# ============================================================================
# Example 2: SQL JOIN + Demographics
#
# Any auth method works — the exploration helpers detect the connection type.
# ============================================================================

rm(list = ls())
library(UZIMA)

# Choose your auth:
conn <- fabric_connect(auth = "sp_vault")
# conn <- fabric_connect(auth = "device_code")
# conn <- fabric_connect(auth = "env")

# SQL JOIN: Sleep summary per participant
cat("Sleep summary per participant (top 10):\n\n")
result <- fabric_query(conn, "
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

# Demographics
cat("\nDemographics:\n\n")
demo <- fabric_query(conn, "
  SELECT Gender, COUNT(*) AS total, AVG(Age) AS avg_age,
         MIN(Age) AS min_age, MAX(Age) AS max_age
  FROM dbo.dimenrolledparticipants
  WHERE Gender IS NOT NULL
  GROUP BY Gender
")
print(demo)

fabric_disconnect(conn)
cat("\nDone.\n")
