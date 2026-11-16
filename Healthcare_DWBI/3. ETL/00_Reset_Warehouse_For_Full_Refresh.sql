USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI
   FULL REFRESH RESET

   Purpose:
   Clear previously loaded warehouse data before executing
   the ETL again.

   Fact tables are cleared before dimensions to preserve
   referential integrity.

   Raw staging/import tables are NOT deleted because they
   contain the extracted source data.
   ========================================================= */


------------------------------------------------------------
-- 1. CLEAR FACT TABLE FIRST
------------------------------------------------------------

DELETE FROM dbo.FactAppointment;
GO


------------------------------------------------------------
-- 2. CLEAR HEALTH FACILITY DIMENSION IF IT EXISTS
------------------------------------------------------------

IF OBJECT_ID('dbo.DimHealthFacility', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.DimHealthFacility;
END;
GO


------------------------------------------------------------
-- 3. CLEAR PATIENT DIMENSION
------------------------------------------------------------

DELETE FROM dbo.DimPatient;
GO


------------------------------------------------------------
-- 4. CLEAR HEALTH PROFILE DIMENSION
------------------------------------------------------------

DELETE FROM dbo.DimHealthProfile;
GO


------------------------------------------------------------
-- 5. CLEAR LOCATION DIMENSION
------------------------------------------------------------

DELETE FROM dbo.DimLocation;
GO


------------------------------------------------------------
-- 6. CLEAR SMS DIMENSION IF IT EXISTS
------------------------------------------------------------

IF OBJECT_ID('dbo.DimSMSReceived', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.DimSMSReceived;
END;
GO


------------------------------------------------------------
-- 7. RESET IDENTITY VALUES
------------------------------------------------------------

DBCC CHECKIDENT ('dbo.FactAppointment', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimPatient', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimLocation', RESEED, 0);
DBCC CHECKIDENT ('dbo.DimHealthProfile', RESEED, 0);
GO

IF OBJECT_ID('dbo.DimHealthFacility', 'U') IS NOT NULL
BEGIN
    DBCC CHECKIDENT ('dbo.DimHealthFacility', RESEED, 0);
END;
GO


------------------------------------------------------------
-- 8. VALIDATE RESET
------------------------------------------------------------

SELECT
    (SELECT COUNT(*) FROM dbo.FactAppointment)
        AS FactAppointmentRows,

    (SELECT COUNT(*) FROM dbo.DimPatient)
        AS PatientRows,

    (SELECT COUNT(*) FROM dbo.DimLocation)
        AS LocationRows,

    (SELECT COUNT(*) FROM dbo.DimHealthProfile)
        AS HealthProfileRows;
GO