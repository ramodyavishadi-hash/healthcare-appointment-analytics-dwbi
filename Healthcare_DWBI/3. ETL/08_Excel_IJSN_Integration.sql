USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI
   XLSX / IJSN NEIGHBOURHOOD INTEGRATION

   Source:
   dbo.IJSN_Neighbourhood_Import

   Target:
   dbo.DimLocation

   Purpose:
   Enrich healthcare appointment neighbourhoods with
   geographical information from the IJSN Excel source.

   Note:
   The enrichment columns are created in
   03_Create_Dimensions.sql. Therefore this ETL script
   only updates those existing columns.
   ========================================================= */


/* =========================================================
   1. VALIDATE IJSN SOURCE DATA
   ========================================================= */

SELECT
    COUNT(*) AS IJSNSourceRows,
    COUNT(DISTINCT nome) AS DistinctNeighbourhoods,
    COUNT(DISTINCT municipio) AS DistinctMunicipalities
FROM dbo.IJSN_Neighbourhood_Import;
GO


/* =========================================================
   2. CLEAR PREVIOUS IJSN ENRICHMENT

   Makes the enrichment stage safe to rerun without
   recreating or duplicating DimLocation records.
   ========================================================= */

UPDATE dbo.DimLocation
SET
    Municipality      = NULL,
    MunicipalityCode  = NULL,
    AreaM2            = NULL,
    MacroRegion       = NULL,
    MicroRegion       = NULL,
    IJSNReferenceYear = NULL;
GO


/* =========================================================
   3. ENRICH DIMLOCATION FROM IJSN EXCEL SOURCE
   ========================================================= */

UPDATE d
SET
    d.Municipality =
        LTRIM(RTRIM(i.municipio)),

    d.MunicipalityCode =
        TRY_CONVERT(INT, i.geocMun),

    d.AreaM2 =
        TRY_CONVERT(FLOAT, i.areaM2),

    d.MacroRegion =
        LTRIM(RTRIM(i.macroEstad)),

    d.MicroRegion =
        LTRIM(RTRIM(i.microEstad)),

    d.IJSNReferenceYear =
        LTRIM(RTRIM(i.anoReferen))

FROM dbo.DimLocation d

INNER JOIN dbo.IJSN_Neighbourhood_Import i

    ON UPPER(LTRIM(RTRIM(d.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI
       =
       UPPER(LTRIM(RTRIM(i.nome)))
       COLLATE Latin1_General_100_CI_AI

WHERE
    i.municipio COLLATE Latin1_General_100_CI_AI
        = N'Vitória';
GO


/* =========================================================
   4. INTEGRATION VALIDATION
   ========================================================= */

SELECT
    COUNT(*) AS TotalLocations,

    SUM
    (
        CASE
            WHEN Municipality IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS EnrichedLocations,

    SUM
    (
        CASE
            WHEN Municipality IS NULL THEN 1
            ELSE 0
        END
    ) AS UnmatchedLocations

FROM dbo.DimLocation;
GO


/* =========================================================
   5. CALCULATE MATCH PERCENTAGE
   ========================================================= */

SELECT
    COUNT(*) AS TotalLocations,

    SUM
    (
        CASE
            WHEN Municipality IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS MatchedLocations,

    CAST
    (
        100.0 *
        SUM
        (
            CASE
                WHEN Municipality IS NOT NULL THEN 1
                ELSE 0
            END
        )
        /
        NULLIF(COUNT(*), 0)

        AS DECIMAL(5,2)
    ) AS MatchPercentage

FROM dbo.DimLocation;
GO


/* =========================================================
   6. DISPLAY ENRICHED LOCATION SAMPLE
   ========================================================= */

SELECT TOP 20
    LocationKey,
    Neighbourhood,
    Municipality,
    MunicipalityCode,
    AreaM2,
    MacroRegion,
    MicroRegion,
    IJSNReferenceYear

FROM dbo.DimLocation

WHERE Municipality IS NOT NULL

ORDER BY Neighbourhood;
GO


/* =========================================================
   7. IDENTIFY UNMATCHED LOCATIONS
   ========================================================= */

SELECT
    LocationKey,
    Neighbourhood

FROM dbo.DimLocation

WHERE Municipality IS NULL

ORDER BY Neighbourhood;
GO