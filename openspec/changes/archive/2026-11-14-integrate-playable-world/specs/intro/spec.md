# Spec Delta

## Purpose

Introducción narrativa entre la elección de mundo y el juego: la salida de la
Tierra, la travesía a la Luna y la presentación de la misión.

## ADDED Requirements

### Requirement: Entrada al mundo jugable

Al aceptar la misión en la pantalla final, la introducción SHALL abrir la escena
jugable de la superficie lunar después de mostrar la confirmación. La
introducción SHALL dejar de ser la última pantalla del flujo.

#### Scenario: Aceptar la misión

- **WHEN** el jugador pulsa la acción de aceptar en la última parte y se muestra la confirmación
- **THEN** el juego abre la escena jugable y la introducción desaparece

#### Scenario: Cancelar antes de aceptar

- **WHEN** el jugador cancela la introducción antes de aceptar
- **THEN** el juego sigue regresando a la pantalla de mundos
