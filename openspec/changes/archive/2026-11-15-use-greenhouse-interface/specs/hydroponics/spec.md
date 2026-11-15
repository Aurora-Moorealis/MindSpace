# Spec Delta

## MODIFIED Requirements

### Requirement: Panel de cultivo

El panel de máquina de la hidroponía SHALL ofrecer la acción de abrir la interfaz
de cultivo del invernadero. Esa interfaz SHALL mostrar las doce celdas con su
etapa, permitir las acciones válidas de cada celda y volver al panel de máquina.
La interfaz SHALL abrirse también con la máquina averiada o sin energía, y en ese
caso solo SHALL ofrecer las acciones que la estación acepte, explicando el estado.
Todos los textos visibles de la interfaz SHALL estar en inglés.

#### Scenario: Abrir el cultivo

- **WHEN** el jugador usa la acción de cultivo desde el panel de la hidroponía
- **THEN** se abre la interfaz de invernadero con las doce celdas y su etapa

#### Scenario: Volver

- **WHEN** el jugador cierra la interfaz de cultivo
- **THEN** vuelve al panel de máquina sin alterar ninguna celda

#### Scenario: Máquina averiada

- **WHEN** la hidroponía está averiada o sin energía
- **THEN** la interfaz se abre, la siembra y la cosecha quedan rechazadas y retirar sigue disponible

#### Scenario: Estado en vivo

- **WHEN** la simulación avanza un tick con la interfaz abierta
- **THEN** las celdas y los contadores reflejan la nueva etapa sin cerrar la interfaz

#### Scenario: Acciones reales

- **WHEN** el jugador siembra, cosecha o retira desde la interfaz
- **THEN** el estado de cultivo de la estación cambia y la comida se suma solo al cosechar
