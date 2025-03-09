DECLARE @StartDate DATETIME = '2025-01-02';  -- Объявление переменной с нужной датой yyyy-dd-mm

WITH TimeIntervals AS (
    -- Генерация 15-минутных интервалов для всех данных в таблице
    SELECT DISTINCT
        ShopNo,
        -- Округляем время начала доставки до ближайшего 15-минутного интервала
        DATEADD(MINUTE, (DATEDIFF(MINUTE, @StartDate, t.date_delivery_start) / 15) * 15, @StartDate) AS time_interval
    FROM Reports_data.Report.report_zakaz_tbl t
    WHERE t.date_delivery_start > @StartDate
    AND t.ShopNo IN (4785, 5485, 6028, 7368, 8047)
),
ActiveCouriers AS (
    -- Выбираем уникальных курьеров для каждого 15-минутного интервала
    SELECT
        t.ShopNo,
        DATEADD(MINUTE, (DATEDIFF(MINUTE, @StartDate, t.date_delivery_start) / 15) * 15, @StartDate) AS time_interval,
        t.id_courier
    FROM Reports_data.Report.report_zakaz_tbl t
    WHERE t.date_delivery_start > @StartDate
    AND t.ShopNo IN (4785, 5485, 6028, 7368, 8047)
),
CourierCount AS (
    -- Подсчитываем количество уникальных курьеров в каждом интервале
    SELECT
        a.ShopNo,
        a.time_interval,
        COUNT(DISTINCT a.id_courier) AS active_courier_count
    FROM ActiveCouriers a
    GROUP BY a.ShopNo, a.time_interval
)
-- Финальный запрос
SELECT
    c.ShopNo,
    c.time_interval,
    c.active_courier_count
FROM CourierCount c
ORDER BY c.ShopNo, c.time_interval;
