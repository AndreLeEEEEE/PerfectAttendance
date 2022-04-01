--"attendance_records" query -
--Find all days with missing full-time hours.
--for every employee
--from 1/1/2022 to today.
--Work-in-Progress
---Take out all things related to tardiness
---Use Clockin/out_Time instead of System_Clockin/out_Time
---Actually combine split days, refer to query 'perfect_attendance' on how to achieve this

SELECT
Hours.Badge_No,
Hours.Name,
Hours.Date,
Hours.Worked_Hours,
CASE
  WHEN 8.0 - Hours.Worked_Hours > 0 THEN
    8.0 - Hours.Worked_Hours
  ELSE
    0.0
END AS Missing_Hours

FROM (
  SELECT
  EMP.Badge_No,
  PU.First_Name + ' ' + PU.Last_Name AS Name,
  CAST(Clockin.Pay_Date AS DATE) AS Date,
  SUM(Clockin.Regular_Hours) as Worked_Hours
  
  FROM Personnel_v_Clockin Clockin
    JOIN Personnel_v_Employee EMP
      ON Clockin.Plexus_User_No = EMP.Plexus_User_No
    JOIN Personnel_v_Clockin_Type CT
      ON Clockin.Clockin_Type_Key = CT.Clockin_Type_Key
    JOIN Plexus_Control_v_Plexus_User PU
      ON EMP.Plexus_User_No = PU.Plexus_User_No
    
  WHERE Clockin.Pay_Date BETWEEN '2022-01-01' AND GETDATE()
  AND EMP.Badge_No > 0
  AND DATENAME(dw, Clockin.Pay_Date) <> 'Saturday'
  AND DATENAME(dw, Clockin.Pay_Date) <> 'Sunday'
  AND CT.Clockin_Type_Key <> 395
  AND CT.Clockin_Type_Key <> 9723
  AND CT.Clockin_Type_Key <> 10804
  AND CT.Clockin_Type_Key <> 10805
  AND CT.Clockin_Type_Key <> 10806
  AND CT.Clockin_Type_Key <> 10807
  AND PU.Active <> 0
  
  GROUP BY EMP.Badge_No, PU.First_Name, PU.Last_Name, Clockin.Pay_Date
  --ORDER BY EMP.Badge_No, Clockin.Pay_Date
) AS Hours

WHERE Hours.Worked_Hours < 8.0;