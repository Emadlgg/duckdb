#!/usr/bin/env python3
"""Compara consultas directas a Parquet contra la tabla DuckDB materializada."""

import argparse
import csv
import statistics
import time
from pathlib import Path

import duckdb


CONSULTAS = {
    "conteo_tipo": """
        SELECT taxi_type, count(*) AS viajes
        FROM {fuente}
        WHERE {filtro}
        GROUP BY taxi_type
        ORDER BY taxi_type
    """,
    "resumen_mensual": """
        SELECT taxi_type, anio, mes,
               count(*) FILTER (WHERE es_valido) AS viajes_validos,
               round(avg(fare_amount) FILTER (WHERE es_valido), 2) AS tarifa_promedio,
               round(avg(total_amount) FILTER (WHERE es_valido), 2) AS total_promedio
        FROM {fuente}
        WHERE {filtro}
        GROUP BY taxi_type, anio, mes
        ORDER BY taxi_type, anio, mes
    """,
    "formas_pago": """
        SELECT taxi_type, payment_type, count(*) AS viajes
        FROM {fuente}
        WHERE {filtro} AND es_valido
        GROUP BY taxi_type, payment_type
        ORDER BY taxi_type, payment_type NULLS FIRST
    """,
    "percentiles": """
        SELECT taxi_type,
               round(median(trip_distance) FILTER
                     (WHERE es_valido AND trip_distance BETWEEN 0.01 AND 100), 2) AS distancia_mediana,
               round(quantile_cont(total_amount, 0.95) FILTER (WHERE es_valido), 2) AS total_p95,
               round(quantile_cont(duracion_min, 0.95) FILTER (WHERE es_valido), 2) AS duracion_p95
        FROM {fuente}
        WHERE {filtro}
        GROUP BY taxi_type
        ORDER BY taxi_type
    """,
}

VOLUMENES = {
    # Filtrar tambien por el nombre permite que DuckDB descarte los Parquet que
    # no pertenecen al volumen medido antes de leerlos.
    "1_mes": "source_file LIKE '%/2026/%_2026-01.parquet'",
    "1_anio": "source_file LIKE '%/2025/%'",
    "completo": "TRUE",
}


def preparar_fuentes(con: duckdb.DuckDBPyConnection) -> None:
    """Crea dos vistas con el mismo esquema para que solo cambie el almacenamiento."""
    con.execute("""
        CREATE OR REPLACE TEMP VIEW bench_parquet AS
        SELECT taxi_type,
               filename AS source_file,
               CAST(regexp_extract(filename, '/(\\d{4})/', 1) AS SMALLINT) AS anio,
               CAST(regexp_extract(filename, '(\\d{2})\\.parquet$', 1) AS TINYINT) AS mes,
               pickup_ts, dropoff_ts, passenger_count, trip_distance,
               PULocationID, DOLocationID, payment_type, fare_amount,
               tip_amount, tolls_amount, total_amount,
               date_diff('second', pickup_ts, dropoff_ts) / 60.0 AS duracion_min,
               strftime(pickup_ts, '%Y-%m') = regexp_extract(filename, '(\\d{4}-\\d{2})\\.parquet$', 1)
                   AND dropoff_ts >= pickup_ts
                   AND dropoff_ts - pickup_ts <= INTERVAL 24 HOUR
                   AND fare_amount >= 0
                   AND total_amount > 0 AS es_valido
        FROM trips
    """)
    con.execute("CREATE OR REPLACE TEMP VIEW bench_table AS SELECT * FROM taxi_trips")


def medir(con: duckdb.DuckDBPyConnection, sql: str, repeticiones: int) -> tuple[float, list]:
    """Calienta una vez y devuelve la mediana de varias ejecuciones."""
    esperado = con.execute(sql).fetchall()
    tiempos = []
    for _ in range(repeticiones):
        inicio = time.perf_counter()
        resultado = con.execute(sql).fetchall()
        tiempos.append(time.perf_counter() - inicio)
        if resultado != esperado:
            raise RuntimeError("la misma consulta produjo resultados distintos entre repeticiones")
    return statistics.median(tiempos), esperado


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--db", type=Path, default=Path("data/processed/taxi.duckdb"))
    parser.add_argument("--output", type=Path, default=Path("docs/benchmark_resultados.csv"))
    parser.add_argument("--repeticiones", type=int, default=3)
    args = parser.parse_args()
    if args.repeticiones < 1:
        parser.error("--repeticiones debe ser al menos 1")

    con = duckdb.connect(str(args.db), read_only=True)
    preparar_fuentes(con)
    filas_tabla = con.execute("SELECT count(*) FROM taxi_trips").fetchone()[0]
    filas_parquet = con.execute(
        "SELECT sum(num_rows) FROM parquet_file_metadata('/workspace/data/raw/*/*/*.parquet')"
    ).fetchone()[0]
    if filas_tabla != filas_parquet:
        raise RuntimeError(f"tabla={filas_tabla:,}, parquet={filas_parquet:,}")

    resultados = []
    print(f"Filas verificadas: {filas_tabla:,}")
    print(f"Repeticiones medidas por caso: {args.repeticiones}\n")
    for volumen, filtro in VOLUMENES.items():
        for nombre, plantilla in CONSULTAS.items():
            por_estrategia = {}
            salidas = {}
            # Alternar el orden reduce la ventaja sistematica del cache.
            orden = ("parquet", "tabla") if len(resultados) % 2 == 0 else ("tabla", "parquet")
            for estrategia in orden:
                fuente = "bench_parquet" if estrategia == "parquet" else "bench_table"
                sql = plantilla.format(fuente=fuente, filtro=filtro)
                segundos, salida = medir(con, sql, args.repeticiones)
                por_estrategia[estrategia] = segundos
                salidas[estrategia] = salida
            if salidas["parquet"] != salidas["tabla"]:
                raise RuntimeError(f"resultados no equivalentes: {volumen}/{nombre}")
            mejora = por_estrategia["parquet"] / por_estrategia["tabla"]
            fila = {
                "volumen": volumen,
                "consulta": nombre,
                "parquet_s": round(por_estrategia["parquet"], 4),
                "tabla_s": round(por_estrategia["tabla"], 4),
                "factor_tabla": round(mejora, 2),
            }
            resultados.append(fila)
            print(
                f"{volumen:8} | {nombre:16} | parquet {fila['parquet_s']:>7.4f} s | "
                f"tabla {fila['tabla_s']:>7.4f} s | factor {fila['factor_tabla']:>5.2f}x"
            )

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="", encoding="utf-8") as archivo:
        escritor = csv.DictWriter(archivo, fieldnames=resultados[0].keys())
        escritor.writeheader()
        escritor.writerows(resultados)
    print(f"\nResultados: {args.output}")


if __name__ == "__main__":
    main()
