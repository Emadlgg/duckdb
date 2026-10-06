# Documentacion de consultas

Para cada consulta: objetivo, fuente, resultado y decision. La consulta SQL esta en el archivo indicado (la etiqueta entre corchetes es el comentario que la identifica). Los resultados se llenan despues de ejecutar `scripts/run_sql.py` sobre los datos reales.

Fuente de todas: `data/raw/yellow/*/*.parquet` y `data/raw/green/*/*.parquet`, a traves de las vistas de `sql/00_vistas.sql`.

## Ejercicio 3 (`sql/03_exploracion.sql`)

| Consulta | Objetivo | Resultado | Decision |
|---|---|---|---|
| [3.1] | Contar archivos por tipo y anio | _pendiente_ | Confirmar que coincide con lo descargado |
| [3.2a] | Contar registros desde los metadatos Parquet | _pendiente_ | |
| [3.2b] | Contar registros por archivo | _pendiente_ | Debe coincidir con 3.2a |
| [3.3 y 3.4] | Columnas y tipos de yellow y green | _pendiente_ | Decidir que columnas comparten para `trips` |
| [3.5] | Muestra de 10 filas por tipo | _pendiente_ | |
| [3.6a] | `SUMMARIZE`: min, max, nulos por columna | _pendiente_ | |
| [3.6b] | Conteo de problemas de calidad | _pendiente_ | Definir filtros de `trips_limpios` |
| [3.6c] | Meses reales de las fechas de pickup | _pendiente_ | Ver si hay viajes fuera del mes del archivo |

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
