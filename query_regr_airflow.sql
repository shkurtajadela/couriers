DECLARE @now DATETIME = GETDATE();
/* datetime format DATETIME = '2025-01-31 00:45:00';*/

WITH intervals AS (
    SELECT v.end_time, v.start_time
    FROM (VALUES
        (@now, DATEADD(MINUTE, -15, @now)),
        (DATEADD(MINUTE, -15, @now), DATEADD(MINUTE, -30, @now)),
        (DATEADD(MINUTE, -30, @now), DATEADD(MINUTE, -45, @now)),
        (DATEADD(MINUTE, -45, @now), DATEADD(MINUTE, -60, @now))
    ) AS v(end_time, start_time)
)
SELECT 
    i.end_time AS date_group,
    t.ShopNo,
    COUNT(DISTINCT t.id_courier) AS active_couriers_count
FROM Reports_data.Report.report_zakaz_tbl t
JOIN intervals i
    ON t.date_delivery_start BETWEEN i.start_time AND i.end_time
JOIN Analitika.dbo.tt ON tt.N = t.ShopNo 
WHERE region_tt = 'Москва' AND Статус = 'Открыт' AND tt_format_rasp = 700
GROUP BY i.end_time, t.ShopNo
ORDER BY t.ShopNo, i.end_time;