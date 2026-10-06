# Ejercicio 6: Parquet versus tabla DuckDB

## Materializacion

La tabla se crea con `sql/06_materializacion.sql` dentro de
`data/processed/taxi.duckdb`. Conserva las 121,184,384 filas de los 64 Parquet y
agrega el anio, el mes, la duracion y una bandera de validez. La creacion tomo
40.1 segundos. Los Parquet ocupan 1.93 GiB y la base DuckDB 3.42 GiB.

La comprobacion posterior dio el mismo conteo en ambos lados:

| Fuente | Filas |
|---|---:|
| Metadatos Parquet | 121,184,384 |
| `taxi_trips` | 121,184,384 |

## Metodo del benchmark

`scripts/benchmark.py` compara cuatro consultas, documentadas tambien en
`sql/06_benchmark.sql`: conteo por tipo, resumen
mensual, formas de pago y percentiles. Se probaron tres volumenes:

- un mes: enero de 2026;
- un anio: 2025 completo;
- conjunto completo: 2024, 2025 y enero-agosto de 2026.

Cada caso tiene una ejecucion de calentamiento y tres ejecuciones medidas. Se
reporta la mediana. El orden Parquet/tabla se alterna y el programa comprueba
que ambas estrategias devuelvan exactamente el mismo resultado. Para los
volumenes parciales el filtro usa `source_file`, lo que permite descartar los
Parquet que no pertenecen al periodo antes de leerlos.

## Resultados

| Volumen | Consulta | Parquet (s) | Tabla (s) | Factor a favor de tabla |
|---|---|---:|---:|---:|
| 1 mes | Conteo por tipo | 0.3733 | 0.0192 | 19.45x |
| 1 mes | Resumen mensual | 0.7756 | 0.0312 | 24.89x |
| 1 mes | Formas de pago | 0.7039 | 0.0319 | 22.09x |
| 1 mes | Percentiles | 0.9787 | 0.2581 | 3.79x |
| 1 anio | Conteo por tipo | 0.4083 | 0.0323 | 12.64x |
| 1 anio | Resumen mensual | 1.3491 | 0.1252 | 10.77x |
| 1 anio | Formas de pago | 1.8419 | 0.0883 | 20.86x |
| 1 anio | Percentiles | 4.7660 | 2.8945 | 1.65x |
| Completo | Conteo por tipo | 0.4103 | 0.0325 | 12.63x |
| Completo | Resumen mensual | 4.5523 | 0.2386 | 19.08x |
| Completo | Formas de pago | 4.5953 | 0.1904 | 24.14x |
| Completo | Percentiles | 13.6221 | 8.9068 | 1.53x |

La salida completa esta en `docs/salida_ej6_benchmark.txt` y la tabla en
`docs/benchmark_resultados.csv`.

## Interpretacion

La tabla fue mas rapida en los doce casos. La mayor diferencia aparece en
agregaciones repetidas, porque DuckDB ya tiene los datos en su almacenamiento y
puede aprovechar sus estadisticas internas. En los percentiles la ventaja baja
al crecer el volumen: calcular la distribucion domina una parte mayor del tiempo
y ambas estrategias tienen que procesar muchos valores.

Esto no vuelve innecesario a Parquet. Consultarlo directamente evita los 40
segundos de carga inicial, usa menos espacio y permite incorporar un archivo con
solo copiarlo a la carpeta. Es la mejor opcion para exploracion, intercambiar
datos y consultas ocasionales. La tabla conviene para el tablero y consultas que
se repiten muchas veces. En este proyecto se conservan las dos: Parquet como
fuente y `taxi_trips` como capa de consulta.
