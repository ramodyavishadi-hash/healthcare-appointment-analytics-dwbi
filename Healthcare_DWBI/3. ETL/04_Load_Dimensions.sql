USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI
   DIMENSION LOAD LOGIC

   ETL Rules:
   - PatientId is stored as NVARCHAR in staging to preserve
     the original CSV representation.
   - PatientId is explicitly converted during transformation.
   - Records with Age < 0 are excluded from patient loading.
   - Age groups are standardised across the DWBI solution.
   ========================================================= */


------------------------------------------------------------
-- 1. LOAD PATIENT DIMENSION
------------------------------------------------------------

INSERT INTO dbo.DimPatient
(
    PatientId,
    Gender,
    Age,
    AgeGroup
)
SELECT DISTINCT
    TRY_CONVERT(FLOAT, a.PatientId) AS PatientId,
    a.Gender,
    a.Age,

    CASE
        WHEN a.Age < 13 THEN 'Child'
        WHEN a.Age BETWEEN 13 AND 19 THEN 'Teenager'
        WHEN a.Age BETWEEN 20 AND 39 THEN 'Young Adult'
        WHEN a.Age BETWEEN 40 AND 59 THEN 'Middle Aged'
        ELSE 'Senior'
    END AS AgeGroup

FROM stg.Appointments a

WHERE a.PatientId IS NOT NULL

    -- Ensure PatientId can be converted from raw staging text
    AND TRY_CONVERT(FLOAT, a.PatientId) IS NOT NULL

    -- Data-quality rule:
    -- Reject the single source record containing Age = -1
    AND a.Age >= 0;
GO


------------------------------------------------------------
-- 2. CREATE UNKNOWN PATIENT MEMBER
------------------------------------------------------------

/*
   PatientKey = 0 is used as the Unknown member when an
   appointment cannot be matched to a valid patient record.
*/

IF NOT EXISTS
(
    SELECT 1
    FROM dbo.DimPatient
    WHERE PatientKey = 0
)
BEGIN

    SET IDENTITY_INSERT dbo.DimPatient ON;

    INSERT INTO dbo.DimPatient
    (
        PatientKey,
        PatientId,
        Gender,
        Age,
        AgeGroup
    )
    VALUES
    (
        0,
        0,
        'Unknown',
        0,
        'Unknown'
    );

    SET IDENTITY_INSERT dbo.DimPatient OFF;

END;
GO


------------------------------------------------------------
-- 3. LOAD LOCATION DIMENSION
------------------------------------------------------------

INSERT INTO dbo.DimLocation
(
    Neighbourhood
)
SELECT DISTINCT
    LTRIM(RTRIM(a.Neighbourhood))
FROM stg.Appointments a
WHERE a.Neighbourhood IS NOT NULL
  AND LTRIM(RTRIM(a.Neighbourhood)) <> '';
GO


------------------------------------------------------------
-- 4. LOAD HEALTH PROFILE DIMENSION
------------------------------------------------------------

INSERT INTO dbo.DimHealthProfile
(
    Scholarship,
    Hypertension,
    Diabetes,
    Alcoholism,
    Handicap
)
SELECT DISTINCT
    a.Scholarship,
    a.Hipertension,
    a.Diabetes,
    a.Alcoholism,
    a.Handcap
FROM stg.Appointments a;
GO


------------------------------------------------------------
-- 5. DIMENSION LOAD VALIDATION
------------------------------------------------------------

SELECT
    (SELECT COUNT(*)
     FROM dbo.DimPatient) AS PatientDimensionRows,

    (SELECT COUNT(*)
     FROM dbo.DimLocation) AS LocationDimensionRows,

    (SELECT COUNT(*)
     FROM dbo.DimHealthProfile) AS HealthProfileDimensionRows;
GO


------------------------------------------------------------
-- 6. VALIDATE INVALID AGE CLEANSING
------------------------------------------------------------

SELECT COUNT(*) AS InvalidAgeSourceRecords
FROM stg.Appointments
WHERE Age < 0;
GO


------------------------------------------------------------
-- 7. VALIDATE PATIENT ID CONVERSION
------------------------------------------------------------

SELECT COUNT(*) AS InvalidPatientIdConversions
FROM stg.Appointments
WHERE PatientId IS NOT NULL
  AND TRY_CONVERT(FLOAT, PatientId) IS NULL;
GO