"""
UZIMA Fabric Data Access — Python Test
Run: python test_fabric.py

Prerequisites:
    pip install "fabricpy[pandas,sql] @ git+https://github.com/AKU-CDIO/fabric-inbound-access.git#subdirectory=fabriconnectpy"
"""
from fabricpy import FabricLakehouse

print("Connecting to Fabric...")
lh = FabricLakehouse()

# List tables
print("\n--- Tables ---")
tables = lh.list_tables()
print(f"Found {len(tables)} tables")
for t in tables[:10]:
    print(f"  {t}")
if len(tables) > 10:
    print(f"  ... and {len(tables) - 10} more")

# Read a table
print("\n--- Read dimenrolledparticipants ---")
df = lh.to_pandas("dimenrolledparticipants")
print(f"Rows: {len(df)}, Columns: {len(df.columns)}")
print(df.head())

# SQL query
print("\n--- Demographics ---")
demo = lh.sql("SELECT Gender, COUNT(*) AS total FROM dimenrolledparticipants WHERE Gender IS NOT NULL GROUP BY Gender")
print(demo)

# SQL JOIN
print("\n--- Sleep summary ---")
result = lh.sql("""
    SELECT p.ParticipantIdentifier, COUNT(*) AS sleep_logs
    FROM dimenrolledparticipants p
    JOIN factfitbitsleeplogs s ON p.ParticipantIdentifier = s.ParticipantIdentifier
    GROUP BY p.ParticipantIdentifier
    ORDER BY sleep_logs DESC
""")
print(result.head(10))

print("\nDone!")
