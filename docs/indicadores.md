# Ejercicio 7: indicadores y tablero

Las diez preguntas y sus consultas estan en `sql/07_indicadores.sql`. El
tablero se construye con `scripts/create_dashboard.py`, que crea o actualiza las
preguntas en Metabase y conecta la base en modo de solo lectura. Son diez
indicadores y doce graficas: los indicadores 1 y 2 se muestran en dos graficas
cada uno, una para yellow y otra para green, porque yellow tiene unas cien veces
mas viajes y en una sola escala green no se distingue.

| Indicador | Pregunta | Visualizacion | Justificacion |
|---|---|---|---|
| 1. Viajes por mes | Como cambia el volumen cada mes? | Una linea por tipo de taxi (1a yellow, 1b green) | Permite ver tendencia y estacionalidad de cada servicio en su propia escala |
| 2. Viajes diarios por anio | Cambio el nivel de demanda? | Barras por tipo de taxi (2a yellow, 2b green) | Corrige la diferencia de dias observados, porque 2026 solo llega a agosto |
| 3. Demanda por hora | En que horas se concentran los viajes? | Lineas porcentuales | Compara perfiles aunque yellow tenga mucho mas volumen |
| 4. Distancia mediana | Cambio el viaje tipico? | Barras | La mediana resiste los valores extremos |
| 5. Monto total promedio | Como evoluciona lo cobrado por viaje? | Barras | Resume el efecto conjunto de tarifa, cargos y peajes |
| 6. Tarjeta y Flex Fare | Como cambia la forma de registrar/pagar viajes? | Barras agrupadas | Es el principal cambio de mezcla observado |
| 7. Propina mediana | Cuanto se propina con tarjeta? | Barras | Evita mezclar efectivo, cuya propina no se registra |
| 8. Registros inconsistentes | Cambio la calidad de los datos? | Barras | Hace visible el efecto de los filtros del analisis |
| 9. Zonas de origen | Donde se concentra la demanda? | Barras, en porcentaje de los viajes del tipo y anio | Identifica las zonas dominantes de cada servicio. Se usa porcentaje para no comparar un 2026 de ocho meses contra anios completos ni yellow contra green por volumen |
| 10. Comparacion enero-agosto | Como cambia el volumen entre anios comparables? | Indice base 100 | Evita comparar 2026 parcial contra anios completos |

## Periodos de las cifras

Las cifras de 2024 y 2025 de este documento son de anio completo y las de 2026
de enero a agosto, salvo que se indique otra cosa. En
`docs/analisis_2024_2026.md` todo se compara solo con enero-agosto, por eso
algunos valores de 2024 son distintos entre los dos documentos (por ejemplo, el
monto total promedio de yellow es 28.75 con el anio completo y 28.45 con
enero-agosto). Los dos son correctos para su periodo.

## Interpretacion

- Yellow mantiene cerca de cien veces el volumen de green. En el periodo
  comparable, yellow pasa de 106,354 viajes diarios en 2024 a 122,290 en 2025 y
  121,546 en 2026. Green baja de 1,809 a 1,624 y luego a 1,380.
- La distancia mediana aumenta en los dos servicios. Green pasa de 1.97 a 2.14
  millas y yellow de 1.80 a 1.92.
- El monto total promedio sube de 28.75 a 30.40 dolares en yellow y de 24.40 a
  25.65 en green.
- Los viajes Flex Fare crecen con fuerza. En yellow pasan de 9.8 % en 2024 a
  26.1 % en 2026; en green, los registros sin codigo de pago pasan de 3.7 % a
  14.4 %. En yellow la participacion de la tarjeta baja cada anio (75.3 %, 67.7 %
  y 64.1 %). En green se mantiene cerca de 69 % en 2024 y 2025 y baja a 65.5 %
  en 2026.
- La propina mediana con tarjeta permanece estable: alrededor de 26 % en yellow
  y 23 % en green.
- Yellow 2025 destaca por 5.88 % de registros inconsistentes, frente a 1.80 %
  en 2024 y 0.56 % en 2026. No se debe interpretar una diferencia de ese anio
  sin aplicar los filtros de calidad.
- Las zonas 237, 161, 132 y 236 estan entre las cuatro principales de yellow en
  los tres anios, mientras 74 y 75 son las dos primeras de green en los tres
  anios. La concentracion se mantiene.

La evidencia exportada esta en `output/pdf/tablero_metabase.pdf`. El tablero
local queda disponible en `http://localhost:3000` mientras Docker este activo.