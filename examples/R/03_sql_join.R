# ============================================================================
# Example 3: SQL JOIN — Sleep summary per participant
# ============================================================================

rm(list = ls())
library(UZIMA)

conn <- fabric_connect(auth = "sp_vault")

result <- fabric_query(conn, "
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

fabric_disconnect(conn)
