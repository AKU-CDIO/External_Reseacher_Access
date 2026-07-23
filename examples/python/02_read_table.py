"""
Example 2: Read Table + SQL Query

Equivalent to: external_researcher_python.py (from fabric-inbound-access repo)
But uses ODBC via Key Vault instead of fabricpy package.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fabric_helpers import get_connection, list_tables, read_table, query_sql

def main():
    conn = get_connection()

    # List tables
    tables = list_tables(conn)
    print(f"Found {len(tables)} tables:\n")
    for t in tables[:10]:
        print(f"  {t}")
    if len(tables) > 10:
        print(f"  ... and {len(tables) - 10} more")

    # Read specific columns
    print("\nReading dimenrolledparticipants (first 5 rows)...")
    df = read_table(conn, "dbo.Dimenrolledparticipants",
                    columns=["ParticipantIdentifier", "Gender", "Age"])
    print(df.head())
    print(f"\nShape: {df.shape}")

    # SQL query
    print("\nRunning SQL query...")
    result = query_sql(conn, "SELECT COUNT(*) AS cnt FROM dbo.DimenrolledParticipants")
    print(result)

    conn.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
