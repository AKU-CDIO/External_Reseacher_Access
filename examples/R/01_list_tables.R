# ============================================================================
# Example 1: Test Connection + List Tables
#
# Equivalent to: examples/test_fabriconnect.R (from fabric-inbound-access repo)
# But uses ODBC via Key Vault instead of fabriconnect package.
#
# Prerequisites:
#   install.packages(c("httr", "jsonlite", "odbc", "DBI", "AzureAuth", "dplyr"))
#   ODBC Driver 18 for SQL Server
# ============================================================================

library(httr)
library(jsonlite)
library(odbc)
library(DBI)
library(dplyr)

# ---- Config ----
KV_TENANT_ID <- "4fde8ff3-4dd5-42e1-a25a-e42905610d66"
VAULT_URL    <- "https://uzima-secrets-xfmh.vault.azure.net"
SERVER       <- "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"
DATABASE     <- "uzima_db_backup"

# ---- Authenticate to Key Vault (browser opens) ----
token_kv <- AzureAuth::get_azure_token(
  resource = "https://vault.azure.net",
  tenant   = KV_TENANT_ID,
  app      = "04b07795-c8b7-4bab-9fb9-464329ae7e9e",
  auth_type = "device_code",
  use_cache = FALSE
)

# ---- Fetch SP credentials from Key Vault ----
fetch_secret <- function(vault_url, secret_name, token) {
  url <- paste0(vault_url, "/secrets/", secret_name, "?api-version=7.4")
  resp <- GET(url, add_headers(Authorization = paste("Bearer", token$credentials$access_token)))
  stop_for_status(resp)
  content(resp)$value
}

tenant_id     <- fetch_secret(VAULT_URL, "fabric-sp-tenant-id", token_kv)
client_id     <- fetch_secret(VAULT_URL, "fabric-sp-client-id", token_kv)
client_secret <- fetch_secret(VAULT_URL, "fabric-sp-client-secret", token_kv)

# ---- Get Fabric SQL token via SP ----
get_sp_token <- function(tenant_id, client_id, client_secret) {
  url <- paste0("https://login.microsoftonline.com/", tenant_id, "/oauth2/v2.0/token")
  body <- list(
    grant_type    = "client_credentials",
    client_id     = client_id,
    client_secret = client_secret,
    scope         = "https://database.windows.net/.default"
  )
  resp <- POST(url, body = body, encode = "form")
  stop_for_status(resp)
  content(resp)$access_token
}

token_sql <- get_sp_token(tenant_id, client_id, client_secret)

# ---- Connect to Fabric SQL ----
con <- dbConnect(
  odbc::odbc(),
  Driver      = "ODBC Driver 18 for SQL Server",
  Server      = paste0(server, ",1433"),
  Database    = database,
  UID         = 1,
  AccessToken = token_sql,
  Encrypt     = "yes",
  TrustServerCertificate = "no",
  Timeout     = 30
)

# ---- List tables ----
tables <- dbGetQuery(con, "
  SELECT TABLE_SCHEMA, TABLE_NAME
  FROM INFORMATION_SCHEMA.TABLES
  ORDER BY TABLE_SCHEMA, TABLE_NAME
")

cat("Tables found:", nrow(tables), "\n\n")
print(tables)

dbDisconnect(con)
cat("\nDone.\n")
