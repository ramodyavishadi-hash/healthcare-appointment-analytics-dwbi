USE Healthcare_DW;
GO

/* 
   HEALTHCARE DWBI
   STAGING / IMPORT TABLE CREATION

   Source 1: Kaggle Medical Appointment No Shows CSV
   Source 2: IJSN Neighbourhood Reference Excel
   Source 3: Vitoria Healthcare Facilities JSON
*/

-- 1. Create staging schema if it does not already exist


IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'stg'
)
BEGIN
    EXEC('CREATE SCHEMA stg');
END;
GO



-- 2. Appointment CSV staging table


DROP TABLE IF EXISTS stg.Appointments;
GO

CREATE TABLE stg.Appointments
(
    PatientId       NVARCHAR(50) NULL,
    AppointmentID   BIGINT NULL,
    Gender          NVARCHAR(10) NULL,
    ScheduledDay    NVARCHAR(50) NULL,
    AppointmentDay  NVARCHAR(50) NULL,
    Age             INT NULL,
    Neighbourhood   NVARCHAR(150) NULL,
    Scholarship     INT NULL,
    Hipertension    INT NULL,
    Diabetes        INT NULL,
    Alcoholism      INT NULL,
    Handcap         INT NULL,
    SMS_received    INT NULL,
    NoShow          NVARCHAR(20) NULL
);
GO



-- 3. IJSN Excel import table


DROP TABLE IF EXISTS dbo.IJSN_Neighbourhood_Import;
GO

CREATE TABLE dbo.IJSN_Neighbourhood_Import
(
    nome        NVARCHAR(255) NULL,
    municipio   NVARCHAR(255) NULL,
    geocMun     NVARCHAR(50) NULL,
    areaM2      FLOAT NULL,
    macroEstad  NVARCHAR(255) NULL,
    microEstad  NVARCHAR(255) NULL,
    anoReferen  NVARCHAR(50) NULL
);
GO



-- 4. Healthcare facility JSON import table

DROP TABLE IF EXISTS dbo.HealthFacility_Import;
GO

CREATE TABLE dbo.HealthFacility_Import
(
    FacilityName       NVARCHAR(200) NULL,
    Neighbourhood      NVARCHAR(150) NULL,
    FacilityType       NVARCHAR(150) NULL,
    Nature             NVARCHAR(100) NULL,
    NeighbourhoodCode  INT NULL,
    CNES               INT NULL
);
GO



-- 5. Verify table creation


SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
WHERE
       (s.name = 'stg' AND t.name = 'Appointments')
    OR (s.name = 'dbo' AND t.name = 'IJSN_Neighbourhood_Import')
    OR (s.name = 'dbo' AND t.name = 'HealthFacility_Import')
ORDER BY SchemaName, TableName;
GO