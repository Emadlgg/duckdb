# Ejercicio 5: incorporacion de 2024

## Procedimiento (5.1 a 5.5)

No hubo que modificar el script. El anio ya era un parametro desde el Ejercicio 2, asi que bastó con:

```bash
docker compose exec lab python scripts/download_data.py --years 2024 2026
docker compose exec lab python scripts/download_data.py --verify --years 2024 2026
```

Los 16 archivos de 2026 aparecieron como `ya existe, se omite` y solo se bajaron los 24 de 2024 (12 de yellow y 12 de green). La verificacion no reporto faltantes ni archivos con tamano distinto.

## Validacion con DuckDB (5.6 y 5.8)

Las consultas estan en `sql/05_incorporacion.sql` y la salida en `docs/salida_ej5.txt`. Las vistas de `sql/00_vistas.sql` no se modificaron.

| Consulta | Resultado |
|---|---|
| [5.5a] archivos por tipo y anio | 12 archivos de 2024 y 8 de 2026, tanto en yellow como en green |
| [5.6a] registros por anio | yellow: 41,169,720 (2024) y 29,703,355 (2026). Green: 660,218 y 337,114 |
| [5.6b] viajes por mes, ambos anios | Los 12 meses de 2024 y los 8 de 2026 aparecen en la misma consulta |
| [5.7a y 5.7b] columnas por anio | Los 20 archivos de cada tipo tienen las mismas columnas y los mismos tipos. `cbd_congestion_fee` solo existe en 2026 (8 archivos) y `request_source` solo en 3 archivos de 2026 |
| [5.7c] esquema final | Igual al que ya se tenia con solo 2026, mismas columnas y tipos |

Nombres como `Airport_fee` se mantienen iguales en los archivos de ambos anios, asi que no hubo conflicto de nombres ni de tipos al unirlos. Las columnas que no existen en 2024 quedan como nulas, gracias a `union_by_name`.

## 5.7 Las consultas anteriores necesitan cambios

Se volvieron a ejecutar `03_exploracion.sql` y `04_eda.sql` sin modificarlos sobre 2024 y 2026 (salida en `docs/salida_ej5_regresion.txt`). Todas las consultas corrieron sin errores, asi que no hizo falta cambiar ninguna. Lo que si cambia es como se leen algunos resultados: Q1 ahora muestra los 20 meses, Q2 (horas) mezcla los dos anios en un solo perfil, y Q3 sigue siendo valida porque ya dividia entre la cantidad de dias de cada caso. El tiempo de ejecucion crecio casi en proporcion a los datos: con 2.4 veces mas filas, Q4 paso de 3.6 s a 8.2 s y Q9 de 3.8 s a 8.3 s.

## 5.9 Que permite incorporar archivos sin cambiar el flujo

- Las vistas leen `data/raw/yellow/*/*.parquet` y `data/raw/green/*/*.parquet`, con comodines. Un archivo nuevo en esas carpetas entra en todas las consultas sin tocar el SQL.
- `union_by_name` alinea las columnas por nombre, de modo que un archivo con columnas de mas o de menos (como `cbd_congestion_fee` en 2026) no rompe la lectura.
- El anio es un parametro (`--years`) del script de descarga y no esta escrito dentro del codigo.
- El script omite lo que ya existe, asi que se puede volver a ejecutar sin repetir descargas ni borrar nada.
- Los datos crudos (`data/raw`) estan separados de lo que se deriva de ellos, y todo el analisis parte de consultas versionadas en `sql/`.

## Primera comparacion entre anios

De enero a agosto, yellow tiene 12.6 % mas viajes en 2026 que en 2024 (29.7 M contra 26.4 M), con aumentos en todos los meses, de 8 % a 26 %. Green hace lo contrario y baja 24 % (337 mil contra 443 mil). Tambien aparece en 2024 la caida del verano que se vio en 2026: en yellow, agosto de 2024 tiene 20 % menos viajes que mayo, y en octubre se recupera 29 % respecto a agosto. Esto apoya la idea de que es estacional.

## Diferencias que aparecen al sumar 2024

Las cifras de 2024 se calcularon restando lo ya conocido de 2026 a los totales de las dos corridas, asi que son aproximadas por el filtro de `trips_limpios`.

| Medida (yellow) | 2024 | 2026 |
|---|---|---|
| Viajes sin pasajeros registrados (pago tipo 0) | 9.9 % | 26.0 % |
| Pago con tarjeta | 75.3 % | 64.1 % |
| Pago en efectivo | 13.3 % | 9.0 % |
| Tarifa negativa | 1.78 % | 0.53 % |
| Distancia menor o igual a 0 | 1.89 % | 3.21 % |
| Bajada antes de la subida | 1,575 viajes | 10 viajes |

En green el tipo de pago vacio sube de 3.7 % a 14.4 %. La relacion de Q11 se mantiene al sumar los dos anios: el 100 % de los viajes con pago tipo 0 (yellow) o vacio (green) no tiene pasajeros registrados, y ningun otro tipo de pago los tiene vacios. Es decir, esa forma de registrar los viajes existe en 2024 pero crecio mucho en 2026, y coincide con la baja del pago con tarjeta.

Tambien hay valores extremos nuevos: el total maximo de un viaje de yellow pasa de 7,053 dolares en 2026 a 335,550 al incluir 2024. Por dia, yellow tiene entre 10 % y 26 % mas viajes en 2026 que en 2024 para cada mes de enero a agosto.
