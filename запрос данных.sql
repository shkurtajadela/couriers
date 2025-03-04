DECLARE @StartDate DATE = '20241002';
DECLARE @EndDate DATE = '20241003';

WITH GeneralOrders AS (
    SELECT TOP 100
        og.id_general,
        SUM(z.order_weight) AS total_order_weight, 
        COUNT(z.id_order) AS total_orders,

        MIN(z.date_order) AS first_date_order, 
        MAX(z.date_order) AS last_date_order, 

        MAX(z.date_supply) AS date_supply,
        MAX(z.date_supply_untill) AS date_supply_untill,
        MAX(z.date_collected) AS date_collected,
        MAX(z.date_delivery_start) AS date_delivery_start,
        MAX(z.date_delivered) AS date_delivered,

        MAX(z.id_courier) AS id_courier,
        MAX(z.id_service) AS id_service,
        MAX(z.source) AS id_source,
        MAX(z.latitude) AS latitude_order,
        MAX(z.longitude) AS longitude_order,
        MAX(tt.N) AS N,
        MAX(tt.Shirota) AS shirota_tt,
        MAX(tt.Dolgota) AS dolgota_tt,
        MAX(z.distance) AS gen_distance

    FROM Reports_data.Report.report_zakaz_tbl z
    INNER JOIN Analitika.dbo.tt ON tt.N = z.ShopNo
    INNER JOIN Analitika.dbo.address_geohash ag ON z.[address] = ag.Адрес_доставки AND tt.city_tt = ag.city_tt
    INNER JOIN Analitika.dbo.geomonitoring_districts gd ON gd.id = ag.district
    JOIN [Loyalty_srv03].[dbo].[order_general] AS og ON z.[id_order] = og.[id_order]
    WHERE gd.region_name = 'Москва'
        AND z.date_order >= @StartDate
        AND z.date_order < @EndDate
        AND z.Latitude IS NOT NULL
        AND z.Longitude IS NOT NULL 
    GROUP BY og.id_general
), 
RankedParcels AS (
    SELECT
        id_parcel, 
        status_str, 
        date_add,
        ROW_NUMBER() OVER (
            PARTITION BY id_parcel 
            ORDER BY 
                CASE 
                    WHEN status_str = 'job_reposted' THEN 1 
                    ELSE 2 
                END, 
                date_add DESC
        ) AS rn
    FROM [Loyalty_srv03].[dbo].[Delivery_Job_History]
    WHERE date_add >= @StartDate 
        AND date_add < @EndDate
        AND status_str IN ('job_posted', 'job_reposted')
)
SELECT TOP 100 jl.[id_pool],
  jl.[id_courier],
  CASE WHEN tr.id_courier_type = 1 THEN 'Ночной авто курьер'
              WHEN tr.id_courier_type = 2 THEN 'Вело'
              WHEN tr.id_courier_type = 3 THEN 'Авто'
              WHEN tr.id_courier_type = 4 THEN 'Вело Свой'
              WHEN tr.id_courier_type = 5 THEN 'Авто час'
              WHEN tr.id_courier_type = 6 THEN 'Мобильный курьер'
              WHEN tr.id_courier_type = 7 THEN 'Ночной Вело Курьер'
          ELSE 'Тип курьера неизвестен' END AS courier_type,
  jl.[id_job],
  jl.[date_start] AS pool_date_start,
  jl.[sort_order],
  jl.[id_general],
  jl.[distance],
  rp.status_str,
  rp.[date_add] AS date_status, 
  ord.*
  FROM GeneralOrders ord 
  LEFT JOIN [Loyalty_srv03].[dbo].Delivery_Job_LinesZIZ_DYN jl ON ord.id_general = jl.[id_general] 
  LEFT JOIN RankedParcels rp ON rp.id_parcel = jl.id_parcel
  LEFT JOIN  loyalty_srv03..delivery_couriers tr ON tr.id = jl.[id_courier]
  WHERE rp.rn = 1;

/* заказы таблицы
[Reports_Data].[Report].[arc_report_zakaz_tbl] - января 2023 до июня 2023
Reports_Data.Report.[report_zakaz_tbl:Archive] - с июня 2023 до октября 2024
Reports_data.Report.report_zakaz_tbl - данные с октября 2024
ИЛИ
[Loyalty_srv03].[dbo].[Orders_header]

[SQL03_ARC].[Loyalty].[Delivery_jobs] - все данные
[Loyalty_srv03].[dbo].Delivery_Job_History_old -  с января 2024 до февр 2024 вкл
[Loyalty_srv03].[dbo].[Delivery_Job_History] - с марта 2024

формат даты: yyyymmdd*/