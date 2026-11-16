USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI
   PREPARE IJSN NEIGHBOURHOOD IMPORT

   Source:
   dbo.IJSN_Excel_Raw

   Target:
   dbo.IJSN_Neighbourhood_Import

   Purpose:
   Select only the geographical attributes required by
   the Healthcare Data Warehouse from the imported Excel
   worksheet.

   The raw Excel worksheet is imported through the
   SQL Server Import and Export Wizard.
   ========================================================= */


/* =========================================================
   1. CLEAR PREVIOUS IMPORT DATA
   ========================================================= */

DELETE FROM dbo.IJSN_Neighbourhood_Import;
GO


/* =========================================================
   2. LOAD REQUIRED IJSN ATTRIBUTES
   ========================================================= */

INSERT INTO dbo.IJSN_Neighbourhood_Import
(
    nome,
    municipio,
    geocMun,
    areaM2,
    macroEstad,
    microEstad,
    anoReferen
)
SELECT
    NULLIF(LTRIM(RTRIM(nome)), N''),
    NULLIF(LTRIM(RTRIM(municipio)), N''),
    CONVERT(NVARCHAR(50), TRY_CONVERT(BIGINT, geocMun)),
    TRY_CONVERT(FLOAT, areaM2),
    NULLIF(LTRIM(RTRIM(macroEstad)), N''),
    NULLIF(LTRIM(RTRIM(microEstad)), N''),
    CONVERT(NVARCHAR(50), TRY_CONVERT(INT, anoReferen))
FROM dbo.IJSN_Excel_Raw
WHERE nome IS NOT NULL;
GO


/* =========================================================
   3. VALIDATE IMPORT
   ========================================================= */

SELECT
    COUNT(*) AS IJSNImportRows,
    COUNT(DISTINCT nome) AS DistinctNeighbourhoods,
    COUNT(DISTINCT municipio) AS DistinctMunicipalities
FROM dbo.IJSN_Neighbourhood_Import;
GO


/* =========================================================
   4. VALIDATE VITORIA SOURCE RECORDS
   ========================================================= */

SELECT
    COUNT(*) AS VitoriaSourceRows,
    COUNT(DISTINCT nome) AS VitoriaNeighbourhoods
FROM dbo.IJSN_Neighbourhood_Import
WHERE municipio COLLATE Latin1_General_100_CI_AI = N'Vitória';
GO


/* =========================================================
   5. SAMPLE VITORIA RECORDS
   ========================================================= */

SELECT TOP 20
    nome,
    municipio,
    geocMun,
    areaM2,
    macroEstad,
    microEstad,
    anoReferen
FROM dbo.IJSN_Neighbourhood_Import
WHERE municipio COLLATE Latin1_General_100_CI_AI = N'Vitória'
ORDER BY nome;
GO