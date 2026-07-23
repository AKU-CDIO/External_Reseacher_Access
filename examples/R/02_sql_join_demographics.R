# UZIMA Fabric SQL — Read Table
# remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect", force = TRUE)

library(fabriconnect)

conn <- connect_to_fabric()

# Read table
df <- read_table(conn, "dimenrolledparticipants")
cat("Rows:", nrow(df), " Cols:", ncol(df), "\n\n")
print(head(df))

# Count
result <- query_tables(conn, "SELECT COUNT(*) AS total FROM dimenrolledparticipants")
cat("\nTotal participants:", result$total, "\n")

dbDisconnect(conn)
