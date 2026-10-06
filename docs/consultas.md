# Documentacion de consultas

Para cada consulta: objetivo, fuente, resultado y decision. La consulta SQL esta en el archivo indicado (la etiqueta entre corchetes es el comentario que la identifica). Los resultados se llenan despues de ejecutar `scripts/run_sql.py` sobre los datos reales.

Fuente de todas: `data/raw/yellow/*/*.parquet` y `data/raw/green/*/*.parquet`, a traves de las vistas de `sql/00_vistas.sql`.

## Ejercicio 3 (`sql/03_exploracion.sql`)

Salida completa de la ejecucion en `docs/salida_ej3.txt`.

| Consulta | Objetivo | Resultado | Decision |
|---|---|---|---|
| [3.1] | Contar archivos por tipo y anio | 8 archivos yellow y 8 green, todos de 2026 (enero a agosto) | Coincide con lo descargado, la descarga esta completa |
| [3.2a] | Contar registros desde los metadatos Parquet | yellow 29,703,355 y green 337,114 | La consulta tardo 0.06 s porque no lee datos |
| [3.2b] | Contar registros por archivo | yellow entre 3.34 M y 4.09 M por mes, green entre 37 mil y 45 mil | Suma igual a 3.2a, los conteos son consistentes |
| [3.3 y 3.4] | Columnas y tipos | Yellow tiene 21 columnas y green 22. Comparten 18 (fechas, ubicaciones, tarifas, pago). Yellow agrega `Airport_fee`, green agrega `ehail_fee` y `trip_type`. Ambos traen `cbd_congestion_fee` y `request_source` | `trips` usa solo las columnas comunes. Las fechas se llaman `tpep_*` en yellow y `lpep_*` en green |
| [3.5] | Muestra de 10 filas por tipo | Filas con aspecto normal. En green `ehail_fee` sale vacio | |
| [3.6a] | `SUMMARIZE` por columna | Ver problemas abajo. `SUMMARIZE` de yellow tardo 12 s por ser 29.7 M de filas | |
| [3.6b] | Conteo de problemas de calidad | Ver tabla abajo | Filtros para `trips_limpios` |
| [3.6c] | Mes real de las fechas de pickup | Hay fechas de 2001, 2008, 2009 y diciembre de 2025 dentro de los archivos de 2026 | Excluir lo que no cae en el mes del archivo |
| [3.6d] | Valores de `request_source` | Nulo en 90.2 % de yellow y 94.3 % de green. Los valores son `HV0003` (2.3 M en yellow), `A`, `HV0005`, `EH0004`, `CC` y `EH0010` | Segun el esquema de Parquet (consulta 5.7), la columna solo existe en 3 de los 8 archivos de 2026 de cada tipo, asi que buena parte de los nulos son meses donde la columna no venia. No se usa en los indicadores. Falta confirmar el significado de cada codigo en el diccionario de datos de la TLC |
| [3.6e] | Nulos de `passenger_count` por mes | Yellow entre 20.9 % (abril) y 30.1 % (febrero), green entre 12.8 % y 15.6 %. Pasa en todos los meses | No es un archivo danado. No se descartan esas filas, solo se excluyen al calcular promedios de pasajeros |
| [3.6f] | Viajes con distancia cero: tarifa y duracion | _pendiente de ejecutar_ | Decidir si se descartan o se tratan aparte |

### Problemas de calidad encontrados (3.6)

| Problema | Yellow | Green |
|---|---|---|
| Total de viajes | 29,703,355 | 337,114 |
| `passenger_count` nulo | 7,716,688 (26.0 %) | 48,775 (14.5 %) |
| `passenger_count` igual a 0 | 91,359 | 4,527 |
| Distancia menor o igual a 0 | 952,231 (3.2 %) | 12,212 (3.6 %) |
| Tarifa negativa | 157,364 (0.5 %) | 999 (0.3 %) |
| Total menor o igual a 0 | 167,093 (0.6 %) | 1,566 (0.5 %) |
| Bajada antes de la subida | 10 | 5 |
| Duracion mayor a 24 horas | 254 | 4 |
| Fuera del mes de su archivo | 146 | 98 |

Otros puntos que salen de `SUMMARIZE`:

- Las fechas de pickup llegan hasta 2001 en yellow y 2008 en green. De los 146 viajes de yellow fuera de mes, solo 17 son de otros anios, los demas son de 2026 pero estan en el archivo de otro mes. En green pasa igual (14 de otros anios sobre 98).
- La distancia maxima es de 328,522 millas en yellow y 179,830 en green, y el promedio de yellow (5.55) esta inflado por esas colas, con desviacion estandar de 550. Para describir viajes tipicos conviene la mediana.
- Hay tarifas de -2,555 y de 7,045 dolares en yellow. La propina minima es -222 y la maxima 766.
- `ehail_fee` en green no tiene ningun valor, es una columna vacia.
- `RatecodeID` llega a 99 y el promedio en yellow (4.5) sugiere que ese valor es frecuente. Falta confirmarlo con una consulta antes de descartar o recodificar.
- En yellow hay `payment_type` igual a 0, que no existe en green.

### 3.9 Que significa consultar directo un Parquet

Consultar directo significa que DuckDB lee el archivo en el momento de la consulta, sin importarlo antes a una tabla ni cargar nada en memoria de antemano. Parquet guarda los datos por columnas, comprimidos, y con estadisticas (minimo y maximo) por bloque. Por eso DuckDB lee solo las columnas que la consulta usa y se salta los bloques que no le sirven. Con mucho volumen esto permite explorar rapido, sin pagar el costo de cargar todo, y agregar un archivo nuevo a la carpeta basta para que entre en las consultas.

## Ejercicio 4 (`sql/04_eda.sql`)

| Pregunta | Consulta | Justificacion |
|---|---|---|
| Como evoluciona el volumen mes a mes | [Q1] | Comportamiento temporal basico y base para comparar anios |
| En que horas se concentra la demanda | [Q2] | Los viajes de taxi tienen un patron diario claro |
| Hay diferencia entre dias de la semana | [Q3] | Separar habiles de fin de semana |
| Como es un viaje tipico | [Q4], [Q5] | Distancia, duracion y pasajeros, usando mediana ademas del promedio por las colas largas |
| Que diferencia hay entre yellow y green | [Q6] | Tarifa, propina y tarifa por milla |
| Como se paga y cuanto se propina | [Q7], [Q8] | La propina solo se registra con tarjeta, por eso se filtra |
| Que valores son atipicos o inconsistentes | [Q9], [Q10] | Percentil 99 contra maximo, velocidades imposibles |

Resultados e interpretacion: _pendiente de ejecutar sobre los datos reales_.

### Hallazgos relevantes (4.5)

1. _pendiente_
2. _pendiente_
3. _pendiente_
