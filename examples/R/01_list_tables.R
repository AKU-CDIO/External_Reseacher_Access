# ============================================================================
# Example 1: Connect + List Tables
#
# Auth flow: Device code (browser) → Key Vault → SP → ODBC SQL
#
# Prerequisites:
#   install.packages(c("httr", "jsonlite", "odbc", "DBI"))
#   ODBC Driver 18 for SQL Server
#   remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect")
# ============================================================================

rm(list = ls())

library(httr)
library(jsonlite)
library(odbc)
library(DBI)
library(fabriconnect)

# ---- Config ----
VAULT_URL    <- "https://uzima-secrets-xfmh.vault.azure.net"
SERVER       <- "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"
DATABASE     <- "uzima_db_backup"

# ---- Step 1: Device code → browser login → get token ----
cat("Signing in via browser...\n")
cfg <- jsonlite::fromJSON(system.file("config.json", package = "fabriconnect"))
token <- fabriconnect:::.get_fabric_token(cfg$fabric_tenant)
cat("Authenticated.\n\n")

# ---- Step 2: Token → Key Vault → get SP credentials ----
cat("Fetching SP credentials from Key Vault...\n")
fetch_secret <- function(name) {
  url <- paste0(VAULT_URL, "/secrets/", name, "?api-version=7.4")
  resp <- GET(url, add_headers(Authorization = paste("Bearer", token)))
  stop_for_status(resp)
  content(resp)$value
}

tenant_id     <- fetch_secret("fabric-sp-tenant-id")
client_id     <- fetch_secret("fabric-sp-client-id")
client_secret <- fetch_secret("fabric-sp-client-secret")
cat("SP credentials retrieved.\n\n")

# ---- Step 3: SP credentials → SQL token ----
cat("Getting SQL access token...\n")
resp <- POST(
  paste0("https://login.microsoftonline.com/", tenant_id, "/oauth2/v2.0/token"),
  body = list(
    grant_type    = "client_credentials",
    client_id     = client_id,
    client_secret = client_secret,
    scope         = "https://database.windows.net/.default"
  ),
  encode = "form"
)
stop_for_status(resp)
sql_token <- content(resp)$access_token
cat("SQL token obtained.\n\n")

# ---- Step 4: SQL token → ODBC connection ----
cat("Connecting to Fabric SQL...\n")
con <- dbConnect(
  odbc::odbc(),
  Driver      = "ODBC Driver 18 for SQL Server",
  Server      = paste0(SERVER, ",1433"),
  Database    = DATABASE,
  UID         = 1,
  AccessToken = sql_token,
  Encrypt     = "yes",
  TrustServerCertificate = "no",
  Timeout     = 30
)
cat("Connected!\n\n")

# ---- List tables ----
tables <- dbGetQuery(con, "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME")
cat("Tables found:", nrow(tables), "\n")
print(tables)

dbDisconnect(con)
