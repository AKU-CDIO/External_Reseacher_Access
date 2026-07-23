# ============================================================================
# UZIMA Fabric Connection Helper
#
# Usage:
#   conn <- fabric_connect(auth = "sp_vault")    # 4-step: Device Code → Key Vault → SP → ODBC
#   conn <- fabric_connect(auth = "device_code") # 1-step: Device Code → OneLake
#
# Prerequisites:
#   install.packages(c("httr", "jsonlite", "odbc", "DBI"))
#   remotes::install_github("AKU-CDIO/fabric-inbound-access", subdir = "fabriconnect")
# ============================================================================

library(httr)
library(jsonlite)
library(odbc)
library(DBI)
library(fabriconnect)

fabric_connect <- function(
  auth     = c("sp_vault", "device_code"),
  database = "uzima_db_backup",
  vault_url = "https://uzima-secrets-xfmh.vault.azure.net",
  server    = "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"
) {
  auth <- match.arg(auth)

  # Step 1: Device code → browser login → get token
  cfg <- jsonlite::fromJSON(system.file("config.json", package = "fabriconnect"))
  token <- fabriconnect:::.get_fabric_token(cfg$fabric_tenant)

  if (auth == "device_code") {
    # Return OneLake connection (fabriconnect style)
    return(connect_to_fabric())
  }

  # Path A: SP + Key Vault → ODBC SQL

  # Step 2: Token → Key Vault → get SP credentials
  fetch_secret <- function(name) {
    url <- paste0(vault_url, "/secrets/", name, "?api-version=7.4")
    resp <- GET(url, add_headers(Authorization = paste("Bearer", token)))
    stop_for_status(resp)
    content(resp)$value
  }

  tenant_id     <- fetch_secret("fabric-sp-tenant-id")
  client_id     <- fetch_secret("fabric-sp-client-id")
  client_secret <- fetch_secret("fabric-sp-client-secret")

  # Step 3: SP credentials → SQL token
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

  # Step 4: SQL token → ODBC connection
  con <- dbConnect(
    odbc::odbc(),
    Driver      = "ODBC Driver 18 for SQL Server",
    Server      = paste0(server, ",1433"),
    Database    = database,
    UID         = 1,
    AccessToken = sql_token,
    Encrypt     = "yes",
    TrustServerCertificate = "no",
    Timeout     = 30
  )

  con
}
