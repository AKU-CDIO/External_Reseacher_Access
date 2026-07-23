"""
Example 1: Connect + List Tables
Fully standalone — copy this file and run it.
"""

import struct
import pandas as pd
import pyodbc
from azure.identity import AzureCliCredential, ClientSecretCredential
from azure.keyvault.secrets import SecretClient

def connect_to_fabric():
    vault_url = "https://uzima-secrets-xfmh.vault.azure.net"
    kv_tenant = "4fde8ff3-4dd5-42e1-a25a-e42905610d66"
    server    = "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"

    kv_client = SecretClient(vault_url, AzureCliCredential(tenant_id=kv_tenant))
    tenant_id = kv_client.get_secret("fabric-sp-tenant-id").value
    client_id = kv_client.get_secret("fabric-sp-client-id").value
    client_secret = kv_client.get_secret("fabric-sp-client-secret").value

    token = ClientSecretCredential(tenant_id, client_id, client_secret
        ).get_token("https://database.windows.net/.default").token

    token_bytes = token.encode("utf-16-le")
    token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)

    conn_str = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{server},1433;"
        "Database=uzima_db_backup;"
        "Encrypt=yes;TrustServerCertificate=no;"
    )
    return pyodbc.connect(conn_str, attrs_before={1256: token_struct}, timeout=30)


conn = connect_to_fabric()
print("Connected!\n")

tables = pd.read_sql_query(
    "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_SCHEMA, TABLE_NAME",
    conn
)
print(tables.to_string(index=False))
conn.close()
