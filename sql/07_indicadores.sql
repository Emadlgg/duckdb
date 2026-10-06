-- 07_indicadores.sql  (Ejercicio 7)
-- Diez preguntas para el tablero. Todas usan la tabla materializada y, salvo
-- el indicador de calidad, trabajan solo con registros marcados como validos.

-- [I1] Como cambia el volumen de viajes cada mes y por tipo de taxi?
SELECT taxi_type, make_date(anio, mes, 1) AS mes, count(*) AS viajes
FROM taxi_trips
WHERE es_valido
GROUP BY ALL
ORDER BY taxi_type, mes;

-- [I2] Cual es el promedio diario de viajes por anio?
SELECT taxi_type, anio, count(*) AS viajes,
       count(DISTINCT pickup_ts::DATE) AS dias,
       round(count(*) / count(DISTINCT pickup_ts::DATE)) AS viajes_por_dia
FROM taxi_trips
WHERE es_valido
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;

-- [I3] En que hora se concentra la demanda de cada anio?
SELECT taxi_type, anio, hour(pickup_ts) AS hora, count(*) AS viajes
FROM taxi_trips
WHERE es_valido
GROUP BY ALL
ORDER BY taxi_type, anio, hora;

-- [I4] Como cambia la distancia del viaje tipico?
SELECT taxi_type, anio,
       round(median(trip_distance), 2) AS distancia_mediana,
       round(quantile_cont(trip_distance, 0.95), 2) AS distancia_p95
FROM taxi_trips
WHERE es_valido AND trip_distance BETWEEN 0.01 AND 100
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;

-- [I5] Como evolucionan la tarifa y el monto total promedio?
SELECT taxi_type, anio,
       round(avg(fare_amount), 2) AS tarifa_promedio,
       round(avg(total_amount), 2) AS total_promedio
FROM taxi_trips
WHERE es_valido
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;

-- [I6] Que formas de pago predominan y como cambian por anio?
SELECT taxi_type, anio, coalesce(payment_type, -1) AS tipo_pago,
       count(*) AS viajes,
       round(100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type, anio), 2) AS porcentaje
FROM taxi_trips
WHERE es_valido
GROUP BY taxi_type, anio, payment_type
ORDER BY taxi_type, anio, viajes DESC;

-- [I7] Cuanto se deja de propina en los viajes pagados con tarjeta?
SELECT taxi_type, anio,
       round(avg(100.0 * tip_amount / fare_amount), 2) AS propina_pct_promedio,
       round(median(100.0 * tip_amount / fare_amount), 2) AS propina_pct_mediana
FROM taxi_trips
WHERE es_valido AND payment_type = 1 AND fare_amount > 0
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;

-- [I8] Que proporcion de los registros presenta inconsistencias?
SELECT taxi_type, anio, count(*) AS registros,
       count(*) FILTER (WHERE NOT es_valido) AS inconsistentes,
       round(100.0 * count(*) FILTER (WHERE NOT es_valido) / count(*), 2) AS porcentaje
FROM taxi_trips
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;

-- [I9] Cuales son las cinco zonas de origen con mas viajes por tipo y anio?
WITH zonas AS (
    SELECT taxi_type, anio, PULocationID, count(*) AS viajes,
           row_number() OVER (PARTITION BY taxi_type, anio ORDER BY count(*) DESC) AS posicion
    FROM taxi_trips
    WHERE es_valido
    GROUP BY taxi_type, anio, PULocationID
)
SELECT taxi_type, anio, PULocationID, viajes
FROM zonas
WHERE posicion <= 5
ORDER BY taxi_type, anio, viajes DESC;

-- [I10] Como cambia el volumen entre anios usando el mismo periodo enero-agosto?
SELECT taxi_type, anio, count(*) AS viajes_enero_agosto,
       round(count(*) / count(DISTINCT pickup_ts::DATE)) AS viajes_por_dia
FROM taxi_trips
WHERE es_valido AND mes BETWEEN 1 AND 8
GROUP BY taxi_type, anio
ORDER BY taxi_type, anio;
