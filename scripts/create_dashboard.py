#!/usr/bin/env python3
"""Crea o actualiza en Metabase el tablero del Ejercicio 7."""

import argparse
import os

import requests


PREGUNTAS = [
    {
        "name": "1a. Viajes por mes - yellow",
        "description": "Evolucion mensual del volumen valido de yellow. Se grafica por separado porque yellow tiene unas cien veces mas viajes que green.",
        "display": "line",
        "sql": """SELECT make_date(anio, mes, 1) AS mes, count(*) AS viajes
                  FROM taxi_trips WHERE es_valido AND taxi_type = 'yellow'
                  GROUP BY ALL ORDER BY mes""",
        "settings": {"graph.dimensions": ["mes"], "graph.metrics": ["viajes"]},
    },
    {
        "name": "1b. Viajes por mes - green",
        "description": "Evolucion mensual del volumen valido de green, con su propia escala para que se vea su tendencia y estacionalidad.",
        "display": "line",
        "sql": """SELECT make_date(anio, mes, 1) AS mes, count(*) AS viajes
                  FROM taxi_trips WHERE es_valido AND taxi_type = 'green'
                  GROUP BY ALL ORDER BY mes""",
        "settings": {"graph.dimensions": ["mes"], "graph.metrics": ["viajes"]},
    },
    {
        "name": "2a. Viajes diarios por año - yellow",
        "description": "Promedio diario de viajes validos de yellow. 2026 incluye solo enero-agosto, el promedio por dia compensa la diferencia.",
        "display": "bar",
        "sql": """SELECT anio::VARCHAR AS anio,
                         round(count(*) / count(DISTINCT pickup_ts::DATE)) AS viajes_por_dia
                  FROM taxi_trips WHERE es_valido AND taxi_type = 'yellow'
                  GROUP BY ALL ORDER BY anio""",
        "settings": {"graph.dimensions": ["anio"], "graph.metrics": ["viajes_por_dia"]},
    },
    {
        "name": "2b. Viajes diarios por año - green",
        "description": "Promedio diario de viajes validos de green, en su propia escala. 2026 incluye solo enero-agosto.",
        "display": "bar",
        "sql": """SELECT anio::VARCHAR AS anio,
                         round(count(*) / count(DISTINCT pickup_ts::DATE)) AS viajes_por_dia
                  FROM taxi_trips WHERE es_valido AND taxi_type = 'green'
                  GROUP BY ALL ORDER BY anio""",
        "settings": {"graph.dimensions": ["anio"], "graph.metrics": ["viajes_por_dia"]},
    },
    {
        "name": "3. Demanda por hora",
        "description": "Porcentaje de los viajes diarios que ocurre en cada hora, por tipo y año.",
        "display": "line",
        "sql": """WITH horas AS (
                      SELECT hour(pickup_ts) AS hora, taxi_type, anio, count(*) AS viajes
                      FROM taxi_trips WHERE es_valido GROUP BY ALL
                  )
                  SELECT hora, taxi_type || ' ' || anio AS serie,
                         round(100.0 * viajes / sum(viajes) OVER (PARTITION BY taxi_type, anio), 2) AS porcentaje
                  FROM horas ORDER BY hora, serie""",
        "settings": {
            "graph.dimensions": ["hora", "serie"], "graph.metrics": ["porcentaje"],
            "graph.y_axis.title_text": "Porcentaje de viajes",
        },
    },
    {
        "name": "4. Distancia del viaje tipico",
        "description": "Mediana de distancia; evita que los valores extremos dominen la comparacion.",
        "display": "bar",
        "sql": """SELECT taxi_type, anio::VARCHAR AS anio, round(median(trip_distance), 2) AS distancia_mediana
                  FROM taxi_trips
                  WHERE es_valido AND trip_distance BETWEEN 0.01 AND 100
                  GROUP BY ALL ORDER BY anio, taxi_type""",
        "settings": {"graph.dimensions": ["anio", "taxi_type"], "graph.metrics": ["distancia_mediana"]},
    },
    {
        "name": "5. Monto total promedio",
        "description": "Evolucion del monto total cobrado por viaje valido.",
        "display": "bar",
        "sql": """SELECT taxi_type, anio::VARCHAR AS anio, round(avg(total_amount), 2) AS total_promedio
                  FROM taxi_trips WHERE es_valido GROUP BY ALL ORDER BY anio, taxi_type""",
        "settings": {"graph.dimensions": ["anio", "taxi_type"], "graph.metrics": ["total_promedio"]},
    },
    {
        "name": "6. Tarjeta y Flex Fare",
        "description": "Cambio en la participacion de tarjeta y viajes Flex Fare o equivalentes sin codigo.",
        "display": "bar",
        "sql": """WITH totales AS (
                      SELECT taxi_type, anio, count(*) AS total,
                             count(*) FILTER (WHERE payment_type = 1) AS tarjeta,
                             count(*) FILTER (WHERE payment_type = 0 OR payment_type IS NULL) AS flex
                      FROM taxi_trips WHERE es_valido GROUP BY ALL
                  )
                  SELECT anio::VARCHAR AS anio, taxi_type || ' - tarjeta' AS serie,
                         round(100.0 * tarjeta / total, 2) AS porcentaje FROM totales
                  UNION ALL
                  SELECT anio::VARCHAR AS anio, taxi_type || ' - Flex Fare' AS serie,
                         round(100.0 * flex / total, 2) AS porcentaje FROM totales
                  ORDER BY anio, serie""",
        "settings": {
            "graph.dimensions": ["anio", "serie"],
            "graph.metrics": ["porcentaje"],
            "graph.y_axis.title_text": "Porcentaje",
        },
    },
    {
        "name": "7. Propina mediana con tarjeta",
        "description": "Porcentaje mediano de propina sobre tarifa en pagos con tarjeta.",
        "display": "bar",
        "sql": """SELECT taxi_type, anio::VARCHAR AS anio,
                         round(median(100.0 * tip_amount / fare_amount), 2) AS propina_pct_mediana
                  FROM taxi_trips
                  WHERE es_valido AND payment_type = 1 AND fare_amount > 0
                  GROUP BY ALL ORDER BY anio, taxi_type""",
        "settings": {"graph.dimensions": ["anio", "taxi_type"], "graph.metrics": ["propina_pct_mediana"]},
    },
    {
        "name": "8. Registros inconsistentes",
        "description": "Porcentaje que no cumple los criterios de fecha, duracion o montos validos.",
        "display": "bar",
        "sql": """SELECT taxi_type, anio::VARCHAR AS anio,
                         round(100.0 * count(*) FILTER (WHERE NOT es_valido) / count(*), 2) AS porcentaje
                  FROM taxi_trips GROUP BY ALL ORDER BY anio, taxi_type""",
        "settings": {"graph.dimensions": ["anio", "taxi_type"], "graph.metrics": ["porcentaje"]},
    },
    {
        "name": "9. Principales zonas de origen",
        "description": "Cinco zonas de recogida con mas viajes por tipo y año, como porcentaje de los viajes del mismo tipo y año. Se usa porcentaje porque 2026 solo tiene enero-agosto y porque yellow tiene mucho mas volumen que green.",
        "display": "bar",
        "sql": """WITH zonas AS (
                      SELECT taxi_type, anio, PULocationID,
                             100.0 * count(*) / sum(count(*)) OVER (PARTITION BY taxi_type, anio) AS porcentaje,
                             row_number() OVER (PARTITION BY taxi_type, anio ORDER BY count(*) DESC) AS posicion
                      FROM taxi_trips WHERE es_valido GROUP BY taxi_type, anio, PULocationID
                  )
                  SELECT 'Zona ' || PULocationID AS zona, taxi_type || ' ' || anio AS serie,
                         round(porcentaje, 2) AS porcentaje
                  FROM zonas WHERE posicion <= 5 ORDER BY porcentaje DESC""",
        "settings": {
            "graph.dimensions": ["zona", "serie"], "graph.metrics": ["porcentaje"],
            "graph.y_axis.title_text": "Porcentaje de los viajes del año",
        },
    },
    {
        "name": "10. Comparacion enero-agosto",
        "description": "Indice del volumen diario usando enero-agosto y 2024 como base 100.",
        "display": "bar",
        "sql": """WITH resumen AS (
                      SELECT taxi_type, anio,
                             count(*) / count(DISTINCT pickup_ts::DATE) AS viajes_por_dia
                      FROM taxi_trips
                      WHERE es_valido AND mes BETWEEN 1 AND 8
                      GROUP BY ALL
                  )
                  SELECT taxi_type, anio::VARCHAR AS anio,
                         round(100.0 * viajes_por_dia /
                               first_value(viajes_por_dia) OVER (PARTITION BY taxi_type ORDER BY anio), 1) AS indice_2024
                  FROM resumen ORDER BY anio, taxi_type""",
        "settings": {
            "graph.dimensions": ["anio", "taxi_type"], "graph.metrics": ["indice_2024"],
            "graph.y_axis.title_text": "Indice (2024 = 100)",
        },
    },
]


def api(session: requests.Session, metodo: str, ruta: str, **kwargs):
    respuesta = session.request(metodo, ruta, timeout=180, **kwargs)
    if not respuesta.ok:
        raise RuntimeError(f"{metodo} {ruta}: {respuesta.status_code} {respuesta.text[:500]}")
    return respuesta.json() if respuesta.content else None


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default="http://metabase:3000")
    parser.add_argument("--email", default=os.getenv("METABASE_EMAIL", "admin@lab8.local"))
    parser.add_argument("--password", default=os.getenv("METABASE_PASSWORD"))
    parser.add_argument("--database", default="NYC Taxi 2024-2026")
    parser.add_argument("--database-file", default="/workspace/data/processed/taxi.duckdb")
    args = parser.parse_args()
    if not args.password:
        parser.error("indique --password o la variable METABASE_PASSWORD")

    sesion = requests.Session()
    inicio = api(
        sesion, "POST", f"{args.url}/api/session",
        json={"username": args.email, "password": args.password},
    )
    sesion.headers["X-Metabase-Session"] = inicio["id"]

    bases = api(sesion, "GET", f"{args.url}/api/database")["data"]
    coincidencias = [base for base in bases if base["name"] == args.database]
    if not coincidencias:
        coincidencias = [api(
            sesion, "POST", f"{args.url}/api/database",
            json={
                "name": args.database,
                "engine": "duckdb",
                "details": {
                    "database_file": args.database_file,
                    "read_only": True,
                    "old_implicit_casting": True,
                    "allow_unsigned_extensions": False,
                },
                "is_full_sync": True,
                "is_on_demand": False,
                "auto_run_queries": True,
            },
        )]
    if len(coincidencias) != 1:
        raise RuntimeError(f"hay mas de una base llamada {args.database!r}")
    database_id = coincidencias[0]["id"]

    colecciones = api(sesion, "GET", f"{args.url}/api/collection")
    coleccion = next((c for c in colecciones if c["name"] == "Lab 8 - DuckDB"), None)
    if coleccion is None:
        coleccion = api(
            sesion, "POST", f"{args.url}/api/collection",
            json={"name": "Lab 8 - DuckDB", "description": "Analisis de viajes NYC TLC, 2024-2026"},
        )
    collection_id = coleccion["id"]

    existentes = api(sesion, "GET", f"{args.url}/api/card", params={"f": "all"})
    por_nombre = {
        tarjeta["name"]: tarjeta for tarjeta in existentes
        if tarjeta.get("collection_id") == collection_id
    }
    tarjetas = []
    for pregunta in PREGUNTAS:
        payload = {
            "name": pregunta["name"],
            "description": pregunta["description"],
            "display": pregunta["display"],
            "visualization_settings": pregunta["settings"],
            "collection_id": collection_id,
            "type": "question",
            "dataset_query": {
                "database": database_id,
                "type": "native",
                "native": {"query": pregunta["sql"], "template-tags": {}},
            },
        }
        anterior = por_nombre.get(pregunta["name"])
        if anterior:
            tarjeta = api(sesion, "PUT", f"{args.url}/api/card/{anterior['id']}", json=payload)
        else:
            tarjeta = api(sesion, "POST", f"{args.url}/api/card", json=payload)
        # Ejecutar una vez valida el SQL y deja los metadatos listos para la grafica.
        api(sesion, "POST", f"{args.url}/api/card/{tarjeta['id']}/query", json={"parameters": []})
        tarjetas.append(tarjeta)
        print(f"OK  {tarjeta['name']}")

    # Las tarjetas de la coleccion que ya no estan en PREGUNTAS (por ejemplo las
    # versiones anteriores de 1 y 2) se archivan para que no queden sueltas.
    vigentes = {pregunta["name"] for pregunta in PREGUNTAS}
    for nombre, tarjeta in por_nombre.items():
        if nombre not in vigentes:
            api(sesion, "PUT", f"{args.url}/api/card/{tarjeta['id']}", json={"archived": True})
            print(f"ARCHIVADA (ya no se usa) {nombre}")

    tableros = api(sesion, "GET", f"{args.url}/api/dashboard")
    tablero = next((t for t in tableros if t["name"] == "NYC Taxi: 2024-2026"), None)
    datos_tablero = {
        "name": "NYC Taxi: 2024-2026",
        "description": "Indicadores de volumen, viajes, pagos, propinas y calidad para taxis yellow y green.",
        "collection_id": collection_id,
    }
    if tablero is None:
        tablero = api(sesion, "POST", f"{args.url}/api/dashboard", json=datos_tablero)
    else:
        tablero = api(sesion, "PUT", f"{args.url}/api/dashboard/{tablero['id']}", json=datos_tablero)

    detalle = api(sesion, "GET", f"{args.url}/api/dashboard/{tablero['id']}")
    dashcards = {d.get("card_id"): d for d in detalle.get("dashcards", [])}
    posiciones = []
    for indice, tarjeta in enumerate(tarjetas):
        existente = dashcards.get(tarjeta["id"])
        posiciones.append({
            "id": existente["id"] if existente else -(indice + 1),
            "card_id": tarjeta["id"],
            "row": (indice // 2) * 6,
            "col": (indice % 2) * 12,
            "size_x": 12,
            "size_y": 6,
        })
    api(
        sesion, "PUT", f"{args.url}/api/dashboard/{tablero['id']}/cards",
        json={"cards": posiciones},
    )
    print(f"\nTablero listo: {args.url}/dashboard/{tablero['id']}")


if __name__ == "__main__":
    main()