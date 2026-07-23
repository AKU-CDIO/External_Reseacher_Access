# ============================================================================
# UZIMA Fabric Connection Helper
#
# Usage:
#   conn <- fabric_connect(auth = "sp_vault")       # Device Code → Key Vault → SP → ODBC
#   conn <- fabric_connect(auth = "device_code")    # Device Code → OneLake
#   conn <- fabric_connect(auth = "token", token = "eyJ...")  # Existing token
#
# Exploration (works with any connection):
#   fabric_list_tables(conn)
#   fabric_read_table(conn, "dimenrolledparticipants")
#   fabric_query(conn, "SELECT ...")
#   fabric_disconnect(conn)
# ============================================================================

library(httr)
library(jsonlite)
library(odbc)
library(DBI)
library(fabriconnect)

fabric_connect <- function(
  auth       = c("sp_vault", "device_code", "token"),
  token      = NULL,
  database   = "uzima_db_backup",
  vault_url  = "https://uzima-secrets-xfmh.vault.azure.net",
  server     = "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com",
  lakehouse  = NULL
) {
  auth <- match.arg(auth)

  # Device code → browser login → get OneLake token
  cfg <- jsonlite::fromJSON(system.file("config.json", package = "fabriconnect"))
  onelake_token <- fabriconnect:::.get_fabric_token(cfg$fabric_tenant)

  if (auth == "device_code") {
    if (!is.null(lakehouse)) {
      return(connect_to_fabric(lakehouse = lakehouse))
    }
    return(connect_to_fabric())
  }

  if (auth == "token") {
    if (is.null(token)) stop("token = required when auth = 'token'")
    return(connect_to_fabric(access_token = token))
  }

  # auth == "sp_vault"
  # Step 2: Token → Key Vault → get SP credentials
  fetch_secret <- function(name) {
    url <- paste0(vault_url, "/secrets/", name, "?api-version=7.4")
    resp <- GET(url, add_headers(Authorization = paste("Bearer", onelake_token)))
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

  attr(con, "auth_type") <- "sp_vault"
  con
}

# ---- Exploration helpers (work with any connection type) ----

fabric_list_tables <- function(conn) {
  if (inherits(conn, "DBIConnection")) {
    result <- dbGetQuery(conn, "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME")
    result$TABLE_NAME
  } else if (inherits(conn, "fabric_connection")) {
    list_tables(conn)
  } else {
    stop("Unknown connection type")
  }
}

fabric_read_table <- function(conn, table_name) {
  if (inherits(conn, "DBIConnection")) {
    dbReadTable(conn, paste0("dbo.", table_name))
  } else if (inherits(conn, "fabric_connection")) {
    read_table(conn, table_name)
  } else {
    stop("Unknown connection type")
  }
}

fabric_query <- function(conn, sql) {
  if (inherits(conn, "DBIConnection")) {
    dbGetQuery(conn, sql)
  } else if (inherits(conn, "fabric_connection")) {
    query_tables(conn, sql)
  } else {
    stop("Unknown connection type")
  }
}

fabric_disconnect <- function(conn) {
  if (inherits(conn, "DBIConnection")) {
    dbDisconnect(conn)
  }
  invisible(NULL)
}
