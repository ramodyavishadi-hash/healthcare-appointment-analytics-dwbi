USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI
   JSON HEALTHCARE FACILITY INTEGRATION

   Source:
   Vitoria_Healthcare_Facilities.json

   Purpose:
   1. Read the original UTF-8 JSON source.
   2. Validate the JSON.
   3. Extract healthcare facility information.
   4. Store Unicode text in dbo.HealthFacility_Import.
   5. Validate imported records.

   NOTE:
   If the project folder is moved, update @JsonFilePath.
   ========================================================= */


/* =========================================================
   1. CREATE / RESET IMPORT TABLE
   ========================================================= */

DROP TABLE IF EXISTS dbo.HealthFacility_Import;
GO

CREATE TABLE dbo.HealthFacility_Import
(
    FacilityName       NVARCHAR(200) NULL,
    Neighbourhood      NVARCHAR(150) NULL,
    FacilityType       NVARCHAR(200) NULL,
    Nature             NVARCHAR(100) NULL,
    NeighbourhoodCode  INT NULL,
    CNES               INT NULL
);
GO


/* =========================================================
   2. CONFIGURE SOURCE FILE
   ========================================================= */

DECLARE @JsonFilePath NVARCHAR(1000);

SET @JsonFilePath =
N'D:\SLIIT\Y3 semester 1\DWBI\Healthcare_DWBI\1. Raw_Data\Vitoria_Healthcare_Facilities.json';


/* =========================================================
   3. READ ORIGINAL UTF-8 JSON FILE
   ========================================================= */

DECLARE @Json VARCHAR(MAX);
DECLARE @SQL NVARCHAR(MAX);

SET @SQL = N'
SELECT @JsonOutput = BulkColumn
FROM OPENROWSET
(
    BULK ''' + REPLACE(@JsonFilePath, '''', '''''') + ''',
    SINGLE_CLOB,
    CODEPAGE = ''65001''
) AS JSONFile;
';

EXEC sys.sp_executesql
    @SQL,
    N'@JsonOutput VARCHAR(MAX) OUTPUT',
    @JsonOutput = @Json OUTPUT;


/* =========================================================
   4. VALIDATE JSON BEFORE PROCESSING
   ========================================================= */

IF @Json IS NULL
BEGIN
    THROW 50001,
          'The healthcare facility JSON file could not be read.',
          1;
END;

IF ISJSON(@Json) <> 1
BEGIN
    THROW 50002,
          'The healthcare facility source file is not valid JSON.',
          1;
END;


/* =========================================================
   5. LOAD JSON DATA INTO IMPORT TABLE
   ========================================================= */

INSERT INTO dbo.HealthFacility_Import
(
    FacilityName,
    Neighbourhood,
    FacilityType,
    Nature,
    NeighbourhoodCode,
    CNES
)
SELECT
    NULLIF(LTRIM(RTRIM(FacilityName)), N''),
    NULLIF(LTRIM(RTRIM(Neighbourhood)), N''),
    NULLIF(LTRIM(RTRIM(FacilityType)), N''),
    NULLIF(LTRIM(RTRIM(Nature)), N''),
    NeighbourhoodCode,
    CNES

FROM OPENJSON(@Json, '$.features')

WITH
(
    FacilityName
        NVARCHAR(200) '$.attributes.nomeUnidade',

    Neighbourhood
        NVARCHAR(150) '$.attributes.bairro',

    FacilityType
        NVARCHAR(200) '$.attributes.tipo',

    Nature
        NVARCHAR(100) '$.attributes.natureza',

    NeighbourhoodCode
        INT '$.attributes.codBairro',

    CNES
        INT '$.attributes.CNES'
);
GO


/* =========================================================
   6. VALIDATE IMPORT COUNTS
   ========================================================= */

SELECT
    COUNT(*) AS TotalImportedFacilities,

    COUNT(DISTINCT CNES) AS DistinctCNES,

    SUM
    (
        CASE
            WHEN FacilityName IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingFacilityNames,

    SUM
    (
        CASE
            WHEN Neighbourhood IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingNeighbourhoods,

    SUM
    (
        CASE
            WHEN FacilityType IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingFacilityTypes,

    SUM
    (
        CASE
            WHEN CNES IS NULL THEN 1
            ELSE 0
        END
    ) AS MissingCNES

FROM dbo.HealthFacility_Import;
GO


/* =========================================================
   7. DISPLAY SAMPLE IMPORTED RECORDS
   ========================================================= */

SELECT TOP 20
    FacilityName,
    Neighbourhood,
    FacilityType,
    Nature,
    CNES
FROM dbo.HealthFacility_Import
ORDER BY FacilityName;
GO


/* =========================================================
   8. UNICODE / PORTUGUESE TEXT VALIDATION
   ========================================================= */

SELECT
    FacilityName,
    Neighbourhood,
    FacilityType
FROM dbo.HealthFacility_Import
WHERE FacilityName LIKE N'%SAÚDE%'
   OR FacilityName LIKE N'%ATENÇÃO%'
   OR FacilityName LIKE N'%FARMÁCIA%'
   OR Neighbourhood = N'SÃO JOSÉ'
ORDER BY FacilityName;
GO


/* =========================================================
   9. NEIGHBOURHOOD MATCHING VALIDATION

   Checks how many JSON neighbourhoods can be matched
   to the existing DimLocation records.
   ========================================================= */

SELECT
    COUNT(*) AS TotalFacilityRecords,

    SUM
    (
        CASE
            WHEN l.LocationKey IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS MatchedFacilityRecords,

    SUM
    (
        CASE
            WHEN l.LocationKey IS NULL THEN 1
            ELSE 0
        END
    ) AS UnmatchedFacilityRecords

FROM dbo.HealthFacility_Import hf

LEFT JOIN dbo.DimLocation l
    ON UPPER(LTRIM(RTRIM(hf.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI
       =
       UPPER(LTRIM(RTRIM(l.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI;
GO


/* =========================================================
   10. SHOW UNMATCHED NEIGHBOURHOODS
   ========================================================= */

SELECT DISTINCT
    hf.Neighbourhood AS UnmatchedNeighbourhood
FROM dbo.HealthFacility_Import hf

LEFT JOIN dbo.DimLocation l
    ON UPPER(LTRIM(RTRIM(hf.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI
       =
       UPPER(LTRIM(RTRIM(l.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI

WHERE l.LocationKey IS NULL

ORDER BY hf.Neighbourhood;
GO