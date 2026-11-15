# Spec Delta

## Purpose

Capa de información de la partida: recursos, vitales, reloj, velocidad y pausa,
avisos de evento y prompt de interacción, para que el jugador pueda leer el
estado de la simulación sin abrir paneles.

## ADDED Requirements

### Requirement: Lectura de recursos y vitales

El HUD SHALL mostrar energía, oxígeno, agua y comida junto con salud, dosis de
radiación, hambre y sed. Cada valor SHALL leerse del estado de simulación y
refrescarse en cada tick y al arrancar la partida.

#### Scenario: Refresco por tick

- **WHEN** la simulación avanza un tick
- **THEN** los ocho valores del HUD muestran los valores del estado en ese tick

#### Scenario: Valores iniciales

- **WHEN** la escena jugable termina de cargar
- **THEN** el HUD muestra los valores iniciales de la economía antes del primer tick

#### Scenario: Recurso sin dato

- **WHEN** el estado no contiene un recurso que el HUD debe mostrar
- **THEN** el HUD lo indica como no disponible en lugar de mostrar un cero

### Requirement: Reloj de la partida

El HUD SHALL mostrar el tick actual, el número de sol y la fase de día o noche.
El sol SHALL calcularse con las filas `day_length_ticks` y `night_length_ticks`
de la economía, y el reloj NO SHALL avanzar mientras la partida esté pausada.

#### Scenario: Avance del reloj

- **WHEN** transcurre un tick
- **THEN** el contador de ticks y el sol que muestra el HUD se actualizan

#### Scenario: Fase de día y de noche

- **WHEN** el tick entra en la franja nocturna de la economía
- **THEN** el HUD muestra la fase de noche y en la franja diurna muestra la de día

#### Scenario: Partida pausada

- **WHEN** la partida está pausada durante 120 segundos reales
- **THEN** el reloj del HUD sigue mostrando el mismo tick y el mismo sol

### Requirement: Control de velocidad y pausa

El jugador SHALL poder subir y bajar la velocidad entre ×1, ×5 y ×10 y alternar
la pausa mediante acciones de entrada dedicadas y mediante controles del HUD. El
cambio SHALL aplicarse de inmediato y el HUD SHALL indicar la velocidad y el
estado de pausa.

#### Scenario: Subir la velocidad

- **WHEN** el jugador sube la velocidad estando a ×1
- **THEN** el reloj pasa a ×5 y el HUD lo indica

#### Scenario: Tope de velocidad

- **WHEN** el jugador sube la velocidad estando a ×10
- **THEN** la velocidad sigue en ×10 y el HUD no muestra un valor fuera de rango

#### Scenario: Pausa y reanudación

- **WHEN** el jugador alterna la pausa
- **THEN** el reloj deja de producir ticks y al alternarla de nuevo vuelve a la velocidad anterior

#### Scenario: Teclas y botones

- **WHEN** el jugador usa la tecla de pausa o el botón de pausa del HUD
- **THEN** ambos producen el mismo cambio de estado

### Requirement: Prompt de interacción

Cuando el astronauta tenga un objetivo interactuable en rango, el HUD SHALL
mostrar el nombre del objetivo y la tecla de interacción. El prompt SHALL
ocultarse cuando no haya objetivo, cuando haya un panel abierto y cuando la
partida haya terminado.

#### Scenario: Objetivo en rango

- **WHEN** el astronauta se acerca a una estación hasta su alcance de interacción
- **THEN** el HUD muestra el nombre de la estación y la tecla de interacción

#### Scenario: Sin objetivo

- **WHEN** el astronauta se aleja hasta perder el objetivo
- **THEN** el prompt desaparece

#### Scenario: Panel abierto

- **WHEN** hay un panel de máquina abierto
- **THEN** el prompt de interacción no se muestra

### Requirement: Banner de evento activo

Mientras haya un evento activo, el HUD SHALL mostrar un banner con su arquetipo,
su intensidad en el tick actual y su procedencia. Un evento con `real_data:
false` SHALL identificarse como simulado y uno con `real_data: true` SHALL mostrar
su fuente y su fecha. El banner SHALL retirarse en el tick en que el evento
termine.

#### Scenario: Evento con datos reales

- **WHEN** un evento con procedencia real está activo
- **THEN** el banner muestra arquetipo, intensidad, fuente y fecha

#### Scenario: Evento simulado

- **WHEN** un evento con `real_data: false` está activo
- **THEN** el banner se identifica como simulado y no inventa una fuente

#### Scenario: Fin del evento

- **WHEN** el evento activo termina
- **THEN** el banner desaparece en ese mismo tick

#### Scenario: Varios eventos activos

- **WHEN** hay más de un evento activo a la vez
- **THEN** el HUD muestra un banner por evento sin solaparse ni tapar los recursos

### Requirement: Aviso de comunicaciones cortadas

Mientras el estado marque las comunicaciones cortadas, el HUD SHALL mostrar un
aviso persistente y SHALL retirarlo en el tick en que se restablezcan.

#### Scenario: Corte de comunicaciones

- **WHEN** el estado pasa a comunicaciones cortadas
- **THEN** el HUD muestra el aviso en ese tick

#### Scenario: Restablecimiento

- **WHEN** el estado deja de estar en comunicaciones cortadas
- **THEN** el aviso desaparece

### Requirement: HUD superpuesto sin bloquear el juego

El HUD SHALL ser una capa de solo lectura: NO SHALL capturar el movimiento ni la
interacción del astronauta, y solo sus controles explícitos SHALL consumir clics
o pulsaciones. Con la partida terminada, sus controles de tiempo SHALL quedar
deshabilitados.

#### Scenario: Movimiento con el HUD visible

- **WHEN** el jugador mueve al astronauta con el HUD en pantalla
- **THEN** el movimiento y la interacción funcionan igual que sin HUD

#### Scenario: Clic fuera de un control

- **WHEN** el jugador hace clic en una zona del HUD que no es un control
- **THEN** el clic no cambia el estado de la partida

#### Scenario: Partida terminada

- **WHEN** la partida termina
- **THEN** los controles de velocidad y pausa del HUD dejan de aceptar cambios

### Requirement: HUD solo durante la partida

El HUD SHALL mostrarse únicamente con la escena jugable activa y SHALL
desaparecer al salir de ella, sin dejar controles activos en la escena
siguiente.

#### Scenario: Salida de la partida

- **WHEN** la escena jugable se descarga
- **THEN** el HUD deja de mostrarse y sus atajos dejan de responder
