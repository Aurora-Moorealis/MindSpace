# Consistencia del morro entre las dos vistas del cohete

- **Estado:** pendiente de decisión
- **Prioridad:** baja
- **Depende de:** —

## Objetivo

El cohete en vuelo (`rocket-ascent`) tiene el **morro teal**; el de aterrizaje
tiene la **cúpula plateada**. Como son el mismo vehículo, hay dos lecturas
posibles y hay que elegir una.

## Opciones

| Opción | Efecto | Coste |
| --- | --- | --- |
| **A. Igualar a plateado** | Morro del ascendente pasa a la rampa de grises del casco | Bajo: remapear los píxeles teal de la punta (índices de color 4/5/6 solo en la zona del cono) |
| **B. Dejar el contraste** | El teal se lee como carenado pintado; no rompe nada porque el aterrizaje va de frente y no muestra la punta | Cero |

## Criterios de aceptación

- La decisión queda escrita en `docs/guia-estetica.md` (sección de cohetes).
- Si es A: la zona teal del morro se identifica por geometría (`x` e `y` del
  cono), no por índice de color a secas, porque el mismo teal se usa en las
  franjas del cuerpo.

## Notas

Se preguntó al autor y respondió "como quieras"; queda abierto hasta que el arte
se use de verdad en una escena.
