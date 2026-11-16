USE [Healthcare_DW]
GO

/****** Object:  Table [dbo].[DimDate]    Script Date: 10/1/2026 11:07:17 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimDate](
	[DateKey] [int] NOT NULL,
	[FullDate] [date] NOT NULL,
	[DayNumber] [tinyint] NOT NULL,
	[DayName] [varchar](20) NOT NULL,
	[MonthNumber] [tinyint] NOT NULL,
	[MonthName] [varchar](20) NOT NULL,
	[QuarterNumber] [tinyint] NOT NULL,
	[QuarterName] [varchar](10) NOT NULL,
	[YearNumber] [smallint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DateKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[FullDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO










USE [Healthcare_DW]
GO

/****** Object:  Table [dbo].[DimPatient]    Script Date: 10/1/2026 11:07:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimPatient](
	[PatientKey] [int] IDENTITY(1,1) NOT NULL,
	[PatientId] [decimal](18, 0) NOT NULL,
	[Gender] [varchar](10) NULL,
	[Age] [int] NULL,
	[AgeGroup] [varchar](30) NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO






USE [Healthcare_DW]
GO

/****** Object:  Table [dbo].[DimLocation]    Script Date: 10/1/2026 11:08:18 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimLocation](
	[LocationKey] [int] IDENTITY(1,1) NOT NULL,
	[Neighbourhood] [nvarchar](150) NOT NULL,
	[Municipality] [nvarchar](255) NULL,
	[MunicipalityCode] [int] NULL,
	[AreaM2] [float] NULL,
	[MacroRegion] [nvarchar](255) NULL,
	[MicroRegion] [nvarchar](255) NULL,
	[IJSNReferenceYear] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[LocationKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO





USE [Healthcare_DW]
GO

/****** Object:  Table [dbo].[DimHealthProfile]    Script Date: 10/1/2026 11:08:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DimHealthProfile](
	[HealthProfileKey] [int] IDENTITY(1,1) NOT NULL,
	[Scholarship] [int] NOT NULL,
	[Hypertension] [int] NOT NULL,
	[Diabetes] [int] NOT NULL,
	[Alcoholism] [int] NOT NULL,
	[Handicap] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[HealthProfileKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

------------------------------------------------------------
-- DIM SMS RECEIVED
------------------------------------------------------------

IF OBJECT_ID('dbo.DimSMSReceived', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimSMSReceived
    (
        SMSReceivedKey INT NOT NULL,
        SMSReceivedLabel VARCHAR(50) NULL,

        CONSTRAINT PK_DimSMSReceived
            PRIMARY KEY (SMSReceivedKey)
    );
END;
GO

------------------------------------------------------------
-- DIM HEALTH FACILITY
------------------------------------------------------------

IF OBJECT_ID('dbo.DimHealthFacility', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimHealthFacility
    (
        FacilityKey INT IDENTITY(1,1) NOT NULL,
        FacilityName NVARCHAR(200) NOT NULL,
        FacilityType NVARCHAR(200) NULL,
        Nature NVARCHAR(100) NULL,
        CNES INT NULL,
        LocationKey INT NOT NULL,

        CONSTRAINT PK_DimHealthFacility
            PRIMARY KEY (FacilityKey),

        CONSTRAINT FK_DimHealthFacility_DimLocation
            FOREIGN KEY (LocationKey)
            REFERENCES dbo.DimLocation(LocationKey)
    );
END;
GO