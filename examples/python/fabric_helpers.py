"""
Shared Fabric SQL connection helper via Key Vault + ODBC.

Usage:
    from fabric_helpers import get_connection, fetch_secret

All examples import this module for authentication.
"""

import struct
import pyodbc
from azure.identity import InteractiveBrowserCredential, ClientSecretCredential
from azure.keyvault.secrets import SecretClient

VAULT_URL = "https://uzima-secrets-xfmh.vault.azure.net"
KV_TENANT_ID = "4fde8ff3-4dd5-42e1-a25a-e42905610d66"

SERVER = "fis5jjpzajqe5fxqs4z3vlsjde-zgopmz6jacoezkc3hd6da52lpm.datawarehouse.fabric.microsoft.com"
DATABASE = "uzima_db_backup"


def get_kv_client():
    credential = InteractiveBrowserCredential(tenant_id=KV_TENANT_ID)
    return SecretClient(VAULT_URL, credential)


def fetch_secret(kv_client, name):
    return kv_client.get_secret(name).value


def get_fabric_token(kv_client):
    tenant_id = fetch_secret(kv_client, "fabric-sp-tenant-id")
    client_id = fetch_secret(kv_client, "fabric-sp-client-id")
    client_secret = fetch_secret(kv_client, "fabric-sp-client-secret")
    return ClientSecretCredential(
        tenant_id, client_id, client_secret
    ).get_token("https://database.windows.net/.default").token


def get_connection(database=None):
    kv_client = get_kv_client()
    token = get_fabric_token(kv_client)

    token_bytes = token.encode("utf-16-le")
    token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)

    db = database or DATABASE
    connection_string = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{SERVER},1433;"
        f"Database={db};"
        "Encrypt=yes;TrustServerCertificate=no;"
    )

    return pyodbc.connect(
        connection_string,
        attrs_before={1256: token_struct},
        timeout=30,
    )


def list_tables(conn):
    cursor = conn.cursor()
    cursor.execute("""
        SELECT TABLE_SCHEMA, TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        ORDER BY TABLE_SCHEMA, TABLE_NAME
    """)
    return [f"{row.TABLE_SCHEMA}.{row.TABLE_NAME}" for row in cursor.fetchall()]


def read_table(conn, table_name, columns=None):
    import pandas as pd
    cols = ", ".join(columns) if columns else "*"
    return pd.read_sql_query(f"SELECT {cols} FROM {table_name}", conn)


def query_sql(conn, sql):
    import pandas as pd
    return pd.read_sql_query(sql, conn)
