# Ejercicios 1 y 2: ambiente y descarga

## Estructura del proyecto

- `data/raw/`: archivos Parquet tal como los publica la TLC, sin tocar. Es la fuente de verdad y se puede volver a bajar.
- `data/processed/`: lo que se derive de los datos crudos (por ejemplo la base `.duckdb` materializada del ejercicio 6).
- `notebooks/`: los notebooks de exploracion, analisis e indicadores.
- `scripts/`: codigo que se ejecuta de principio a fin sin intervencion (descarga, benchmarks).
- `sql/`: las consultas, en archivos `.sql` versionados.
- `docs/`: documentacion de consultas, resultados y decisiones.
- `Dockerfile`, `metabase.Dockerfile`, `docker-compose.yml`: definen el ambiente completo.

`data/raw` y `data/processed` estan en el `.gitignore`, solo se versiona el `.gitkeep`.

## Ejercicio 1

**1.4 Herramientas del ambiente.** El contenedor `lab` trae Python 3.11, JupyterLab, DuckDB 1.5.5, pandas, pyarrow, matplotlib y requests, ademas de `curl`. El contenedor `metabase` trae Metabase con el driver de DuckDB, que es la herramienta de visualizacion para el ejercicio 7.

**1.6 Por que un ambiente reproducible.** Un analisis que solo corre en la maquina de quien lo hizo no se puede verificar ni retomar. Con Docker, cualquiera que clone el repositorio obtiene las mismas versiones de Python, DuckDB y librerias, asi que un resultado distinto no se puede atribuir a diferencias de instalacion. Esto importa mas con DuckDB y Metabase, porque el driver tiene que coincidir con la version de DuckDB y fijarlas en un solo lugar evita ese problema. Tambien nos quita el "en mi computadora funciona" al momento de entregar.

## Ejercicio 2

**2.1 Que habia que modificar.** El script original tenia el anio (`ANIO = 2026`) fijo en tres funciones, asi que no se podia usar para otro anio sin editar el codigo. Tampoco tenia forma de comprobar si la descarga estaba completa.

**2.6 Cambios realizados.**

- El anio paso a ser parametro: `--years` acepta uno o varios anios (por defecto 2026, que es lo que pide el ejercicio 2). Para los ejercicios 5 y 8 solo se cambia el comando, no el codigo.
- `construir_nombre`, `construir_url` y `ruta_destino` reciben el anio.
- Se agrego `--verify`, que compara cada archivo local con el `Content-Length` que devuelve el servidor y lista faltantes o archivos de tamano distinto.
- Se mantuvo lo que ya hacia bien: preguntar al servidor que meses estan publicados, omitir archivos existentes y descargar a un `.part` que se renombra al terminar.

**2.7 Como saber que esta completo.** Se ejecuta `--verify`. Cada mes publicado debe tener su archivo local con el mismo tamano que reporta el servidor, y los meses que aparecen como "no publicado" deben ser los ultimos del anio, que la TLC todavia no sube. Despues se confirma con DuckDB que el conteo de archivos (consulta 3.1) coincide, y que la suma de filas en los metadatos (3.2a) coincide con el conteo real (3.2b).
