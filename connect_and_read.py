"""
UZIMA Fabric SQL — Connect and Read
pip install "fabricpy[pandas,sql] @ git+https://github.com/AKU-CDIO/fabric-inbound-access.git#subdirectory=fabriconnectpy"
"""
from fabricpy import FabricLakehouse

lh = FabricLakehouse()

# List tables
tables = lh.list_tables()
print(f"Tables ({len(tables)}):\n")
for t in tables:
    print(t)

# Read top 10 participants
df = lh.to_pandas("dimenrolledparticipants")
print(f"\nTop 10 participants:\n{df.head(10)}")
