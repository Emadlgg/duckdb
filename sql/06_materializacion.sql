-- 06_materializacion.sql  (Ejercicio 6)
-- Requiere sql/00_vistas.sql y una conexion a data/processed/taxi.duckdb.
-- La tabla conserva todas las filas. es_valido aplica los mismos criterios que
-- trips_limpios, pero no elimina registros para que la comparacion sea completa.

CREATE OR REPLACE TABLE taxi_trips AS
SELECT taxi_type,
       filename AS source_file,
       CAST(regexp_extract(filename, '/(\d{4})/', 1) AS SMALLINT) AS anio,
       CAST(regexp_extract(filename, '(\d{2})\.parquet$', 1) AS TINYINT) AS mes,
       pickup_ts,
       dropoff_ts,
       passenger_count,
       trip_distance,
       PULocationID,
       DOLocationID,
       payment_type,
       fare_amount,
       tip_amount,
       tolls_amount,
       total_amount,
       date_diff('second', pickup_ts, dropoff_ts) / 60.0 AS duracion_min,
       strftime(pickup_ts, '%Y-%m') = regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1)
           AND dropoff_ts >= pickup_ts
           AND dropoff_ts - pickup_ts <= INTERVAL 24 HOUR
           AND fare_amount >= 0
           AND total_amount > 0 AS es_valido
FROM trips;

-- Comprobacion: debe coincidir con la suma de parquet_file_metadata.
SELECT (SELECT count(*) FROM taxi_trips) AS filas_tabla,
       (SELECT sum(num_rows)
        FROM parquet_file_metadata('/workspace/data/raw/*/*/*.parquet')) AS filas_parquet,
       (SELECT count(DISTINCT source_file) FROM taxi_trips) AS archivos;

SELECT taxi_type, anio, count(*) AS viajes
FROM taxi_trips
GROUP BY ALL
ORDER BY taxi_type, anio;
