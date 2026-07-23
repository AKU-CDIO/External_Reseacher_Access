# ============================================================================
# SQL JOIN + Demographics
# ============================================================================

library(httr); library(jsonlite); library(odbc); library(DBI); library(dplyr)

connect_to_fabric <- function() {
  vault_url <- "https://uzima-secrets-xfmh.vault.azure.net"
  kv_tenant <- "4fde8ff3-4dd5-42e1-a25a-e42905610d66"
  server    <- "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"

  token_kv <- AzureAuth::get_azure_token(resource = "https://vault.azure.net",
    tenant = kv_tenant, app = "04b07795-c8b7-4bab-9fb9-464329ae7e9e",
    auth_type = "device_code", use_cache = FALSE)

  get_secret <- function(name) {
    resp <- GET(paste0(vault_url, "/secrets/", name, "?api-version=7.4"),
                add_headers(Authorization = paste("Bearer", token_kv$credentials$access_token)))
    stop_for_status(resp); content(resp)$value
  }

  tid <- get_secret("fabric-sp-tenant-id")
  cid <- get_secret("fabric-sp-client-id")
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

cat("Sleep summary (top 10):\n\n")
result <- dbGetQuery(con, "
  SELECT p.ParticipantIdentifier, p.Gender, p.Age,
         COUNT(*) AS sleep_logs, AVG(s.MinutesAsleep) AS avg_sleep
  FROM dbo.DimenrolledParticipants p
  JOIN dbo.FactFitBitSleepLog s ON p.ParticipantIdentifier = s.ParticipantIdentifier
  GROUP BY p.ParticipantIdentifier, p.Gender, p.Age
  ORDER BY sleep_logs DESC
")
print(head(result, 10))

cat("\nDemographics:\n\n")
demo <- dbGetQuery(con, "
  SELECT Gender, COUNT(*) AS total, AVG(Age) AS avg_age,
         MIN(Age) AS min_age, MAX(Age) AS max_age
  FROM dbo.DimenrolledParticipants WHERE Gender IS NOT NULL GROUP BY Gender
")
print(demo)

dbDisconnect(con)
