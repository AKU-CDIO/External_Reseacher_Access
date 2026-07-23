"""
Example 1: Basic Connection + List Tables

Equivalent to: python test_delegated_access.py (from fabric-inbound-access repo)
But uses ODBC via Key Vault instead of fabricpy package.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fabric_helpers import get_connection, list_tables

def main():
    conn = get_connection()
    tables = list_tables(conn)

    print(f"OK - {len(tables)} tables found\n")
    for t in tables:
        print(f"  {t}")

    conn.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
