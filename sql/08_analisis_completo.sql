-- 08_analisis_completo.sql  (Ejercicio 8)
-- Comparaciones de 2024, 2025 y 2026. Para evitar comparar doce meses contra
-- ocho, las tendencias entre anios usan siempre enero-agosto.

-- [8.3] Archivos y filas incorporados por tipo y anio.
SELECT taxi_type, anio, count(DISTINCT source_file) AS archivos, count(*) AS filas
FROM taxi_trips
GROUP BY ALL
ORDER BY taxi_type, anio;

-- [8.5a] Evolucion mensual, normalizada por cantidad de dias observados.
SELECT taxi_type, anio, mes, count(*) AS viajes,
       count(DISTINCT pickup_ts::DATE) AS dias,
       round(count(*) / count(DISTINCT pickup_ts::DATE)) AS viajes_por_dia
FROM taxi_trips
WHERE es_valido
GROUP BY ALL
ORDER BY taxi_type, anio, mes;

-- [8.5b] Resumen comparable de enero-agosto.
SELECT taxi_type, anio,
       count(*) AS viajes,
       round(count(*) / count(DISTINCT pickup_ts::DATE)) AS viajes_por_dia,
       round(median(trip_distance) FILTER (WHERE trip_distance BETWEEN 0.01 AND 100), 2) AS distancia_mediana,
       round(avg(total_amount), 2) AS total_promedio,
       round(100.0 * count(*) FILTER (WHERE payment_type = 1) / count(*), 2) AS pct_tarjeta,
       round(100.0 * count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) / count(*), 2) AS pct_flex
FROM taxi_trips
WHERE es_valido AND mes BETWEEN 1 AND 8
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;

-- [8.5c] Cambio porcentual del volumen diario entre anios consecutivos.
WITH resumen AS (
    SELECT taxi_type, anio,
           count(*) / count(DISTINCT pickup_ts::DATE) AS viajes_por_dia
    FROM taxi_trips
    WHERE es_valido AND mes BETWEEN 1 AND 8
    GROUP BY taxi_type, anio
), cambios AS (
    SELECT *, lag(viajes_por_dia) OVER (PARTITION BY taxi_type ORDER BY anio) AS anterior
    FROM resumen
)
SELECT taxi_type, anio, round(viajes_por_dia) AS viajes_por_dia,
       round(100.0 * (viajes_por_dia - anterior) / anterior, 1) AS cambio_pct
FROM cambios
ORDER BY taxi_type, anio;

-- [8.5d] Evolucion de propinas con tarjeta en el periodo comparable.
SELECT taxi_type, anio,
       round(median(100.0 * tip_amount / fare_amount), 2) AS propina_pct_mediana,
       round(avg(tip_amount), 2) AS propina_dolares_promedio
FROM taxi_trips
WHERE es_valido AND mes BETWEEN 1 AND 8
  AND payment_type = 1 AND fare_amount > 0
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;

-- [8.6] Calidad: cambio en los principales problemas por anio.
SELECT taxi_type, anio, count(*) AS filas,
       round(100.0 * count(*) FILTER (WHERE NOT es_valido) / count(*), 2) AS pct_invalidos,
       round(100.0 * count(*) FILTER (WHERE trip_distance <= 0) / count(*), 2) AS pct_distancia_no_positiva,
       round(100.0 * count(*) FILTER (WHERE passenger_count IS NULL) / count(*), 2) AS pct_pasajeros_nulos
FROM taxi_trips
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;

-- [8.6b] Que criterio de validez produce los invalidos de yellow en cada anio.
SELECT anio,
       count(*) FILTER (WHERE NOT es_valido) AS invalidos,
       count(*) FILTER (WHERE strftime(pickup_ts, '%Y-%m')
                              <> regexp_extract(source_file, '(\d{4}-\d{2})\.parquet$', 1)) AS fuera_del_mes,
       count(*) FILTER (WHERE dropoff_ts < pickup_ts) AS bajada_antes_de_subida,
       count(*) FILTER (WHERE dropoff_ts - pickup_ts > INTERVAL 24 HOUR) AS mas_de_24h,
       count(*) FILTER (WHERE fare_amount < 0) AS tarifa_negativa,
       count(*) FILTER (WHERE total_amount <= 0) AS total_no_positivo
FROM taxi_trips
WHERE taxi_type = 'yellow'
GROUP BY anio
ORDER BY anio;

-- [8.6c] Invalidos de yellow 2025 por mes y tipo de pago.
SELECT mes, payment_type, count(*) AS invalidos
FROM taxi_trips
WHERE taxi_type = 'yellow' AND anio = 2025 AND NOT es_valido
GROUP BY ALL
ORDER BY mes, invalidos DESC;