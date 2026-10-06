-- 04_eda.sql  (Ejercicio 4)
-- Requiere sql/00_vistas.sql.
-- trips_limpios descarta lo que 3.6 mostro como invalido. Ajustar los filtros
-- segun lo que se decida a partir de esos resultados, y documentar la decision.

CREATE OR REPLACE VIEW trips_limpios AS
SELECT *,
       date_diff('second', pickup_ts, dropoff_ts) / 60.0 AS duracion_min
FROM trips
WHERE strftime(pickup_ts, '%Y-%m') = regexp_extract(filename, '(\d{4}-\d{2})\.parquet$', 1)
  AND dropoff_ts >= pickup_ts
  AND trip_distance > 0
  AND fare_amount >= 0
  AND total_amount > 0;

-- [Q1] Como evoluciona el volumen de viajes mes a mes, y que tan distinto es en yellow vs green
SELECT taxi_type, date_trunc('month', pickup_ts)::DATE AS mes, count(*) AS viajes
FROM trips_limpios
GROUP BY ALL
ORDER BY taxi_type, mes;

-- [Q2] En que horas del dia se concentra la demanda
SELECT taxi_type, hour(pickup_ts) AS hora, count(*) AS viajes
FROM trips_limpios
GROUP BY ALL
ORDER BY taxi_type, hora;

-- [Q3] Cambia la demanda entre dias de la semana (isodow: 1 = lunes)
SELECT taxi_type, isodow(pickup_ts) AS dia_semana, count(*) AS viajes,
       round(avg(trip_distance), 2) AS distancia_prom_millas
FROM trips_limpios
GROUP BY ALL
ORDER BY taxi_type, dia_semana;

-- [Q4] Como son los viajes tipicos: distancia, duracion y pasajeros
SELECT taxi_type,
       round(avg(trip_distance), 2)                  AS distancia_prom,
       round(median(trip_distance), 2)               AS distancia_mediana,
       round(quantile_cont(trip_distance, 0.95), 2)  AS distancia_p95,
       round(avg(duracion_min), 1)                   AS duracion_prom_min,
       round(median(duracion_min), 1)                AS duracion_mediana_min,
       round(avg(passenger_count), 2)                AS pasajeros_prom
FROM trips_limpios
GROUP BY taxi_type;

-- [Q5] Distribucion de la distancia por rangos
WITH rangos AS (
    SELECT taxi_type,
           CASE WHEN trip_distance < 1  THEN '0-1'
                WHEN trip_distance < 3  THEN '1-3'
                WHEN trip_distance < 5  THEN '3-5'
                WHEN trip_distance < 10 THEN '5-10'
                WHEN trip_distance < 20 THEN '10-20'
                ELSE '20+' END AS rango_millas,
           CASE WHEN trip_distance < 1  THEN 1
                WHEN trip_distance < 3  THEN 2
                WHEN trip_distance < 5  THEN 3
                WHEN trip_distance < 10 THEN 4
                WHEN trip_distance < 20 THEN 5
                ELSE 6 END AS orden
    FROM trips_limpios
)
SELECT taxi_type, rango_millas, count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS porcentaje
FROM rangos
GROUP BY taxi_type, rango_millas, orden
ORDER BY taxi_type, orden;

-- [Q6] Diferencias en tarifa entre yellow y green
SELECT taxi_type,
       round(avg(fare_amount), 2)  AS tarifa_prom,
       round(avg(total_amount), 2) AS total_prom,
       round(avg(tip_amount), 2)   AS propina_prom,
       round(avg(tolls_amount), 2) AS peajes_prom,
       round(avg(fare_amount / trip_distance), 2) AS tarifa_por_milla
FROM trips_limpios
GROUP BY taxi_type;

-- [Q7] Como pagan los pasajeros (0 flex, 1 tarjeta, 2 efectivo, 3 sin cargo, 4 disputa, 5 desconocido, 6 anulado)
SELECT taxi_type, payment_type, count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type), 2) AS porcentaje,
       round(avg(tip_amount), 2) AS propina_prom
FROM trips_limpios
GROUP BY taxi_type, payment_type
ORDER BY taxi_type, viajes DESC;

-- [Q8] Porcentaje de propina sobre la tarifa, solo viajes con tarjeta
SELECT taxi_type,
       round(avg(100.0 * tip_amount / fare_amount), 2)                    AS propina_pct_prom,
       round(quantile_cont(100.0 * tip_amount / fare_amount, 0.5), 2)     AS propina_pct_mediana
FROM trips_limpios
WHERE payment_type = 1 AND fare_amount > 0
GROUP BY taxi_type;

-- [Q9] Valores atipicos: percentiles altos y maximos de las variables clave
SELECT taxi_type,
       round(quantile_cont(trip_distance, 0.99), 1) AS dist_p99,
       max(trip_distance)                           AS dist_max,
       round(quantile_cont(duracion_min, 0.99), 1)  AS dur_p99_min,
       round(max(duracion_min), 1)                  AS dur_max_min,
       round(quantile_cont(total_amount, 0.99), 1)  AS total_p99,
       max(total_amount)                            AS total_max
FROM trips_limpios
GROUP BY taxi_type;

-- [Q10] Inconsistencias fisicas: velocidades imposibles (mas de 80 mph) o viajes de mas de 100 millas
SELECT taxi_type,
       count(*) FILTER (WHERE duracion_min > 0 AND trip_distance / (duracion_min / 60.0) > 80) AS velocidad_imposible,
       count(*) FILTER (WHERE trip_distance > 100) AS mas_de_100_millas,
       count(*) FILTER (WHERE total_amount > 500)  AS total_mayor_500
FROM trips_limpios
GROUP BY taxi_type;
