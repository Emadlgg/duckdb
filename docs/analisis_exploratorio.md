# Ejercicio 4: analisis exploratorio

Datos: viajes de taxis amarillos y verdes de enero a agosto de 2026. Despues de aplicar la vista `trips_limpios` quedan 29,535,723 viajes de yellow (se descartó 0.56 %) y 335,441 de green (se descartó 0.5 %). Las consultas estan en `sql/04_eda.sql` y la salida completa en `docs/salida_ej4.txt`.

## 4.1 Preguntas

1. Como cambia el volumen de viajes a lo largo de los meses.
2. A que horas se concentra la demanda y si yellow y green siguen el mismo patron.
3. Cambia la demanda entre dias de la semana.
4. Como es un viaje tipico en distancia, duracion y pasajeros.
5. Que diferencias de tarifa hay entre yellow y green.
6. Como se paga y cuanto se deja de propina.
7. Que valores atipicos o inconsistentes hay en los datos.

## 4.4 Resultados

**Volumen mensual (Q1).** Yellow tiene unas cien veces mas viajes que green. El total de febrero es el mas bajo, pero es por tener 28 dias: por dia, el volumen sube de 118,852 en enero hasta 131,459 en mayo y baja a 113,377 en julio y 107,123 en agosto, una caida de 18.5 % desde mayo.

**Horas (Q2).** Yellow tiene su pico a las 18 h (2.08 M de viajes) y su minimo a las 4 h (243 mil). Green tiene el pico una hora antes, a las 17 h, y el minimo a las 3 h. Entre las 0 y las 4 h ocurre 8.5 % de los viajes de yellow y 4.5 % de los de green. En la franja de 7 a 9 h green concentra 15.1 % de sus viajes y yellow 11.1 %.

**Dia de la semana (Q3).** Como enero a agosto tiene cinco dias que se repiten 35 veces y dos (martes y miercoles) que se repiten 34, hay que dividir por la cantidad de dias. En yellow el jueves es el dia mas fuerte (134,725 viajes por dia), seguido del sabado (131,629), y el lunes el mas bajo (100,904). En green el sabado cae a 1,159 viajes por dia contra 1,583 del jueves, es decir 27 % menos, mientras que en yellow el sabado esta casi igual que el jueves (98 %). Los viajes del fin de semana son algo mas largos: la distancia mediana del domingo es 2.22 millas en yellow y 2.38 en green, contra 1.82 y 2.08 el miercoles.

**Viaje tipico (Q4 y Q5).** La mediana de distancia es 1.92 millas en yellow y 2.14 en green, y la duracion mediana es 14.0 y 13.4 minutos. Los promedios de distancia son 3.51 y 3.36 millas, ya excluyendo los viajes de mas de 100 millas. El promedio de pasajeros es 1.25 y 1.30. Dos tercios de los viajes son de menos de 3 millas en ambos tipos (67.1 % en yellow y 66.3 % en green). Yellow tiene mas viajes largos: 7.6 % pasan de 10 millas contra 5.8 % en green. Ese corte importa mucho: en la primera ejecucion, sin excluirlos, el promedio de green era 13.89 millas, mayor que su percentil 95, y bastaron unos 70 viajes con distancias absurdas para llevarlo de 3.4 a 13.9.

**Tarifas (Q6).** La tarifa promedio de yellow es 21.51 y la de green 17.12, es decir 25.6 % mas. En el total pagado la diferencia es de 18.5 % (30.40 contra 25.65) y yellow paga mas peajes (0.54 contra 0.29). La tarifa por milla (suma de tarifas entre suma de millas, en viajes de 0.1 a 100 millas) es 5.99 dolares en yellow y 4.98 en green, 20 % mas en yellow. La primera version de esta consulta daba 25.49 porque promediaba razones y se inflaba con distancias minimas, por eso se cambio. Es de notar que la mayor tarifa de yellow no viene de viajes mas largos, porque su mediana de distancia es menor que la de green. Con estas consultas no se puede decir a que se debe.

**Pagos y propinas (Q7 y Q8).** En ambos tipos alrededor de dos tercios paga con tarjeta (64.1 % en yellow, 65.5 % en green). En yellow, 26.1 % de los viajes tiene `payment_type` igual a 0 (7.7 millones). En green, 14.4 % tiene el tipo de pago vacio. El efectivo siempre registra propina de 0.00, asi que las propinas solo se pueden analizar en viajes con tarjeta. Ahi la propina es de 25.4 % de la tarifa en promedio en yellow y 25.6 % en green, pero la mediana es mas alta en yellow (26.4 % contra 23.5 %).

**Atipicos (Q9 y Q10).** El percentil 99 de distancia es 19.6 millas en yellow y 17.9 en green, pero los maximos son 328,522 y 179,830 millas. En yellow hay 7,915 viajes con velocidad mayor a 80 mph, 1,191 de mas de 100 millas y 782 con total mayor a 500 dolares. En green son 1,105, 72 y 21. Son pocos en proporcion, pero alteran los promedios.

## 4.5 Hallazgos

1. **Los viajes sin pasajeros registrados son un tipo de viaje aparte.** En yellow, los 7,715,673 viajes con `payment_type` igual a 0 tienen todos el `passenger_count` vacio, y ningun otro tipo de pago tiene pasajeros vacios (Q11). En green pasa lo mismo con los 48,401 viajes de tipo de pago vacio. Es decir, el 26 % de nulos de yellow (14 % en green) no es un error aleatorio: viene de una forma distinta de registrar el viaje. El diccionario de datos de la TLC confirma que el tipo 0 corresponde a Flex Fare (<https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf>). Estos viajes tambien tienen una propina promedio muy baja (0.40 en yellow), asi que no son comparables con los de tarjeta. Decision: se conservan, pero se analizan aparte cuando la pregunta usa pasajeros o propinas.
2. **Yellow y green tienen perfiles distintos.** Yellow tiene mas actividad nocturna, mas viajes largos, tarifas 26 % mas altas (20 % mas por milla) y mantiene la demanda del fin de semana. Green se parece mas a un servicio de dias de semana con hora pico por la manana, y los sabados cae 27 % respecto al jueves.
3. **La demanda baja en el verano.** Despues del maximo de mayo (131,459 viajes por dia en yellow), julio y agosto caen 14 % y 18.5 %. Green tambien baja, pero menos (de 1,467 viajes por dia en abril a 1,305 en agosto, 11 %). Con solo estos ocho meses no se puede decir si es un patron anual, para eso se necesitan 2024 y 2025.
4. **Las distancias tienen una cola muy larga.** Con mediana de 1.9 millas, los maximos de cientos de miles de millas distorsionan cualquier promedio. Las conclusiones sobre distancia usan mediana y percentiles, y el analisis de distancia excluye viajes de mas de 100 millas, que son menos del 0.01 % de los viajes de yellow pero cambian el promedio de green en un factor de cuatro.
