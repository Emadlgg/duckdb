-- 00_vistas.sql
-- Vistas base sobre los archivos Parquet. No se importa nada a una tabla.
-- Los comodines */* cubren cualquier anio que exista en data/raw/<tipo>/<anio>/,
-- asi que al descargar 2024 o 2025 las vistas los incluyen sin cambiar nada.
-- union_by_name = true alinea las columnas por nombre aunque cambie el esquema entre archivos.
-- filename = true agrega la columna filename, util para saber de que archivo viene cada fila.

CREATE OR REPLACE VIEW yellow_raw AS
SELECT * FROM read_parquet('/workspace/data/raw/yellow/*/*.parquet',
                           union_by_name = true, filename = true);

CREATE OR REPLACE VIEW green_raw AS
SELECT * FROM read_parquet('/workspace/data/raw/green/*/*.parquet',
                           union_by_name = true, filename = true);

-- Vista unificada con las columnas que comparten ambos tipos de taxi.
-- Yellow usa tpep_* y green usa lpep_* para las fechas.
CREATE OR REPLACE VIEW trips AS
SELECT 'yellow' AS taxi_type, filename,
       tpep_pickup_datetime  AS pickup_ts,
       tpep_dropoff_datetime AS dropoff_ts,
       passenger_count, trip_distance, PULocationID, DOLocationID,
       payment_type, fare_amount, tip_amount, tolls_amount, total_amount
FROM yellow_raw
UNION ALL
SELECT 'green' AS taxi_type, filename,
       lpep_pickup_datetime  AS pickup_ts,
       lpep_dropoff_datetime AS dropoff_ts,
       passenger_count, trip_distance, PULocationID, DOLocationID,
       payment_type, fare_amount, tip_amount, tolls_amount, total_amount
FROM green_raw;
