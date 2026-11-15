# Spec Delta

## MODIFIED Requirements

### Requirement: Reloj determinista por ticks

El núcleo SHALL avanzar el estado del juego únicamente mediante ticks discretos. Un tick representa 1 hora de juego y ocurre cada 60 segundos reales a ×1. Los multiplicadores ×1/×5/×10/×100/×1000/×10000 SHALL modificar solo la frecuencia del tick, nunca la escala temporal del motor. La pausa SHALL detener los ticks sin detener la interfaz.

#### Scenario: Avance a velocidad base

- **WHEN** transcurren 60 segundos reales con el reloj a ×1
- **THEN** el contador de ticks avanza exactamente 1 y la hora de juego avanza 1

#### Scenario: Multiplicadores de velocidad

- **WHEN** el reloj está a ×5 y transcurren 12 segundos reales
- **THEN** el contador de ticks avanza exactamente 1
- **WHEN** el reloj está a ×10 y transcurren 6 segundos reales
- **THEN** el contador de ticks avanza exactamente 1
- **WHEN** el reloj está a ×100 y transcurren 0,6 segundos reales
- **THEN** el contador de ticks avanza exactamente 1
- **WHEN** el reloj está a ×1000 y transcurren 0,06 segundos reales
- **THEN** el contador de ticks avanza exactamente 1
- **WHEN** el reloj está a ×10000 y transcurren 0,006 segundos reales
- **THEN** el contador de ticks avanza exactamente 1

#### Scenario: Pausa

- **WHEN** la partida está en pausa y transcurren 120 segundos reales
- **THEN** el contador de ticks no cambia
- **WHEN** se reanuda la partida
- **THEN** los ticks vuelven a avanzar a la velocidad seleccionada

#### Scenario: Determinismo

- **WHEN** dos partidas arrancan del mismo estado y aplican la misma secuencia de ticks
- **THEN** los recursos, la salud, la radiación, las máquinas y los hechos registrados son idénticos
