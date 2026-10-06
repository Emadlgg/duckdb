# Lab 8 - DuckDB

## Integrantes

Osman de Leon
Milton Polanco

Repositorio base del laboratorio 8 del curso **CC3084 - Data Science**
(Universidad del Valle de Guatemala, Ciclo 2, 2026).

Este fork contiene el flujo completo del laboratorio: descarga incremental,
consultas directas a Parquet, analisis exploratorio, tabla materializada,
benchmark y tablero de indicadores para 2024, 2025 y 2026.

## Trabajo con fork

El laboratorio se desarrolla y se entrega sobre un **fork** de este repositorio.
No se trabaja directamente sobre el repositorio del docente.

1. Realice un fork de este repositorio:
   <https://github.com/menene/duckdb>

2. Clone **su propio fork** (no el del docente):

   ```bash
   git clone https://github.com/Emadlgg/duckdb.git
   cd duckdb
   ```

3. Opcional, para recibir correcciones publicadas por el docente:

   ```bash
   git remote add upstream https://github.com/menene/duckdb.git
   git fetch upstream
   ```

Realice commits frecuentes y descriptivos: el historial del repositorio es parte
de la evaluacion. **La entrega del laboratorio es la URL de su fork.**

## Estructura

```text
duckdb/
|
+-- data/
|   +-- raw/
|   +-- processed/
|
+-- notebooks/
|
+-- scripts/
|
+-- sql/
|
+-- docs/
|
+-- Dockerfile
+-- metabase.Dockerfile
+-- docker-compose.yml
+-- README.md
```

## Requisitos

- Docker, con Docker Compose
- Git

La primera construccion del ambiente descarga varios cientos de MB y puede
tardar algunos minutos.

Considere el espacio en disco: las imagenes de Docker ocupan unos 3 GB y los
datos de los tres anios del laboratorio superan 1.5 GB, a los que se suma la
base materializada del Ejercicio 6. Se recomienda tener al menos 10 GB libres.

## Datos

El repositorio incluye `scripts/download_data.py`, que descarga los archivos de
yellow y green de los anios solicitados (`--help` muestra las opciones). Los
archivos se guardan en `data/raw/<tipo>/<anio>/`.

La TLC publica cada mes con varias semanas de atraso, por lo que los ultimos
meses de 2026 todavia no existen. El script consulta al servidor que meses estan
publicados, de modo que vuelve a ejecutarse sin problema conforme aparezcan
nuevos archivos.

Los datos descargados **no deben incluirse en el repositorio Git**. El archivo
`.gitignore` ya esta configurado para evitarlo.

Fuente de datos: NYC TLC Trip Record Data
<https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page>

Dentro de los contenedores, la carpeta `data/` del proyecto esta montada en
`/workspace/data`. Esa es la ruta que deben usar las herramientas que corren
dentro del ambiente, no la ruta de su computadora.

> **Nota sobre DuckDB:** un archivo `.duckdb` admite un solo proceso con permiso
> de escritura a la vez. Si conecta una herramienta externa a su base de datos,
> use el modo de solo lectura (`read_only`) en esa conexion; de lo contrario los
> demas procesos no podran abrir el archivo.

## Material a entregar

Al finalizar, su fork debe contener:

- el codigo fuente modificado y los scripts de descarga;
- las consultas SQL desarrolladas;
- el notebook o notebooks utilizados;
- la documentacion de las consultas;
- los scripts utilizados para los benchmarks;
- el codigo de los indicadores y visualizaciones;
- el tablero o la evidencia del tablero desarrollado;
- este `README.md`, con las instrucciones para reproducir el trabajo.

Los archivos de datos descargados **no** deben incluirse.

---

# Documentacion del equipo

Las siguientes secciones permiten que una persona que no participo en el
desarrollo pueda levantar el ambiente, descargar los datos, ejecutar el analisis,
reproducir los benchmarks y generar los resultados principales.

## Como levantar el ambiente

Requisitos: Docker con Docker Compose y Git.

```bash
git clone https://github.com/Emadlgg/duckdb.git
cd duckdb
docker compose up --build -d
```

La primera vez tarda varios minutos porque construye dos imagenes: `lab`
(Python 3.11, JupyterLab, DuckDB, pandas, pyarrow, matplotlib, requests) y
`metabase` (Metabase con el driver de DuckDB). Para comprobar que todo quedo
arriba:

```bash
docker compose ps                                              # los dos servicios en "running"
docker compose exec lab python -c "import duckdb; print(duckdb.__version__)"
curl -s http://localhost:3000/api/health                       # {"status":"ok"}
```

- JupyterLab: <http://localhost:8888> (sin token ni contrasena)
- Metabase: <http://localhost:3000> (la primera vez pide crear un usuario)

Para apagarlo: `docker compose down`. Los datos y los notebooks viven en carpetas
del proyecto montadas dentro del contenedor, asi que no se pierden al apagarlo.
Todos los comandos de abajo se ejecutan dentro del contenedor `lab`, con
`docker compose exec lab <comando>`.

## Como descargar los datos

```bash
docker compose exec lab python scripts/download_data.py                      # 2026 (por defecto)
docker compose exec lab python scripts/download_data.py --years 2024 2026    # Ejercicio 5
docker compose exec lab python scripts/download_data.py --years 2024 2025 2026   # Ejercicio 8
docker compose exec lab python scripts/download_data.py --verify --years 2024 2025 2026
```

Los archivos quedan en `data/raw/<tipo>/<anio>/`. El script no vuelve a bajar
un archivo que ya existe, y `--verify` compara cada archivo local contra el
tamano que reporta el servidor para confirmar que la descarga esta completa.
Los cambios hechos al script estan en `docs/ejercicios_1_2.md`.

Al 6 de octubre de 2026 se esperan 64 archivos: 24 de 2024, 24 de 2025 y
16 de 2026, porque la TLC ha publicado enero-agosto. `--verify` distingue los
meses no publicados de errores de red o del servidor.

## Como ejecutar el analisis

Las consultas estan en `sql/` y se ejecutan en orden dentro del contenedor:

```bash
docker compose exec lab python scripts/run_sql.py sql/00_vistas.sql sql/03_exploracion.sql
docker compose exec lab python scripts/run_sql.py sql/00_vistas.sql sql/04_eda.sql
docker compose exec lab python scripts/run_sql.py sql/00_vistas.sql sql/05_incorporacion.sql
```

`00_vistas.sql` crea las vistas sobre los Parquet (`data/raw/*/*/*.parquet`),
por lo que al descargar anios nuevos las consultas los toman sin cambios. La
documentacion de cada consulta esta en `docs/consultas.md`.

## Como reproducir los benchmarks

Primero se crea la tabla materializada. La base queda en `data/processed/` y no
se versiona:

```bash
docker compose exec lab python scripts/run_sql.py --db data/processed/taxi.duckdb sql/00_vistas.sql sql/06_materializacion.sql
docker compose exec lab python scripts/benchmark.py
```

El benchmark hace una ejecucion de calentamiento y tres mediciones por caso,
comprueba que Parquet y tabla den el mismo resultado y guarda la tabla en
`docs/benchmark_resultados.csv`. La metodologia e interpretacion estan en
`docs/benchmark.md`.

## Como generar los resultados principales

Con la tabla creada:

```bash
docker compose exec lab python scripts/run_sql.py --read-only --db data/processed/taxi.duckdb sql/07_indicadores.sql
docker compose exec lab python scripts/run_sql.py --read-only --db data/processed/taxi.duckdb sql/08_analisis_completo.sql
```

El notebook `notebooks/resumen_indicadores.ipynb` reproduce un resumen grafico
desde JupyterLab. Las salidas detalladas estan en `docs/salida_ej7.txt` y
`docs/salida_ej8.txt`.

### Tablero de Metabase

1. Abra <http://localhost:3000> y cree el usuario administrador la primera vez.
2. Ejecute el constructor indicando ese correo y contrasena. El script crea la
   conexion DuckDB de solo lectura, diez preguntas y el tablero:

   ```bash
   docker compose exec -e METABASE_EMAIL=correo-usado -e METABASE_PASSWORD=contrasena-usada lab python scripts/create_dashboard.py
   ```

3. Abra la coleccion `Lab 8 - DuckDB` y el tablero `NYC Taxi: 2024-2026`.

La contrasena solo se pasa al proceso y no se guarda en el repositorio. La
evidencia exportada del tablero esta en `output/pdf/tablero_metabase.pdf`.

## Documentacion de resultados

- Ejercicios 1 y 2: `docs/ejercicios_1_2.md`.
- Ejercicio 3: `docs/consultas.md` y `docs/salida_ej3.txt`.
- Ejercicio 4: `docs/analisis_exploratorio.md`.
- Ejercicio 5: `docs/incorporacion_2024.md`.
- Ejercicio 6: `docs/benchmark.md`.
- Ejercicio 7: `docs/indicadores.md`.
- Ejercicio 8: `docs/analisis_2024_2026.md`.
- Ejercicio 9: `docs/discusion.md`.
