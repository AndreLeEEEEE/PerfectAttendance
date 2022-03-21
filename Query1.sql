--"No punch recorded" query -
--Finds all entries labeled as Scheduled (with no hours) or Absent-No Call
--These labels are indicators to HR that they need to investigate these days
--to determine what they really were.
--Work-In-Progress

SELECT
TT.Badge_No,
TT.Employee_Name,
TT.Description,
TT.Date,
CASE
  WHEN DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) > 480.00 THEN
    ROUND((DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) - 30.0) / 60.0, 2)
  ELSE
    ROUND(DATEDIFF(MI, TT.Scheduled_In_Time, DATEADD(MI, TT.Scheduled_OT, TT.Scheduled_Out_Time)) / 60.0, 2)
END as Scheduled_Hours,
SUM(TT.Regular_Hours + TT.Overtime_Hours + TT.Doubletime_Hours) AS Worked_Hours

FROM (
  SELECT
  EMP.Badge_No,
  PU.First_Name + ' ' + PU.Last_Name AS 'Employee_Name',
  CT.Description,
  CAST(Clockin.Scheduled_In_Time AS DATE) AS Date,
  Clockin.Regular_Hours,
  Clockin.Overtime_Hours,
  Clockin.Doubletime_Hours,
  --Convert from Eastern time to Mountain time
  DATEADD(HOUR, -2, Clockin.Scheduled_In_Time) as Scheduled_In_Time,
  DATEADD(HOUR, -2, Clockin.Scheduled_Out_Time) as Scheduled_Out_Time,
  --Amount of hours to subtract from Scheduled_Out_Time to yield exactly 8 scheduled hours and 30 minutes for lunch if applicable
  --Negative number
  CASE
    --If larger than 8.5 hours
    WHEN ABS(DATEDIFF(MI, Clockin.Scheduled_In_Time, Clockin.Scheduled_Out_Time)) > 510.00 THEN
      DATEDIFF(MI, Clockin.Scheduled_Out_Time, Clockin.Scheduled_In_Time) + 510.00
    ELSE
      0.00
  END as Scheduled_OT
  
  FROM Personnel_v_Clockin Clockin
    JOIN Personnel_v_Employee EMP
      ON Clockin.Plexus_User_No = EMP.Plexus_User_No
    JOIN Personnel_v_Clockin_Type CT
      ON Clockin.Clockin_Type_Key = CT.Clockin_Type_Key
    JOIN Plexus_Control_v_Plexus_User PU
      ON EMP.Plexus_User_No = PU.Plexus_User_No

  WHERE Clockin.Scheduled_In_Time BETWEEN '2022-01-01' AND GETDATE()
    AND (Clockin.Clockin_Type_Key = 388
        OR Clockin.Clockin_Type_Key = 394)
    AND DATENAME(dw, Clockin.Scheduled_In_Time) <> 'Saturday'
    AND DATENAME(dw, Clockin.Scheduled_In_Time) <> 'Sunday'
) AS TT

GROUP BY TT.Badge_No, TT.Employee_Name, TT.Description, TT.Date, TT.Scheduled_In_Time, TT.Scheduled_Out_Time, TT.Scheduled_OT
ORDER BY TT.Badge_No