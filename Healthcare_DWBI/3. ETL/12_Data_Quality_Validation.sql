USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE APPOINTMENT ANALYTICS
   FINAL DATA QUALITY VALIDATION

   Purpose:
   Validate warehouse row counts, referential integrity,
   duplicate appointments, waiting-day quality, attendance
   measures, unknown members, and Data Mart consistency.
   ========================================================= */


/* =========================================================
   1. WAREHOUSE AND SOURCE ROW COUNTS
   ========================================================= */

SELECT 'FactAppointment' AS TableName, COUNT(*) AS TotalRows
FROM dbo.FactAppointment

UNION ALL

SELECT 'DimPatient', COUNT(*)
FROM dbo.DimPatient

UNION ALL

SELECT 'DimLocation', COUNT(*)
FROM dbo.DimLocation

UNION ALL

SELECT 'DimHealthProfile', COUNT(*)
FROM dbo.DimHealthProfile

UNION ALL

SELECT 'DimDate', COUNT(*)
FROM dbo.DimDate

UNION ALL

SELECT 'DimSMSReceived', COUNT(*)
FROM dbo.DimSMSReceived

UNION ALL

SELECT 'DimHealthFacility', COUNT(*)
FROM dbo.DimHealthFacility

UNION ALL

SELECT 'IJSN_Neighbourhood_Import', COUNT(*)
FROM dbo.IJSN_Neighbourhood_Import

UNION ALL

SELECT 'HealthFacility_Import', COUNT(*)
FROM dbo.HealthFacility_Import;
GO


/* =========================================================
   2. DATA MART ROW COUNT
   FactAppointment and Data Mart should both contain
   110,526 appointment records.
   ========================================================= */

SELECT
    (SELECT COUNT(*)
     FROM dbo.FactAppointment) AS FactAppointmentRows,

    (SELECT COUNT(*)
     FROM dbo.vw_AppointmentManagement_DataMart) AS DataMartRows;
GO


/* =========================================================
   3. FACT -> LOCATION REFERENTIAL INTEGRITY
   Expected result: 0
   ========================================================= */

SELECT
    COUNT(*) AS InvalidFactLocationReferences
FROM dbo.FactAppointment f
LEFT JOIN dbo.DimLocation l
    ON f.LocationKey = l.LocationKey
WHERE l.LocationKey IS NULL;
GO


/* =========================================================
   4. FACILITY -> LOCATION REFERENTIAL INTEGRITY
   Expected result: 0
   ========================================================= */

SELECT
    COUNT(*) AS InvalidFacilityLocationReferences
FROM dbo.DimHealthFacility h
LEFT JOIN dbo.DimLocation l
    ON h.LocationKey = l.LocationKey
WHERE l.LocationKey IS NULL;
GO


/* =========================================================
   5. COMPLETE FACT DIMENSION REFERENTIAL INTEGRITY
   Expected values: all 0
   ========================================================= */

SELECT
    SUM(CASE WHEN p.PatientKey IS NULL
        THEN 1 ELSE 0 END) AS InvalidPatientReferences,

    SUM(CASE WHEN l.LocationKey IS NULL
        THEN 1 ELSE 0 END) AS InvalidLocationReferences,

    SUM(CASE WHEN h.HealthProfileKey IS NULL
        THEN 1 ELSE 0 END) AS InvalidHealthProfileReferences,

    SUM(CASE WHEN sd.DateKey IS NULL
        THEN 1 ELSE 0 END) AS InvalidScheduledDateReferences,

    SUM(CASE WHEN ad.DateKey IS NULL
        THEN 1 ELSE 0 END) AS InvalidAppointmentDateReferences

FROM dbo.FactAppointment f

LEFT JOIN dbo.DimPatient p
    ON f.PatientKey = p.PatientKey

LEFT JOIN dbo.DimLocation l
    ON f.LocationKey = l.LocationKey

LEFT JOIN dbo.DimHealthProfile h
    ON f.HealthProfileKey = h.HealthProfileKey

LEFT JOIN dbo.DimDate sd
    ON f.ScheduledDateKey = sd.DateKey

LEFT JOIN dbo.DimDate ad
    ON f.AppointmentDateKey = ad.DateKey;
GO


/* =========================================================
   6. DUPLICATE APPOINTMENT VALIDATION
   Expected result: no rows
   ========================================================= */

SELECT
    AppointmentID,
    COUNT(*) AS DuplicateCount
FROM dbo.FactAppointment
GROUP BY AppointmentID
HAVING COUNT(*) > 1;
GO


/* =========================================================
   7. UNIQUE APPOINTMENT ID CONSTRAINT VALIDATION
   ========================================================= */

SELECT
    kc.name AS ConstraintName,
    kc.type_desc AS ConstraintType
FROM sys.key_constraints kc
WHERE kc.parent_object_id =
      OBJECT_ID('dbo.FactAppointment')
  AND kc.name =
      'UQ_FactAppointment_AppointmentID';
GO


/* =========================================================
   8. WAITING DAYS DATA QUALITY

   Five source appointments produced negative waiting-day
   values. The appointments are retained, but WaitingDays
   is stored as NULL.

   Expected:
   NegativeWaitingDayRecords = 0
   NullWaitingDayRecords     = 5
   ========================================================= */

SELECT
    SUM(
        CASE
            WHEN WaitingDays < 0 THEN 1
            ELSE 0
        END
    ) AS NegativeWaitingDayRecords,

    SUM(
        CASE
            WHEN WaitingDays IS NULL THEN 1
            ELSE 0
        END
    ) AS NullWaitingDayRecords
FROM dbo.FactAppointment;
GO


/* =========================================================
   9. UNKNOWN PATIENT VALIDATION

   PatientKey = 0 represents the Unknown Patient member.
   ========================================================= */

SELECT
    COUNT(*) AS UnknownPatientAppointments
FROM dbo.FactAppointment
WHERE PatientKey = 0;
GO


/* =========================================================
   10. ATTENDANCE MEASURE VALIDATION

   Expected:
   AppointmentCount = 110526
   AttendedCount    = 88207
   NoShowCount      = 22319
   NoShowRate       = 20.19%
   ========================================================= */

SELECT
    SUM(AppointmentCount) AS AppointmentCount,
    SUM(AttendedCount) AS AttendedCount,
    SUM(NoShowCount) AS NoShowCount,

    CAST(
        100.0 * SUM(NoShowCount)
        / NULLIF(SUM(AppointmentCount), 0)
        AS DECIMAL(6,2)
    ) AS NoShowRatePercentage
FROM dbo.FactAppointment;
GO


/* =========================================================
   11. SMS RECEIVED VALIDATION

   The two categories should together equal the total
   number of fact appointment records.
   ========================================================= */

SELECT
    SMSReceived,
    COUNT(*) AS AppointmentRows
FROM dbo.FactAppointment
GROUP BY SMSReceived
ORDER BY SMSReceived;
GO


/* =========================================================
   12. FACILITY SOURCE / DIMENSION VALIDATION
   ========================================================= */

SELECT
    (SELECT COUNT(*)
     FROM dbo.HealthFacility_Import)
        AS ImportedFacilityRows,

    (SELECT COUNT(*)
     FROM dbo.DimHealthFacility)
        AS FacilityDimensionRows,

    (SELECT COUNT(*)
     FROM dbo.DimHealthFacility h
     LEFT JOIN dbo.DimLocation l
        ON h.LocationKey = l.LocationKey
     WHERE l.LocationKey IS NULL)
        AS UnmatchedFacilityLocations;
GO


/* =========================================================
   13. IJSN LOCATION ENRICHMENT VALIDATION
   ========================================================= */

SELECT
    COUNT(*) AS TotalLocations,

    SUM(
        CASE
            WHEN Municipality IS NOT NULL THEN 1
            ELSE 0
        END
    ) AS EnrichedLocations,

    SUM(
        CASE
            WHEN Municipality IS NULL THEN 1
            ELSE 0
        END
    ) AS UnmatchedLocations

FROM dbo.DimLocation;
GO


/* =========================================================
   14. FINAL WAREHOUSE SUMMARY
   ========================================================= */

SELECT
    (SELECT COUNT(*)
     FROM dbo.FactAppointment)
        AS FactAppointments,

    (SELECT COUNT(*)
     FROM dbo.DimPatient)
        AS Patients,

    (SELECT COUNT(*)
     FROM dbo.DimLocation)
        AS Locations,

    (SELECT COUNT(*)
     FROM dbo.DimHealthProfile)
        AS HealthProfiles,

    (SELECT COUNT(*)
     FROM dbo.DimDate)
        AS Dates,

    (SELECT COUNT(*)
     FROM dbo.DimSMSReceived)
        AS SMSCategories,

    (SELECT COUNT(*)
     FROM dbo.DimHealthFacility)
        AS Facilities,

    (SELECT COUNT(*)
     FROM dbo.vw_AppointmentManagement_DataMart)
        AS DataMartRows;
GO