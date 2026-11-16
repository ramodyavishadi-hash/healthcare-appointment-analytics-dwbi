USE Healthcare_DW;
GO

/* =========================================================
   HEALTHCARE DWBI
   LOAD SMS RECEIVED DIMENSION

   0 = No SMS
   1 = SMS Received
   ========================================================= */

------------------------------------------------------------
-- Clear existing records for full refresh
------------------------------------------------------------

DELETE FROM dbo.DimSMSReceived;
GO


------------------------------------------------------------
-- Load SMS categories
------------------------------------------------------------

INSERT INTO dbo.DimSMSReceived
(
    SMSReceivedKey,
    SMSReceivedLabel
)
VALUES
    (0, 'No SMS'),
    (1, 'SMS Received');
GO


------------------------------------------------------------
-- Validate
------------------------------------------------------------

SELECT
    SMSReceivedKey,
    SMSReceivedLabel
FROM dbo.DimSMSReceived
ORDER BY SMSReceivedKey;
GO