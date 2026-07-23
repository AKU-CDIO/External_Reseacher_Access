"""
Fabric SQL connection helper.

Usage:
    from fabric_helpers import connect_to_fabric, list_tables, read_table, query_sql

    conn = connect_to_fabric()   # browser opens for login
    print(list_tables(conn))
    df = read_table(conn, "dbo.DimEnrolledParticipants")
"""

import struct
import pandas as pd
import pyodbc
from azure.identity import InteractiveBrowserCredential, ClientSecretCredential
from azure.keyvault.secrets import SecretClient

def connect_to_fabric(database=None):
    vault_url = "https://uzima-secrets-xfmh.vault.azure.net"
    kv_tenant = "4fde8ff3-4dd5-42e1-a25a-e42905610d66"
    server    = "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"
    db        = database or "uzima_db_backup"

    kv_client = SecretClient(vault_url, InteractiveBrowserCredential(tenant_id=kv_tenant))
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
        f"Database={db};"
        "Encrypt=yes;TrustServerCertificate=no;"
    )
    return pyodbc.connect(conn_str, attrs_before={1256: token_struct}, timeout=30)


def list_tables(conn):
    return pd.read_sql_query(
        "SELECT TABLE_SCHEMA, TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_SCHEMA, TABLE_NAME",
        conn
    )


def read_table(conn, table_name, columns=None):
    cols = ", ".join(columns) if columns else "*"
    return pd.read_sql_query(f"SELECT {cols} FROM {table_name}", conn)


def query_sql(conn, sql):
    return pd.read_sql_query(sql, conn)
