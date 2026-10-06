#!/usr/bin/env python3
"""Ejecuta uno o varios archivos .sql con DuckDB e imprime cada resultado.

Uso (dentro del contenedor, desde /workspace):
    python scripts/run_sql.py sql/00_vistas.sql sql/03_exploracion.sql
    python scripts/run_sql.py --db data/processed/taxi.duckdb sql/00_vistas.sql sql/04_eda.sql

Todos los archivos corren en la misma conexion, asi que las vistas creadas en
00_vistas.sql quedan disponibles para los siguientes. Cada sentencia se
imprime junto con su tiempo de ejecucion. Los comentarios de los archivos no
deben contener punto y coma, porque las sentencias se separan por ';'.
"""

import argparse
import time
from pathlib import Path

import duckdb
import pandas as pd

pd.set_option("display.width", 200)
pd.set_option("display.max_columns", 50)
pd.set_option("display.max_rows", 100)


def sentencias(texto: str):
    for bloque in texto.split(";"):
        # se ignoran bloques que solo tienen comentarios o espacios
        util = [l for l in bloque.splitlines() if l.strip() and not l.strip().startswith("--")]
        if util:
            yield bloque.strip()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("archivos", nargs="+", type=Path)
    parser.add_argument("--db", default=":memory:", help="base DuckDB (por defecto en memoria)")
    args = parser.parse_args()

    con = duckdb.connect(args.db)
    for archivo in args.archivos:
        print(f"\n##### {archivo} #####")
        for sql in sentencias(archivo.read_text(encoding="utf-8")):
            print("\n" + "-" * 70)
            print(sql)
            inicio = time.perf_counter()
            cursor = con.execute(sql)
            if cursor.description is not None:
                df = cursor.fetchdf()
                dur = time.perf_counter() - inicio
                print(f"\n{df.to_string(index=False)}")
            else:
                dur = time.perf_counter() - inicio
            print(f"\n[{dur:.3f} s]")


if __name__ == "__main__":
    main()
