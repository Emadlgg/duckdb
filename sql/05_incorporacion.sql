-- 05_incorporacion.sql  (Ejercicio 5)
-- Valida que los anios nuevos entraron y que se pueden consultar junto con 2026.
-- Requiere sql/00_vistas.sql. Las vistas no se modificaron para incorporar 2024.

-- [5.5a] Archivos por tipo y anio
SELECT regexp_extract(file, '/raw/(yellow|green)/(\d{4})/', 1) AS taxi,
       regexp_extract(file, '/raw/(yellow|green)/(\d{4})/', 2) AS anio,
       count(*) AS archivos
FROM glob('/workspace/data/raw/*/*/*.parquet')
GROUP BY ALL
ORDER BY taxi, anio;

-- [5.6a] Registros por tipo y anio del archivo, leyendo ambos anios en la misma consulta
SELECT taxi_type,
       regexp_extract(filename, '/(\d{4})/', 1) AS anio_archivo,
       count(*) AS registros
FROM trips
GROUP BY ALL
ORDER BY taxi_type, anio_archivo;

-- [5.6b] Viajes por mes de pickup, 2024 y 2026 juntos (solo viajes dentro del mes de su archivo)
SELECT taxi_type, date_trunc('month', pickup_ts)::DATE AS mes, count(*) AS viajes
FROM trips
WHERE strftime(pickup_ts, '%Y-%m') = regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1)
GROUP BY ALL
ORDER BY taxi_type, mes;

-- [5.7a] Columnas de yellow por anio: aparecen, desaparecen o cambian de tipo entre anios
SELECT name AS columna,
       list(DISTINCT regexp_extract(file_name, '/(\d{4})/', 1) ORDER BY 1) AS anios,
       list(DISTINCT type ORDER BY 1) AS tipos,
       count(DISTINCT file_name) AS archivos
FROM parquet_schema('/workspace/data/raw/yellow/*/*.parquet')
WHERE name <> 'schema'
GROUP BY name
ORDER BY name;

-- [5.7b] Lo mismo para green
SELECT name AS columna,
       list(DISTINCT regexp_extract(file_name, '/(\d{4})/', 1) ORDER BY 1) AS anios,
       list(DISTINCT type ORDER BY 1) AS tipos,
       count(DISTINCT file_name) AS archivos
FROM parquet_schema('/workspace/data/raw/green/*/*.parquet')
WHERE name <> 'schema'
GROUP BY name
ORDER BY name;

-- [5.7c] Tipos finales que ve DuckDB despues de unir los anios
DESCRIBE SELECT * FROM yellow_raw;

DESCRIBE SELECT * FROM green_raw;
