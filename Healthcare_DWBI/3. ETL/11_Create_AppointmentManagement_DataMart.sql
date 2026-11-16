USE Healthcare_DW;
GO

/* =========================================================
   APPOINTMENT MANAGEMENT DATA MART

   Purpose:
   Provides a department-focused analytical view for
   healthcare appointment management and no-show analysis.

   Source:
   Enterprise Healthcare Data Warehouse
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_AppointmentManagement_DataMart
AS

SELECT
    f.AppointmentID,

    /* Date */
    d.YearNumber,
    d.QuarterName,
    d.MonthNumber,
    d.MonthName,
    d.FullDate AS AppointmentDate,

    /* Patient */
    p.Gender,
    p.Age,
    p.AgeGroup,

    /* Location */
    l.Neighbourhood,
    l.Municipality,
    l.MacroRegion,
    l.MicroRegion,

    /* Health Profile */
    h.Scholarship,
    h.Hypertension,
    h.Diabetes,
    h.Alcoholism,
    h.Handicap,

    /* Appointment Measures */
    f.AppointmentCount,
    f.AttendedCount,
    f.NoShowCount,
    f.SMSReceived,
    f.WaitingDays

FROM dbo.FactAppointment f

INNER JOIN dbo.DimDate d
    ON f.AppointmentDateKey = d.DateKey

LEFT JOIN dbo.DimPatient p
    ON f.PatientKey = p.PatientKey

INNER JOIN dbo.DimLocation l
    ON f.LocationKey = l.LocationKey

INNER JOIN dbo.DimHealthProfile h
    ON f.HealthProfileKey = h.HealthProfileKey;
GO


/* =========================================================
   DATA MART VALIDATION
   ========================================================= */

SELECT COUNT(*) AS DataMartRows
FROM dbo.vw_AppointmentManagement_DataMart;
GO

SELECT TOP 20 *
FROM dbo.vw_AppointmentManagement_DataMart
ORDER BY AppointmentDate, AppointmentID;
GO