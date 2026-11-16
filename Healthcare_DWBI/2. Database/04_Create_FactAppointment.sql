USE [Healthcare_DW];
GO

/* =========================================================
   CREATE FACT APPOINTMENT TABLE

   Grain:
   One row represents one healthcare appointment.

   AppointmentID is unique to prevent duplicate appointment
   records from being loaded into the fact table.
   ========================================================= */

SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO


/* =========================================================
   1. CREATE FACT APPOINTMENT
   ========================================================= */

CREATE TABLE [dbo].[FactAppointment]
(
    [AppointmentKey]      [int] IDENTITY(1,1) NOT NULL,
    [AppointmentID]       [bigint] NOT NULL,
    [PatientKey]          [int] NOT NULL,
    [LocationKey]         [int] NOT NULL,
    [HealthProfileKey]    [int] NOT NULL,
    [ScheduledDateKey]    [int] NOT NULL,
    [AppointmentDateKey]  [int] NOT NULL,
    [AppointmentCount]    [int] NOT NULL,
    [NoShowCount]         [int] NOT NULL,
    [AttendedCount]       [int] NOT NULL,
    [SMSReceived]         [int] NOT NULL,
    [WaitingDays]         [int] NULL,

    CONSTRAINT [PK_FactAppointment]
        PRIMARY KEY CLUSTERED
        (
            [AppointmentKey] ASC
        )
        WITH
        (
            PAD_INDEX = OFF,
            STATISTICS_NORECOMPUTE = OFF,
            IGNORE_DUP_KEY = OFF,
            ALLOW_ROW_LOCKS = ON,
            ALLOW_PAGE_LOCKS = ON,
            OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
        )
        ON [PRIMARY],

    CONSTRAINT [UQ_FactAppointment_AppointmentID]
        UNIQUE ([AppointmentID])

) ON [PRIMARY];
GO


/* =========================================================
   2. DEFAULT CONSTRAINT
   ========================================================= */

ALTER TABLE [dbo].[FactAppointment]
ADD CONSTRAINT [DF_FactAppointment_AppointmentCount]
DEFAULT ((1)) FOR [AppointmentCount];
GO


/* =========================================================
   3. APPOINTMENT DATE FOREIGN KEY
   ========================================================= */

ALTER TABLE [dbo].[FactAppointment]
WITH CHECK ADD CONSTRAINT [FK_FactAppointment_AppointmentDate]
FOREIGN KEY ([AppointmentDateKey])
REFERENCES [dbo].[DimDate] ([DateKey]);
GO

ALTER TABLE [dbo].[FactAppointment]
CHECK CONSTRAINT [FK_FactAppointment_AppointmentDate];
GO


/* =========================================================
   4. HEALTH PROFILE FOREIGN KEY
   ========================================================= */

ALTER TABLE [dbo].[FactAppointment]
WITH CHECK ADD CONSTRAINT [FK_FactAppointment_HealthProfile]
FOREIGN KEY ([HealthProfileKey])
REFERENCES [dbo].[DimHealthProfile] ([HealthProfileKey]);
GO

ALTER TABLE [dbo].[FactAppointment]
CHECK CONSTRAINT [FK_FactAppointment_HealthProfile];
GO


/* =========================================================
   5. LOCATION FOREIGN KEY
   ========================================================= */

ALTER TABLE [dbo].[FactAppointment]
WITH CHECK ADD CONSTRAINT [FK_FactAppointment_Location]
FOREIGN KEY ([LocationKey])
REFERENCES [dbo].[DimLocation] ([LocationKey]);
GO

ALTER TABLE [dbo].[FactAppointment]
CHECK CONSTRAINT [FK_FactAppointment_Location];
GO


/* =========================================================
   6. PATIENT FOREIGN KEY
   ========================================================= */

ALTER TABLE [dbo].[FactAppointment]
WITH CHECK ADD CONSTRAINT [FK_FactAppointment_Patient]
FOREIGN KEY ([PatientKey])
REFERENCES [dbo].[DimPatient] ([PatientKey]);
GO

ALTER TABLE [dbo].[FactAppointment]
CHECK CONSTRAINT [FK_FactAppointment_Patient];
GO


/* =========================================================
   7. SCHEDULED DATE FOREIGN KEY
   ========================================================= */

ALTER TABLE [dbo].[FactAppointment]
WITH CHECK ADD CONSTRAINT [FK_FactAppointment_ScheduledDate]
FOREIGN KEY ([ScheduledDateKey])
REFERENCES [dbo].[DimDate] ([DateKey]);
GO

ALTER TABLE [dbo].[FactAppointment]
CHECK CONSTRAINT [FK_FactAppointment_ScheduledDate];
GO