# UZIMA Fabric SQL — List Tables
# remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect", force = TRUE)

library(fabriconnect)

conn <- connect_to_fabric()
tables <- list_tables(conn)
cat("Tables found:", length(tables), "\n\n")
for (t in tables) cat(t, "\n")
dbDisconnect(conn)
