"""
UZIMA Fabric SQL — Read Table
pip install "fabricpy[pandas,sql] @ git+https://github.com/AKU-CDIO/fabric-inbound-access.git#subdirectory=fabriconnectpy"
"""
from fabricpy import FabricLakehouse

lh = FabricLakehouse()

# Read all columns
df = lh.to_pandas("dimenrolledparticipants")
print(df.head())
print(f"\nRows: {len(df)}, Columns: {len(df.columns)}")

# Read specific columns (faster)
df2 = lh.to_pandas("dimenrolledparticipants", columns=["ParticipantIdentifier", "Gender", "Age"])
print(f"\nSpecific columns:\n{df2.head()}")
