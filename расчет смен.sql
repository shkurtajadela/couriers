WITH OrderedDeliveries AS (
    SELECT 
        id_courier,
        date_pickuped,
        date_delivered,
        LAG(date_delivered) OVER (PARTITION BY id_courier ORDER BY date_pickuped) AS previous_delivery_time
    FROM [Loyalty_srv03].[dbo].[Delivery_Job_LinesZIZ_DYN] dy
    LEFT JOIN [Loyalty_srv03].[dbo].[delivery_couriers] (NOLOCK) dc 
    ON dc.id = dy.id_courier
    where date_pickuped >= '20250101' and date_pickuped < '20250201'
),
Shifts AS (
    SELECT 
        id_courier,
        date_pickuped AS shift_start_time,
        date_delivered AS shift_end_time,
        CASE 
            WHEN previous_delivery_time IS NULL THEN 0
            ELSE DATEDIFF(SECOND, previous_delivery_time, date_pickuped) / 3600.0
        END AS hours_since_last_order,
        CASE 
            WHEN previous_delivery_time IS NULL OR DATEDIFF(SECOND, previous_delivery_time, date_pickuped) / 3600.0 > 2 THEN 1 -- вот тут хардкод 2 часов, крути, как хочешь
            ELSE 0
        END AS is_new_shift
    FROM OrderedDeliveries
),
ShiftGroups AS (
    SELECT 
        id_courier,
        shift_start_time,
        shift_end_time,
        SUM(is_new_shift) OVER (PARTITION BY id_courier ORDER BY shift_start_time ROWS UNBOUNDED PRECEDING) AS shift_group
    FROM Shifts
),
FinalShifts AS (
    SELECT
        id_courier,
        MIN(shift_start_time) AS shift_start,
        MAX(shift_end_time) AS shift_end,
        DATEDIFF(SECOND, MIN(shift_start_time), MAX(shift_end_time)) / 3600.0 AS shift_length_hours,
        COUNT(*) AS orders_per_shift
    FROM ShiftGroups
    GROUP BY id_courier, shift_group
)
SELECT
    id_courier,
    CAST(shift_start AS DATE) AS date_,
    shift_start,
    shift_end,
    shift_length_hours,
    CEILING(shift_length_hours) AS shift_length_hours_rounded,
    orders_per_shift
FROM FinalShifts;