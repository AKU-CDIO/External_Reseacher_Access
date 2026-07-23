"""
UZIMA Fabric SQL — List Tables
pip install "fabricpy[pandas,sql] @ git+https://github.com/AKU-CDIO/fabric-inbound-access.git#subdirectory=fabriconnectpy"
"""
from fabricpy import FabricLakehouse

lh = FabricLakehouse()
tables = lh.list_tables()
for t in tables:
    print(t)
