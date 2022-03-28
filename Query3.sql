--perfect_attendance -
--Find all employees that still qualify for the perfect attendance bonuses
--This query finds all the IDs of people who aren't qualified and subtracts
--them from the the group of all IDs, which should leave the IDs of those
--who are qualified
--Range: Entirety of 2021 and one or two quarters of 2021
--Work-In-Progress
---No unexcused lates
---No unexcused absences -> no PTO and no Holiday on an unpaid day is an example
---Worked 8 hours Monday-Friday

SELECT
DISTINCT EMP.Badge_No,
PU.First_Name + ' ' + PU.Last_Name AS Name

FROM Personnel_v_Clockin Clockin
  JOIN Personnel_v_Employee EMP
    ON Clockin.Plexus_User_No = EMP.Plexus_User_No
  JOIN Personnel_v_Clockin_Type CT
    ON Clockin.Clockin_Type_Key = CT.Clockin_Type_Key
  JOIN Plexus_Control_v_Plexus_User PU
	  ON EMP.Plexus_User_No = PU.Plexus_User_No


WHERE Clockin.Pay_Date BETWEEN '2021-01-01' AND '2021-12-31'
AND EMP.Badge_No > 0
AND CT.Paid = 1
AND DATENAME(dw, Clockin.Pay_Date) <> 'Saturday'
AND DATENAME(dw, Clockin.Pay_Date) <> 'Sunday'
--Filter out all employees that have at least one day of insufficient hours
AND EMP.Badge_No NOT IN (
  --Find all employees that have at least one day of insufficient hours
  --or a late day
  SELECT
  DISTINCT Hours.Badge_No
  
  FROM (
    --Get the amount of standard hours worked by every employee for each of their shifts
    --and get the clockin times for those shifts
    SELECT
    EMP.Badge_No,
    CAST(Clockin.Pay_Date AS DATE) AS Date,
    SUM(Clockin.Regular_Hours) AS Worked_Hours,
    --Using an aggregate function allows GROUP BY to combine a person's split shifts due to lunch clocking based on the date
    --Using MIN() in particular returns the morning clock in time, not the lunch clock in time
    MIN(Clockin.Scheduled_In_Time) AS Earliest_Scheduled_Clockin,
    MIN(Clockin.System_Clockin_Time) AS Earliest_Actual_Clockin,
    --Passing Active to the next outer query returns 4 employees in the final results
    MAX(PU.Active) AS Active,
    MAX(Clockin.Late) AS Late
  
    FROM Personnel_v_Clockin Clockin
      JOIN Personnel_v_Employee EMP
        ON Clockin.Plexus_User_No = EMP.Plexus_User_No
      JOIN Plexus_Control_v_Plexus_User PU
	      ON EMP.Plexus_User_No = PU.Plexus_User_No
    
    WHERE Clockin.Pay_Date BETWEEN '2021-01-01' AND '2021-12-31'
    AND EMP.Badge_No > 0
    AND DATENAME(dw, Clockin.Pay_Date) <> 'Saturday'
    AND DATENAME(dw, Clockin.Pay_Date) <> 'Sunday'
    -- -1 may mean a person is active
    --Using this line results in 141 employees being returned in the final results
    --AND PU.Active = -1
    
    GROUP BY EMP.Badge_No, Clockin.Pay_Date
  ) AS Hours
  
  --Check if a person worked less than 8.0 hours (weekdays only)
  WHERE Hours.Worked_Hours < 8.0
  --Check is a person had both a late clockin and a set late marker.
  --If someone had a prrearranged clockin time that occurs after their
  --scheduled clockin time but their late marker is 0, they fail this check
  OR (DATEDIFF(MI, Hours.Earliest_Scheduled_Clockin, Hours.Earliest_Actual_Clockin) > 0
    AND Hours.Late = 1)
  --Check if a person is no longer working here
  OR Hours.Active = 0
)

ORDER BY EMP.Badge_No