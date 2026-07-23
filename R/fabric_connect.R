#' Connect to UZIMA Fabric Data
#'
#' Authenticates to Microsoft Fabric and returns a connection object.
#' Supports multiple authentication methods.
#'
#' @param auth Authentication method: "sp_vault", "device_code", "token", or "env"
#' @param token Access token (required when auth = "token")
#' @param database Database name (default: "uzima_db_backup")
#' @param vault_url Key Vault URL
#' @param server Fabric SQL server
#' @param lakehouse Lakehouse name (for device_code auth)
#' @param env_var Environment variable name (for env auth)
#' @return A database connection (DBIConnection) or Fabric connection (fabric_connection)
#' @export
fabric_connect <- function(
  auth       = c("env", "sp_vault", "device_code", "token"),
  token      = NULL,
  database   = "uzima_db_backup",
  vault_url  = "https://uzima-secrets-xfmh.vault.azure.net",
  server     = "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com",
  lakehouse  = NULL,
  env_var    = c("FABRIC_ACCESS_TOKEN", "FABRIC_DELEGATED_ACCESS_TOKEN", "AZURE_ACCESS_TOKEN")
) {
  auth <- match.arg(auth)

  if (auth == "token") {
    if (is.null(token)) stop("token = required when auth = 'token'")
    return(fabriconnect::connect_to_fabric(access_token = token))
  }

  if (auth == "env") {
    # Check all env var names, use the first one found
    token_val <- ""
    used_var  <- ""
    for (v in env_var) {
      val <- Sys.getenv(v, unset = "")
      if (nzchar(val)) {
        token_val <- val
        used_var  <- v
        break
      }
    }
    if (!nzchar(token_val)) {
      stop("None of the environment variables are set: ",
           paste(env_var, collapse = ", "),
           ". Set one of them with Sys.setenv() or setx.")
    }
    message("Using token from: ", used_var)
    return(fabriconnect::connect_to_fabric(access_token = token_val))
  }

  # Device code → browser login → get tokens
  cfg <- jsonlite::fromJSON(system.file("config.json", package = "fabriconnect"))
  tenant <- cfg$fabric_tenant

  if (auth == "device_code") {
    if (!is.null(lakehouse)) {
      return(fabriconnect::connect_to_fabric(lakehouse = lakehouse))
    }
    return(fabriconnect::connect_to_fabric())
  }

  # auth == "sp_vault"
  # Try az CLI first (works with external identities), fallback to device code
  az_cmd <- if (file.exists("C:/Program Files/Microsoft SDKs/Azure/CLI2/wbin/az.cmd")) {
    "C:/Program Files/Microsoft SDKs/Azure/CLI2/wbin/az.cmd"
  } else {
    "az"
  }

  get_kv_token <- function() {
    r <- processx::run(az_cmd, c("account", "get-access-token", "--resource", "https://vault.azure.net", "--output", "json"),
                       error_on_status = FALSE)
    if (r$status == 0) {
      return(jsonlite::fromJSON(r$stdout)$accessToken)
    }
    # Fallback: device code for Key Vault
    kv_token <- fabriconnect:::.try_msal_device_code(tenant, "https://vault.azure.net")
    if (!is.null(kv_token)) return(kv_token$access_token)
    stop("Failed to get Key Vault token. Run 'az login' first or use auth='device_code'.")
  }

  kv_access_token <- get_kv_token()

  # Step 2: Token → Key Vault → get SP credentials
  fetch_secret <- function(name) {
    url <- paste0(vault_url, "/secrets/", name, "?api-version=7.4")
    resp <- httr::GET(url, httr::add_headers(Authorization = paste("Bearer", kv_access_token)))
    httr::stop_for_status(resp)
    httr::content(resp)$value
  }

  tenant_id     <- fetch_secret("fabric-sp-tenant-id")
  client_id     <- fetch_secret("fabric-sp-client-id")
  client_secret <- fetch_secret("fabric-sp-client-secret")

  # Step 4: ODBC connection — driver handles token via SP creds
  con <- DBI::dbConnect(
    odbc::odbc(),
    Driver                   = "ODBC Driver 18 for SQL Server",
    Server                   = paste0(server, ",1433"),
    Database                 = database,
    Authentication           = "ActiveDirectoryServicePrincipal",
    UID                      = client_id,
    pwd                      = client_secret,
    Encrypt                  = "yes",
    TrustServerCertificate   = "no",
    Timeout                  = 30
  )

  attr(con, "auth_type") <- "sp_vault"
  con
}

#' List Tables
#'
#' Lists all tables in the connected database.
#' Works with both DBI and fabric_connection objects.
#'
#' @param conn Connection object from fabric_connect()
#' @return Character vector of table names
#' @export
fabric_list_tables <- function(conn) {
  if (inherits(conn, "DBIConnection")) {
    result <- DBI::dbGetQuery(conn, "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME")
    # Filter out internal views and materialized tables
    tabs <- result$TABLE_NAME[!grepl("^(_vw_|_mat_|dm_|sys|exec_|managed_|external_|sql_pool|frequently|long_running)", result$TABLE_NAME, ignore.case = TRUE)]
    tabs
  } else if (inherits(conn, "fabric_connection")) {
    fabriconnect::list_tables(conn)
  } else {
    stop("Unknown connection type")
  }
}

#' Read Table
#'
#' Reads a table into a data frame.
#' Works with both DBI and fabric_connection objects.
#'
#' @param conn Connection object from fabric_connect()
#' @param table_name Name of the table to read
#' @return Data frame with table data
#' @export
fabric_read_table <- function(conn, table_name) {
  if (inherits(conn, "DBIConnection")) {
    # Query without quotes so SQL Server handles case-insensitive matching
    sql <- paste0("SELECT * FROM ", table_name)
    DBI::dbGetQuery(conn, sql)
  } else if (inherits(conn, "fabric_connection")) {
    fabriconnect::read_table(conn, table_name)
  } else {
    stop("Unknown connection type")
  }
}

#' Run SQL Query
#'
#' Executes a SQL query and returns results.
#' Works with both DBI and fabric_connection objects.
#'
#' @param conn Connection object from fabric_connect()
#' @param sql SQL query string
#' @return Data frame with query results
#' @export
fabric_query <- function(conn, sql) {
  if (inherits(conn, "DBIConnection")) {
    DBI::dbGetQuery(conn, sql)
  } else if (inherits(conn, "fabric_connection")) {
    fabriconnect::query_tables(conn, sql)
  } else {
    stop("Unknown connection type")
  }
}

#' Disconnect
#'
#' Closes the database connection.
#'
#' @param conn Connection object from fabric_connect()
#' @return Invisible NULL
#' @export
fabric_disconnect <- function(conn) {
  if (inherits(conn, "DBIConnection")) {
    DBI::dbDisconnect(conn)
  }
  invisible(NULL)
}
