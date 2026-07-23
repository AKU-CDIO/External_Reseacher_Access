"""
Example 3: SQL JOIN across tables

Equivalent to: test_fabriconnect.R SQL JOIN example (from fabric-inbound-access repo)
But uses ODBC via Key Vault instead of fabriconnect package.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fabric_helpers import get_connection, query_sql

def main():
    conn = get_connection()

    # Sleep summary per participant
    print("Sleep summary per participant (top 10):\n")
    result = query_sql(conn, """
        SELECT p.ParticipantIdentifier, p.Gender, p.Age,
               COUNT(*) AS sleep_logs,
               AVG(s.MinutesAsleep) AS avg_min_asleep,
               AVG(s.TimeInBed) AS avg_min_in_bed
        FROM dbo.DimenrolledParticipants p
        JOIN dbo.FactFitBitSleepLog s
          ON p.ParticipantIdentifier = s.ParticipantIdentifier
        GROUP BY p.ParticipantIdentifier, p.Gender, p.Age
        ORDER BY sleep_logs DESC
    """)
    print(result.head(10))

    # Demographics
    print("\nDemographics:\n")
    demo = query_sql(conn, """
        SELECT Gender, COUNT(*) AS total, AVG(Age) AS avg_age,
               MIN(Age) AS min_age, MAX(Age) AS max_age
        FROM dbo.DimenrolledParticipants
        WHERE Gender IS NOT NULL
        GROUP BY Gender
    """)
    print(demo)

    conn.close()
    print("\nDone.")

if __name__ == "__main__":
    main()
