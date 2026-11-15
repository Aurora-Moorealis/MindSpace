# Spec Delta

## MODIFIED Requirements

### Requirement: Lectura de recursos y vitales

El HUD SHALL mostrar la barra de vida con la salud actual y la salud máxima de la
simulación, y la tira de recursos con oxígeno, agua, comida y energía, cada uno con
su porcentaje sobre su capacidad. Cada valor SHALL leerse del estado de simulación
y refrescarse en cada tick y al reiniciar la partida. La radiación, el hambre y la
sed NO SHALL mostrarse en esta versión.

#### Scenario: Refresco por tick

- **WHEN** la simulación avanza un tick
- **THEN** la barra de vida y las cuatro barras de recursos muestran los valores del estado en ese tick

#### Scenario: Valores iniciales

- **WHEN** la escena jugable termina de cargar
- **THEN** el HUD muestra los valores iniciales de la economía antes del primer tick

#### Scenario: Recurso sin dato

- **WHEN** el estado no contiene un recurso que el HUD debe mostrar
- **THEN** el HUD usa la capacidad de respaldo para calcular el porcentaje en lugar de fallar

### Requirement: Reloj de la partida

El HUD SHALL mostrar el sol actual, la fase de día o noche y la hora del sol en la
esquina superior derecha, sin panel de fondo. El sol SHALL calcularse con las filas
`day_length_ticks` y `night_length_ticks` de la economía y el reloj NO SHALL avanzar
mientras la partida esté pausada.

#### Scenario: Avance del reloj

- **WHEN** transcurre un tick
- **THEN** el sol y la hora que muestra el HUD se actualizan

#### Scenario: Fase de día y de noche

- **WHEN** el tick entra en la franja nocturna de la economía
- **THEN** el HUD muestra la fase de noche y en la franja diurna muestra la de día

#### Scenario: Partida pausada

- **WHEN** la partida está pausada durante 120 segundos reales
- **THEN** el reloj del HUD sigue mostrando el mismo sol y la misma hora

### Requirement: HUD superpuesto sin bloquear el juego

El HUD SHALL ser una capa de solo lectura: NO SHALL capturar el movimiento ni la
interacción del astronauta, y solo los espacios de la hotbar y el objeto en la mano
SHALL consumir clics o pulsaciones.

#### Scenario: Movimiento con el HUD visible

- **WHEN** el jugador mueve al astronauta con el HUD en pantalla
- **THEN** el movimiento y la interacción funcionan igual que sin HUD

#### Scenario: Clic fuera de un control

- **WHEN** el jugador hace clic en una zona del HUD que no es un espacio de la hotbar
- **THEN** el clic no cambia el estado de la partida

#### Scenario: Partida terminada

- **WHEN** la partida termina
- **THEN** el HUD deja de refrescar la vida y los recursos y la evaluación queda por encima de él

## REMOVED Requirements

### Requirement: Control de velocidad y pausa

**Reason**: queda pospuesto; esta versión no ofrece controles de tiempo en el HUD.
El reloj muestra el multiplicador actual, pero no se puede cambiar desde la
interfaz.

### Requirement: Prompt de interacción

**Reason**: queda pospuesto a un cambio posterior; la interacción con las máquinas
sigue funcionando aunque el HUD no muestre el nombre del objetivo.

### Requirement: Banner de evento activo

**Reason**: queda pospuesto a un cambio posterior; el HUD de esta versión se limita
a vida, recursos, Sol y hotbar.

### Requirement: Aviso de comunicaciones cortadas

**Reason**: queda pospuesto a un cambio posterior; el estado de comunicaciones
sigue en el ledger aunque el HUD no lo muestre.
