USE Healthcare_DW;
GO

/* =========================================================
   SOURCE DATA PROFILING
   ========================================================= */

-- Appointment source row count
SELECT COUNT(*) AS TotalAppointments
FROM stg.Appointments;

-- Missing Patient IDs
SELECT COUNT(*) AS MissingPatientIDs
FROM stg.Appointments
WHERE PatientId IS NULL;

-- Invalid dates
SELECT
    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, ScheduledDay, 127) IS NULL
        THEN 1 ELSE 0 END) AS InvalidScheduledDates,

    SUM(CASE
        WHEN TRY_CONVERT(DATETIME2, AppointmentDay, 127) IS NULL
        THEN 1 ELSE 0 END) AS InvalidAppointmentDates
FROM stg.Appointments;

-- Excel source profiling
SELECT
    COUNT(*) AS ExcelRows,
    COUNT(DISTINCT nome) AS UniqueNeighbourhoods,
    COUNT(DISTINCT municipio) AS UniqueMunicipalities
FROM dbo.IJSN_Neighbourhood_Import;

-- JSON source profiling
SELECT
    COUNT(*) AS TotalFacilities,
    SUM(CASE WHEN FacilityName IS NULL THEN 1 ELSE 0 END)
        AS MissingFacilityName,
    SUM(CASE WHEN Neighbourhood IS NULL THEN 1 ELSE 0 END)
        AS MissingNeighbourhood,
    SUM(CASE WHEN FacilityType IS NULL THEN 1 ELSE 0 END)
        AS MissingFacilityType,
    SUM(CASE WHEN CNES IS NULL THEN 1 ELSE 0 END)
        AS MissingCNES,
    COUNT(DISTINCT CNES) AS UniqueCNES
FROM dbo.HealthFacility_Import;
GO