# Spec Delta

## Purpose

Define el comportamiento observable del núcleo que hace avanzar la partida: el reloj por ticks, la economía data-driven, los recursos, la radiación y la escalera de consecuencias que lleva a la muerte o al fin de la misión.

## MODIFIED Requirements

### Requirement: Radiación acumulativa irreversible

La dosis de radiación SHALL ser un acumulador que nunca decrece. Bajo techo SHALL permanecer constante; en el exterior SHALL crecer según distancia, duración y el multiplicador del traje equipado. Por encima del 30% SHALL limitar la salud máxima y causar daño progresivo; al 100% SHALL causar la muerte.

#### Scenario: Interior sin ganancia

- **WHEN** transcurre un tick con el astronauta bajo techo
- **THEN** la dosis de radiación no aumenta

#### Scenario: Exterior con ganancia

- **WHEN** el astronauta permanece en el exterior durante un tick
- **THEN** la dosis aumenta según la distancia y el tiempo configurados

#### Scenario: Traje reforzado

- **WHEN** el astronauta lleva el traje reforzado y pasa un tick en el exterior
- **THEN** la dosis aumenta según la fila de exterior multiplicada por la fila del traje reforzado

#### Scenario: Dosis irreversible

- **WHEN** el astronauta vuelve al interior después de acumular dosis
- **THEN** la dosis acumulada se conserva y no decrece en ticks posteriores

#### Scenario: Umbral del 30%

- **WHEN** la dosis supera el 30%
- **THEN** la salud máxima se reduce a ese tope y la salud por encima del tope se pierde

#### Scenario: Dosis letal

- **WHEN** la dosis alcanza el 100%
- **THEN** la partida termina por muerte
