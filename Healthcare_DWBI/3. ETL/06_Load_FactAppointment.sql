USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE APPOINTMENT ANALYTICS
   LOAD FACT APPOINTMENT

   Grain:
   One row represents one healthcare appointment.

   Data-quality rules:
   1. Records with Age < 0 are rejected.
   2. Invalid PatientId values use the Unknown Patient member.
   3. Negative WaitingDays values are retained as appointments
      but WaitingDays is stored as NULL.
   4. Full-refresh logic prevents duplicate fact records.
   ========================================================= */


/* =========================================================
   1. CLEAR EXISTING FACT DATA
   ========================================================= */

DELETE FROM dbo.FactAppointment;
GO

DBCC CHECKIDENT ('dbo.FactAppointment', RESEED, 0);
GO


/* =========================================================
   2. LOAD FACT APPOINTMENT
   ========================================================= */

INSERT INTO dbo.FactAppointment
(
    AppointmentID,
    PatientKey,
    LocationKey,
    HealthProfileKey,
    ScheduledDateKey,
    AppointmentDateKey,
    AppointmentCount,
    NoShowCount,
    AttendedCount,
    SMSReceived,
    WaitingDays
)
SELECT
    TRY_CONVERT(BIGINT, a.AppointmentID),

    COALESCE(p.PatientKey, 0),

    l.LocationKey,

    h.HealthProfileKey,

    TRY_CONVERT(
        INT,
        CONVERT(
            CHAR(8),
            CAST(
                TRY_CONVERT(DATETIME2, a.ScheduledDay, 127)
                AS DATE
            ),
            112
        )
    ) AS ScheduledDateKey,

    TRY_CONVERT(
        INT,
        CONVERT(
            CHAR(8),
            CAST(
                TRY_CONVERT(DATETIME2, a.AppointmentDay, 127)
                AS DATE
            ),
            112
        )
    ) AS AppointmentDateKey,

    1 AS AppointmentCount,

    CASE
        WHEN UPPER(LTRIM(RTRIM(a.NoShow))) = 'YES'
            THEN 1
        ELSE 0
    END AS NoShowCount,

    CASE
        WHEN UPPER(LTRIM(RTRIM(a.NoShow))) = 'NO'
            THEN 1
        ELSE 0
    END AS AttendedCount,

    TRY_CONVERT(INT, a.SMS_received) AS SMSReceived,

    CASE
        WHEN DATEDIFF
        (
            DAY,
            CAST(
                TRY_CONVERT(DATETIME2, a.ScheduledDay, 127)
                AS DATE
            ),
            CAST(
                TRY_CONVERT(DATETIME2, a.AppointmentDay, 127)
                AS DATE
            )
        ) < 0
        THEN NULL

        ELSE DATEDIFF
        (
            DAY,
            CAST(
                TRY_CONVERT(DATETIME2, a.ScheduledDay, 127)
                AS DATE
            ),
            CAST(
                TRY_CONVERT(DATETIME2, a.AppointmentDay, 127)
                AS DATE
            )
        )
    END AS WaitingDays

FROM stg.Appointments a

LEFT JOIN dbo.DimPatient p
    ON TRY_CONVERT(DECIMAL(18,0), a.PatientId) = p.PatientId
    AND a.Gender = p.Gender
    AND a.Age = p.Age

INNER JOIN dbo.DimLocation l
    ON UPPER(LTRIM(RTRIM(a.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI
       =
       UPPER(LTRIM(RTRIM(l.Neighbourhood)))
       COLLATE Latin1_General_100_CI_AI

INNER JOIN dbo.DimHealthProfile h
    ON a.Scholarship = h.Scholarship
    AND a.Hipertension = h.Hypertension
    AND a.Diabetes = h.Diabetes
    AND a.Alcoholism = h.Alcoholism
    AND a.Handcap = h.Handicap

WHERE a.Age >= 0
  AND TRY_CONVERT(BIGINT, a.AppointmentID) IS NOT NULL;
GO


/* =========================================================
   3. FACT ROW COUNT VALIDATION
   Expected:
   SourceRows = 110527
   InvalidAgeRows = 1
   FactRows = 110526
   ========================================================= */

SELECT
    (SELECT COUNT(*)
     FROM stg.Appointments) AS SourceRows,

    (SELECT COUNT(*)
     FROM stg.Appointments
     WHERE Age < 0) AS RejectedInvalidAgeRows,

    (SELECT COUNT(*)
     FROM dbo.FactAppointment) AS FactRows;
GO


/* =========================================================
   4. ATTENDANCE VALIDATION
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
   5. WAITING DAYS QUALITY VALIDATION

   Expected:
   NegativeWaitingDays = 0

   Five source records have negative calculated waiting days.
   They remain in the fact table but WaitingDays is stored NULL.
   ========================================================= */

SELECT
    SUM(
        CASE
            WHEN WaitingDays < 0 THEN 1
            ELSE 0
        END
    ) AS NegativeWaitingDays,

    SUM(
        CASE
            WHEN WaitingDays IS NULL THEN 1
            ELSE 0
        END
    ) AS NullWaitingDays
FROM dbo.FactAppointment;
GO


/* =========================================================
   6. DUPLICATE APPOINTMENT VALIDATION

   Expected:
   0 rows returned
   ========================================================= */

SELECT
    AppointmentID,
    COUNT(*) AS DuplicateCount
FROM dbo.FactAppointment
GROUP BY AppointmentID
HAVING COUNT(*) > 1;
GO


/* =========================================================
   7. FOREIGN KEY / DIMENSION VALIDATION
   ========================================================= */

SELECT
    SUM(CASE WHEN p.PatientKey IS NULL THEN 1 ELSE 0 END)
        AS InvalidPatientReferences,

    SUM(CASE WHEN l.LocationKey IS NULL THEN 1 ELSE 0 END)
        AS InvalidLocationReferences,

    SUM(CASE WHEN h.HealthProfileKey IS NULL THEN 1 ELSE 0 END)
        AS InvalidHealthProfileReferences,

    SUM(CASE WHEN sd.DateKey IS NULL THEN 1 ELSE 0 END)
        AS InvalidScheduledDateReferences,

    SUM(CASE WHEN ad.DateKey IS NULL THEN 1 ELSE 0 END)
        AS InvalidAppointmentDateReferences

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
   8. SMS VALIDATION
   ========================================================= */

SELECT
    SMSReceived,
    COUNT(*) AS AppointmentRows
FROM dbo.FactAppointment
GROUP BY SMSReceived
ORDER BY SMSReceived;
GO