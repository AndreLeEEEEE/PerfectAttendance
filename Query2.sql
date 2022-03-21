--"attendance_records" query -
--Find all late days and all missing hours
--for every employee
--from 1/1/2022 to today.
--Work-in-Progress

SELECT
TT.Badge_No,
TT.Full_Name,
TT.Employee_Status,
TT.Description,
TT.Date,
TT.Scheduled_In_Time,
TT.Scheduled_Out_Time,
--Remove overtime hours
DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time) as Adjusted_Scheduled_Out_Time,
TT.Actual_In_Time,
TT.Actual_Out_Time,
TT.Scheduled_OT / 60.0 as Overtime,
TT.Absent,
CASE
  WHEN DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) > 480.00 THEN
    ROUND((DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) - 30.0) / 60.0, 2) - TT.Regular_Hours
  ELSE
    ROUND(DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) / 60.0, 2) - TT.Regular_Hours
END as Missing_Hours,
TT.Late,
CASE
  WHEN DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) > 480.00 THEN
    ROUND((DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) - 30.0) / 60.0, 2)
  ELSE
    ROUND(DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) / 60.0, 2)
END as Scheduled_Hours,
TT.Regular_Hours as Actual_Hours,
TT.Note
FROM (
	SELECT
    EMP.Badge_No,
    PU.First_Name + ' ' + PU.Last_Name AS 'Full_Name',
    EMP.Employee_Status,
    CT.Description,
    CAST(Clockin.Scheduled_In_Time as DATE) as Date,
    CT.Absent,
    --Amount of hours to subtract from Scheduled_Out_Time to yield exactly 8 scheduled hours and 30 minutes for lunch if applicable
    --Negative number
    CASE
      --If larger than 8.5 hours
      WHEN ABS(DATEDIFF(MI, Clockin.Scheduled_In_Time, Clockin.Scheduled_Out_Time)) > 510.00 THEN
        DATEDIFF(MI, Clockin.Scheduled_Out_Time, Clockin.Scheduled_In_Time) + 510.00
      ELSE
        0.00
    END as Scheduled_OT,
    
    --Convert from Eastern time to Mountain time
    DATEADD(HOUR, -2, Clockin.Scheduled_In_Time) as Scheduled_In_Time,
    DATEADD(HOUR, -2, Clockin.Scheduled_Out_Time) as Scheduled_Out_Time,
    DATEADD(HOUR, -2, Clockin.System_Clockin_Time) as Actual_In_Time,
    DATEADD(HOUR, -2, Clockin.System_Clockout_Time) as Actual_Out_Time,
    Clockin.Note,
    CASE
      WHEN ISNULL(DATEDIFF(MI,  Clockin.Scheduled_In_Time, Clockin.System_Clockin_Time), 0) <= 0 THEN 0
      ELSE DATEDIFF(MI,  Clockin.Scheduled_In_Time, Clockin.System_Clockin_Time)
    END AS 'Late_Minutes',
    CASE
      WHEN ISNULL(DATEDIFF(MI, Clockin.System_Clockout_Time, Clockin.Scheduled_Out_Time), 0) <= 0 THEN 0
      ELSE DATEDIFF(MI, Clockin.System_Clockout_Time, Clockin.Scheduled_Out_Time)
    END AS 'Left_Early_Minutes', -- Need to fix
    Clockin.Late,
    Clockin.Regular_Hours,
    Clockin.Shift_Hours
  
	FROM Personnel_v_Clockin Clockin
	JOIN Personnel_v_Employee EMP
	  ON Clockin.Plexus_User_No = EMP.Plexus_User_No
	JOIN Personnel_v_Clockin_Type CT
	  ON Clockin.Clockin_Type_Key = CT.Clockin_Type_Key
	JOIN Plexus_Control_v_Plexus_User PU
	  ON EMP.Plexus_User_No = PU.Plexus_User_No
	  
	WHERE Clockin.Scheduled_In_Time BETWEEN '2022-01-01' AND GETDATE()
	AND EMP.Badge_No > 0
	AND (CT.Clockin_Type_Key = 393 --Suspended
	OR CT.Clockin_Type_Key = 9722 --Unpaid
	OR CT.Clockin_Type_Key = 386) --Work
	AND Clockin.Regular_Hours <
	CASE WHEN Clockin.Shift_Hours > 8.00 THEN
	  8.00
	ELSE
	  Clockin.Shift_Hours
	END
	AND DATENAME(dw, Clockin.Scheduled_In_Time) <> 'Saturday'
  AND DATENAME(dw, Clockin.Scheduled_In_Time) <> 'Sunday'
) AS TT

--Might need GROUP BY
ORDER BY TT.Badge_No, CAST(DATEADD(HOUR, -2, TT.Scheduled_In_Time) as DATE);