# UZIMA Fabric SQL — SQL JOINs
# remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect", force = TRUE)

library(fabriconnect)

conn <- connect_to_fabric()

# Sleep summary per participant
sleep <- query_tables(conn, "
  SELECT p.ParticipantIdentifier, p.Gender,
         COUNT(*) AS sleep_logs,
         AVG(s.MinutesAsleep) AS avg_sleep
  FROM dimenrolledparticipants p
  JOIN factfitbitsleeplogs s ON p.ParticipantIdentifier = s.ParticipantIdentifier
  GROUP BY p.ParticipantIdentifier, p.Gender
  ORDER BY sleep_logs DESC
")
cat("Sleep summary (top 10):\n\n")
print(head(sleep, 10))

# Demographics
demo <- query_tables(conn, "
  SELECT Gender, COUNT(*) AS total, AVG(Age) AS avg_age
  FROM dimenrolledparticipants
  WHERE Gender IS NOT NULL
  GROUP BY Gender
")
cat("\nDemographics:\n\n")
print(demo)

dbDisconnect(conn)
