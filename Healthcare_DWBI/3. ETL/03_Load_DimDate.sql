USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI
   LOAD DATE DIMENSION

   Purpose:
   Populate DimDate with the complete date range required
   by the healthcare appointment dataset.

   Date Range:
   2015-11-01 to 2016-06-30

   Expected Rows:
   243
   ========================================================= */


------------------------------------------------------------
-- 1. CLEAR EXISTING DATE DIMENSION
------------------------------------------------------------

DELETE FROM dbo.DimDate;
GO


------------------------------------------------------------
-- 2. DEFINE DATE RANGE
------------------------------------------------------------

DECLARE @CurrentDate DATE = '2015-11-01';
DECLARE @EndDate     DATE = '2016-06-30';


------------------------------------------------------------
-- 3. POPULATE DIMDATE
------------------------------------------------------------

WHILE @CurrentDate <= @EndDate
BEGIN

    INSERT INTO dbo.DimDate
    (
        DateKey,
        FullDate,
        DayNumber,
        DayName,
        MonthNumber,
        MonthName,
        QuarterNumber,
        QuarterName,
        YearNumber
    )
    VALUES
    (
        CONVERT(INT, CONVERT(CHAR(8), @CurrentDate, 112)),

        @CurrentDate,

        DAY(@CurrentDate),

        DATENAME(WEEKDAY, @CurrentDate),

        MONTH(@CurrentDate),

        DATENAME(MONTH, @CurrentDate),

        DATEPART(QUARTER, @CurrentDate),

        CONCAT('Q', DATEPART(QUARTER, @CurrentDate)),

        YEAR(@CurrentDate)
    );

    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);

END;
GO


------------------------------------------------------------
-- 4. VALIDATE DIMDATE
------------------------------------------------------------

SELECT
    COUNT(*) AS DimDateRows,
    MIN(FullDate) AS FirstDate,
    MAX(FullDate) AS LastDate
FROM dbo.DimDate;
GO


------------------------------------------------------------
-- 5. SAMPLE DATE RECORDS
------------------------------------------------------------

SELECT TOP 20
    DateKey,
    FullDate,
    DayNumber,
    DayName,
    MonthNumber,
    MonthName,
    QuarterNumber,
    QuarterName,
    YearNumber
FROM dbo.DimDate
ORDER BY FullDate;
GO