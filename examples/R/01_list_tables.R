# ============================================================================
# Test: Connect + List Tables
# Prerequisites: install.packages(c("httr","jsonlite","odbc","DBI","dplyr","processx"))
#                ODBC Driver 18 for SQL Server + Azure CLI (az login)
# ============================================================================

library(httr); library(jsonlite); library(odbc); library(DBI); library(dplyr); library(processx)

connect_to_fabric <- function() {
  vault_url <- "https://uzima-secrets-xfmh.vault.azure.net"
  server    <- "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"

  az_token <- function(resource) {
    r <- processx::run("az", c("account", "get-access-token", "--resource", resource, "--output", "json"),
                       error_on_status = FALSE)
    if (r$status != 0) stop("Run 'az login' first in a terminal.")
    fromJSON(r$stdout)$accessToken
  }

  get_secret <- function(name) {
    tok <- az_token("https://vault.azure.net")
    resp <- GET(paste0(vault_url, "/secrets/", name, "?api-version=7.4"),
                add_headers(Authorization = paste("Bearer", tok)))
    stop_for_status(resp); content(resp)$value
  }

  tid  <- get_secret("fabric-sp-tenant-id")
  cid  <- get_secret("fabric-sp-client-id")
  csec <- get_secret("fabric-sp-client-secret")

  resp <- POST(paste0("https://login.microsoftonline.com/", tid, "/oauth2/v2.0/token"),
               body = list(grant_type="client_credentials", client_id=cid,
                           client_secret=csec, scope="https://database.windows.net/.default"),
               encode = "form")
  stop_for_status(resp)

  dbConnect(odbc::odbc(), Driver = "ODBC Driver 18 for SQL Server",
            Server = paste0(server, ",1433"), Database = "uzima_db_backup",
            UID = 1, AccessToken = content(resp)$access_token,
            Encrypt = "yes", TrustServerCertificate = "no", Timeout = 30)
}

con <- connect_to_fabric()
tables <- dbGetQuery(con, "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_SCHEMA, TABLE_NAME")
cat("Tables found:", nrow(tables), "\n")
print(tables)
dbDisconnect(con)
