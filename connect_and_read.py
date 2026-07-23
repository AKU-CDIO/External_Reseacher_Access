
import struct
import pandas as pd
import pyodbc
from azure.identity import InteractiveBrowserCredential, ClientSecretCredential
from azure.keyvault.secrets import SecretClient

VAULT_URL = "https://uzima-secrets-xfmh.vault.azure.net"
KV_TENANT_ID = "4fde8ff3-4dd5-42e1-a25a-e42905610d66"

SERVER = "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"
DATABASE = "uzima_db_backup"
TABLE_TO_READ = "dbo.dimenrolledparticipants"

kv_credential = InteractiveBrowserCredential(tenant_id=KV_TENANT_ID)
kv_client = SecretClient(VAULT_URL, kv_credential)
tenant_id = kv_client.get_secret("fabric-sp-tenant-id").value
client_id = kv_client.get_secret("fabric-sp-client-id").value
client_secret = kv_client.get_secret("fabric-sp-client-secret").value

token = ClientSecretCredential(
    tenant_id, client_id, client_secret
).get_token("https://database.windows.net/.default").token

token_bytes = token.encode("utf-16-le")
token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)

connection_string = (
    "Driver={ODBC Driver 18 for SQL Server};"
    f"Server=tcp:{SERVER},1433;"
    f"Database={DATABASE};"
    "Encrypt=yes;TrustServerCertificate=no;"
)

with pyodbc.connect(
    connection_string,
    attrs_before={1256: token_struct},
    timeout=30,
) as connection:

    tables = pd.read_sql_query(
        """
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        ORDER BY TABLE_SCHEMA, TABLE_NAME
        """,
        connection,
    )
    print(tables.head(30).to_string(index=False))

    sample = pd.read_sql_query(
        f"SELECT TOP 10 * FROM {TABLE_TO_READ}",
        connection,
    )
    print(sample.to_string(index=False))
