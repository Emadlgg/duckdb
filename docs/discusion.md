# Ejercicio 9: discusion

## 9.1 Caracteristicas de DuckDB mas utiles

La mas util fue consultar varios Parquet con un comodin sin cargarlos antes.
Tambien ayudaron `union_by_name`, las funciones sobre metadatos Parquet, las
ventanas, cuantiles y la posibilidad de guardar una tabla en el mismo motor sin
cambiar de SQL. Al ser embebido, el analisis corre desde Python y Metabase sin
mantener un servidor de base de datos separado.

## 9.2 Ventajas y limitaciones de consultar Parquet

Parquet ocupa menos espacio, se puede compartir con otras herramientas y deja
incorporar un mes nuevo copiando un archivo. DuckDB lee solo las columnas
necesarias y puede descartar archivos o grupos de filas usando sus estadisticas.
La desventaja es que cada consulta vuelve a abrir archivos y resolver esquemas.
Las agregaciones repetidas fueron entre 10 y 24 veces mas lentas que sobre la
tabla en este benchmark. Tambien hay que manejar cambios de nombres o tipos
entre anios.

## 9.3 Ventajas y limitaciones de la tabla materializada

La tabla acelera el tablero y deja precalculadas columnas como anio, mes,
duracion y validez. Tambien ofrece un esquema estable para Metabase. A cambio,
ocupa 3.42 GB adicionales y tardo 40 segundos en crearse. Cuando llega un
archivo nuevo hay que actualizarla o volverla a construir, mientras la vista
Parquet lo incorpora automaticamente.

## 9.4 Diferencia frente a cargar todo con Pandas

Pandas normalmente materializa el conjunto en memoria y 121 millones de filas
no caben comodamente en una computadora comun. DuckDB ejecuta filtros y
agregaciones de forma vectorizada y solo entrega a Python el resultado pequeno.
Eso reduce memoria, evita copias innecesarias y deja la transformacion expresada
en SQL reproducible.

## 9.5 Incorporacion de nuevos datos

El anio es un argumento del descargador, las carpetas siguen una convencion
estable y las vistas usan comodines. `union_by_name` tolera columnas nuevas y el
nombre del archivo conserva el anio y mes de procedencia. Por eso 2024 y 2025 se
incorporaron sin reescribir las consultas de los ejercicios 3 y 4.

## 9.6 Que automatizaria en produccion

Programaria la deteccion de meses nuevos, la descarga, validacion de tamano y
esquema, pruebas de calidad, actualizacion incremental de la tabla y refresco
del tablero. Tambien guardaria un manifiesto con URL, fecha, tamano y checksum
de cada archivo, y enviaria una alerta si cambia un archivo ya procesado.

## 9.7 Decisiones para mantener reproducibilidad

Se fijaron versiones en `requirements.txt`, el ambiente se definio con Docker,
los datos quedaron fuera de Git y todas las consultas viven en `sql/`. Las
salidas importantes se guardaron en `docs/`, el descargador es idempotente y el
tablero puede reconstruirse con un script. Tambien se separaron datos crudos,
datos procesados y documentacion.

## 9.8 Aprendizaje que no se ve con datos pequenos

Un porcentaje pequeno puede representar millones de filas y unos pocos valores
extremos pueden cambiar mucho un promedio. Con este volumen fue necesario usar
medianas, percentiles y filtros justificados. Tambien se hizo visible el costo
de releer archivos: una consulta aislada sobre Parquet es practica, pero un
tablero que repite agregaciones se beneficia bastante de materializar una
tabla. Finalmente, los nulos no siempre son errores aleatorios; en este caso
identifican una forma distinta de registrar viajes Flex Fare.
