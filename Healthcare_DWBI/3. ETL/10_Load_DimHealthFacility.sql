USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI
   LOAD HEALTH FACILITY DIMENSION

   Source:
   dbo.HealthFacility_Import

   Relationship:
   Health Facility -> Location

   Important:
   Healthcare facilities are NOT directly related to
   individual appointments because a location may contain
   multiple healthcare facilities.
   ========================================================= */


------------------------------------------------------------
-- 1. CLEAR EXISTING FACILITY DIMENSION
------------------------------------------------------------

DELETE FROM dbo.DimHealthFacility;
GO

DBCC CHECKIDENT ('dbo.DimHealthFacility', RESEED, 0);
GO


------------------------------------------------------------
-- 2. LOAD MATCHED HEALTHCARE FACILITIES
------------------------------------------------------------

INSERT INTO dbo.DimHealthFacility
(
    FacilityName,
    FacilityType,
    Nature,
    CNES,
    LocationKey
)
SELECT DISTINCT

    LTRIM(RTRIM(hf.FacilityName)),

    NULLIF(LTRIM(RTRIM(hf.FacilityType)), ''),

    NULLIF(LTRIM(RTRIM(hf.Nature)), ''),

    hf.CNES,

    l.LocationKey

FROM dbo.HealthFacility_Import hf

INNER JOIN dbo.DimLocation l
    ON UPPER(LTRIM(RTRIM(hf.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI
       =
       UPPER(LTRIM(RTRIM(l.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI

WHERE hf.FacilityName IS NOT NULL
  AND LTRIM(RTRIM(hf.FacilityName)) <> '';
GO


------------------------------------------------------------
-- 3. VALIDATE FACILITY LOAD
------------------------------------------------------------

SELECT COUNT(*) AS HealthFacilityDimensionRows
FROM dbo.DimHealthFacility;
GO


------------------------------------------------------------
-- 4. VALIDATE LOCATION RELATIONSHIPS
------------------------------------------------------------

SELECT COUNT(*) AS InvalidFacilityLocationReferences
FROM dbo.DimHealthFacility f
LEFT JOIN dbo.DimLocation l
    ON f.LocationKey = l.LocationKey
WHERE l.LocationKey IS NULL;
GO


------------------------------------------------------------
-- 5. IDENTIFY UNMATCHED SOURCE FACILITIES
------------------------------------------------------------

SELECT
    hf.FacilityName,
    hf.Neighbourhood,
    hf.FacilityType,
    hf.CNES
FROM dbo.HealthFacility_Import hf

LEFT JOIN dbo.DimLocation l
    ON UPPER(LTRIM(RTRIM(hf.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI
       =
       UPPER(LTRIM(RTRIM(l.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI

WHERE l.LocationKey IS NULL
ORDER BY hf.Neighbourhood, hf.FacilityName;
GO