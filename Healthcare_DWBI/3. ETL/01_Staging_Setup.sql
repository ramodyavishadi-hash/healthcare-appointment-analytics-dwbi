USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI - STAGING LAYER
   Sources:
   1. CSV  - Kaggle Medical Appointment No Shows
   2. XLSX - IJSN Neighbourhood Reference Data
   3. JSON - Vitoria Healthcare Facilities
   ========================================================= */

-- Validate CSV staging source
SELECT COUNT(*) AS AppointmentStagingRows
FROM stg.Appointments;

-- Validate Excel import
SELECT COUNT(*) AS IJSNExcelRows
FROM dbo.IJSN_Neighbourhood_Import;

-- Validate JSON staging
SELECT COUNT(*) AS JSONFacilityRows
FROM dbo.HealthFacility_Import;
GO