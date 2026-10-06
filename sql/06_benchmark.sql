-- 06_benchmark.sql  (consultas del benchmark)
-- scripts/benchmark.py crea bench_parquet y bench_table con el mismo esquema,
-- sustituye {fuente} por cada una y {filtro} por uno de estos volumenes:
--   source_file LIKE '%/2026/%_2026-01.parquet'  -- un mes
--   source_file LIKE '%/2025/%'                  -- un anio
--   TRUE                                         -- conjunto completo

-- [B1] Conteo por tipo
SELECT taxi_type, count(*) AS viajes
FROM {fuente}
WHERE {filtro}
GROUP BY taxi_type
ORDER BY taxi_type;

-- [B2] Resumen mensual
SELECT taxi_type, anio, mes,
       count(*) FILTER (WHERE es_valido) AS viajes_validos,
       round(avg(fare_amount) FILTER (WHERE es_valido), 2) AS tarifa_promedio,
       round(avg(total_amount) FILTER (WHERE es_valido), 2) AS total_promedio
FROM {fuente}
WHERE {filtro}
GROUP BY taxi_type, anio, mes
ORDER BY taxi_type, anio, mes;

-- [B3] Formas de pago
SELECT taxi_type, payment_type, count(*) AS viajes
FROM {fuente}
WHERE {filtro} AND es_valido
GROUP BY taxi_type, payment_type
ORDER BY taxi_type, payment_type NULLS FIRST;

-- [B4] Percentiles y medianas
SELECT taxi_type,
       round(median(trip_distance) FILTER
             (WHERE es_valido AND trip_distance BETWEEN 0.01 AND 100), 2) AS distancia_mediana,
       round(quantile_cont(total_amount, 0.95) FILTER (WHERE es_valido), 2) AS total_p95,
       round(quantile_cont(duracion_min, 0.95) FILTER (WHERE es_valido), 2) AS duracion_p95
FROM {fuente}
WHERE {filtro}
GROUP BY taxi_type
ORDER BY taxi_type;
