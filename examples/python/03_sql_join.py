"""
UZIMA Fabric SQL — SQL JOINs
pip install "fabricpy[pandas,sql] @ git+https://github.com/AKU-CDIO/fabric-inbound-access.git#subdirectory=fabriconnectpy"
"""
from fabricpy import FabricLakehouse

lh = FabricLakehouse()

# Sleep summary per participant
result = lh.sql("""
    SELECT p.ParticipantIdentifier, p.Gender,
           COUNT(*) AS sleep_logs,
           AVG(s.MinutesAsleep) AS avg_sleep
    FROM dimenrolledparticipants p
    JOIN factfitbitsleeplogs s ON p.ParticipantIdentifier = s.ParticipantIdentifier
    GROUP BY p.ParticipantIdentifier, p.Gender
    ORDER BY sleep_logs DESC
""")
print("Sleep summary (top 10):\n", result.head(10))

# Demographics
demo = lh.sql("""
    SELECT Gender, COUNT(*) AS total, AVG(Age) AS avg_age
    FROM dimenrolledparticipants
    WHERE Gender IS NOT NULL
    GROUP BY Gender
""")
print("\nDemographics:\n", demo)
