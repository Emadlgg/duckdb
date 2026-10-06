-- 03_exploracion.sql  (Ejercicio 3)
-- Requiere sql/00_vistas.sql. Todas las consultas leen directo de los Parquet.

-- [3.1] Cantidad de archivos, por tipo de taxi y anio
SELECT regexp_extract(file, '/raw/(yellow|green)/(\d{4})/', 1) AS taxi,
       regexp_extract(file, '/raw/(yellow|green)/(\d{4})/', 2) AS anio,
       count(*) AS archivos
FROM glob('/workspace/data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY taxi, anio;

-- [3.2a] Cantidad de registros leyendo solo los metadatos del Parquet (no escanea datos)
SELECT regexp_extract(file_name, '/raw/(yellow|green)/', 1) AS taxi,
       sum(num_rows) AS registros
FROM parquet_file_metadata('/workspace/data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY taxi;

-- [3.2b] Cantidad de registros por tipo y mes, contando filas
SELECT taxi_type,
       regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1) AS archivo_mes,
       count(*) AS registros
FROM trips
GROUP BY ALL
ORDER BY taxi_type, archivo_mes;

-- [3.3 y 3.4] Columnas y tipos de datos
DESCRIBE SELECT * FROM yellow_raw;

DESCRIBE SELECT * FROM green_raw;

-- [3.5] Muestra de registros
SELECT * FROM yellow_raw USING SAMPLE 10 ROWS;

SELECT * FROM green_raw USING SAMPLE 10 ROWS;

-- [3.6a] Resumen estadistico por columna (min, max, nulos, cuantiles)
SUMMARIZE SELECT * FROM yellow_raw;

SUMMARIZE SELECT * FROM green_raw;

-- [3.6b] Conteo de problemas de calidad por tipo de taxi
SELECT taxi_type,
       count(*)                                                        AS total,
       count(*) FILTER (WHERE passenger_count IS NULL)                 AS pasajeros_nulos,
       count(*) FILTER (WHERE passenger_count = 0)                     AS pasajeros_cero,
       count(*) FILTER (WHERE trip_distance <= 0)                      AS distancia_no_positiva,
       count(*) FILTER (WHERE fare_amount < 0)                         AS tarifa_negativa,
       count(*) FILTER (WHERE total_amount <= 0)                       AS total_no_positivo,
       count(*) FILTER (WHERE dropoff_ts < pickup_ts)                  AS dropoff_antes_de_pickup,
       count(*) FILTER (WHERE date_diff('hour', pickup_ts, dropoff_ts) > 24) AS duracion_mayor_24h,
       count(*) FILTER (WHERE strftime(pickup_ts, '%Y-%m')
                              <> regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1)) AS fuera_del_mes_del_archivo
FROM trips
GROUP BY taxi_type;

-- [3.6c] Fechas fuera del rango esperado: de que meses reales vienen los viajes
SELECT taxi_type, date_trunc('month', pickup_ts) AS mes_real, count(*) AS viajes
FROM trips
GROUP BY ALL
ORDER BY taxi_type, mes_real;

-- [3.6d] Que valores trae request_source y cuantos viajes tiene cada uno
SELECT 'yellow' AS taxi_type, request_source, count(*) AS viajes FROM yellow_raw GROUP BY ALL
UNION ALL
SELECT 'green' AS taxi_type, request_source, count(*) AS viajes FROM green_raw GROUP BY ALL
ORDER BY taxi_type, viajes DESC;

-- [3.6e] Porcentaje de passenger_count nulo por archivo
SELECT taxi_type,
       regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1) AS archivo_mes,
       count(*) AS total,
       count(*) FILTER (WHERE passenger_count IS NULL) AS nulos,
       round(100.0 * count(*) FILTER (WHERE passenger_count IS NULL) / count(*), 1) AS pct_nulos
FROM trips
GROUP BY ALL
ORDER BY taxi_type, archivo_mes;

-- [3.6f] Viajes con distancia cero o negativa: que tarifa y duracion tienen
SELECT taxi_type,
       count(*) AS viajes,
       count(*) FILTER (WHERE fare_amount > 0) AS con_tarifa_positiva,
       round(avg(fare_amount), 2) AS tarifa_prom,
       round(avg(date_diff('second', pickup_ts, dropoff_ts) / 60.0), 1) AS duracion_prom_min
FROM trips
WHERE trip_distance <= 0
GROUP BY taxi_type;
