# Ejercicio 7: indicadores y tablero

Las diez preguntas y sus consultas estan en `sql/07_indicadores.sql`. El
tablero se construye con `scripts/create_dashboard.py`, que crea o actualiza las
preguntas en Metabase y conecta la base en modo de solo lectura.

| Indicador | Pregunta | Visualizacion | Justificacion |
|---|---|---|---|
| Viajes por mes | Como cambia el volumen cada mes? | Linea | Permite ver tendencia y estacionalidad |
| Viajes diarios por anio | Cambio el nivel de demanda? | Barras | Corrige la diferencia de dias observados |
| Demanda por hora | En que horas se concentran los viajes? | Lineas porcentuales | Compara perfiles aunque yellow tenga mucho mas volumen |
| Distancia mediana | Cambio el viaje tipico? | Barras | La mediana resiste los valores extremos |
| Monto total promedio | Como evoluciona lo cobrado por viaje? | Barras | Resume el efecto conjunto de tarifa, cargos y peajes |
| Tarjeta y Flex Fare | Como cambia la forma de registrar/pagar viajes? | Barras agrupadas | Es el principal cambio de mezcla observado |
| Propina mediana | Cuanto se propina con tarjeta? | Barras | Evita mezclar efectivo, cuya propina no se registra |
| Registros inconsistentes | Cambio la calidad de los datos? | Barras | Hace visible el efecto de los filtros del analisis |
| Zonas de origen | Donde se concentra la demanda? | Barras | Identifica las zonas dominantes de cada servicio |
| Comparacion enero-agosto | Como cambia el volumen entre anios comparables? | Indice base 100 | Evita comparar 2026 parcial contra anios completos |

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
  14.4 %. Al mismo tiempo cae la participacion de tarjeta.
- La propina mediana con tarjeta permanece estable: alrededor de 26 % en yellow
  y 23 % en green.
- Yellow 2025 destaca por 5.88 % de registros inconsistentes, frente a 1.80 %
  en 2024 y 0.56 % en 2026. No se debe interpretar una diferencia de ese anio
  sin aplicar los filtros de calidad.
- Las zonas 237, 161 y 132 dominan yellow, mientras 74 y 75 dominan green. La
  concentracion se mantiene en los tres anios.

La evidencia exportada esta en `output/pdf/tablero_metabase.pdf`. El tablero
local queda disponible en `http://localhost:3000` mientras Docker este activo.
