# Spec Delta

## Purpose

Define la respuesta sonora de una acción del juego: qué suena, cuándo suena, con
qué mezcla y cómo se silencia, sin introducir música, voz ni cambios en la
simulación.

## ADDED Requirements

### Requirement: Feedback de acciones confirmadas y rechazadas

Toda acción confirmada por el jugador SHALL producir un único SFX de la acción
correspondiente. Una acción rechazada por el estado del juego SHALL producir el
sonido de denegación. Una acción sin efecto (clic fuera de un control, refresco
automático de una celda) SHALL NOT producir sonido.

#### Scenario: Acción confirmada

- **WHEN** el jugador siembra una celda vacía con la máquina operativa
- **THEN** suena el SFX de siembra una sola vez

#### Scenario: Acción rechazada

- **WHEN** el jugador pulsa una celda de una máquina rota y la siembra no se
  aplica
- **THEN** suena el SFX de denegación y no suena el de siembra

#### Scenario: Refresco sin acción

- **WHEN** el panel de hidroponía se refresca por un tick o por un cambio de
  estado
- **THEN** no se reproduce ningún SFX

### Requirement: Cobertura de las acciones del juego

El sistema SHALL cubrir las siguientes familias de acciones: UI (clic, abrir,
cerrar y denegar), hidroponía (sembrar, recoger y quitar), reparación de
máquina, informe enviado, aviso de radiación, notificación de evento y escaneo
cuando exista. Cada familia SHALL tener un sonido distinguible de las demás.

#### Scenario: Acciones de hidroponía

- **WHEN** el jugador siembra, recoge una planta madura o quita una planta en
  crecimiento
- **THEN** suena respectivamente `plant`, `harvest` o `remove`, sin reutilizar el
  mismo sonido para las tres

#### Scenario: Reparación

- **WHEN** el jugador inicia una reparación que `GameSim` acepta
- **THEN** suena el SFX de reparación y el panel se refresca

#### Scenario: Escaneo futuro

- **WHEN** todavía no existe una acción de escaneo en el juego
- **THEN** el SFX de escaneo permanece disponible pero no se dispara

### Requirement: Alertas críticas

El aviso de radiación SHALL sonar una sola vez cuando la dosis cruza el umbral
de aviso derivado del umbral de cap de la economía. La notificación de evento
SHALL sonar una sola vez por evento iniciado. Ninguna alerta SHALL depender de
que el jugador esté mirando el panel correspondiente.

#### Scenario: Cruce del umbral de radiación

- **WHEN** la dosis acumulada cruza por primera vez el umbral de aviso
- **THEN** suena `radiation_alarm` una vez y no se repite en los ticks
  siguientes

#### Scenario: Evento nuevo

- **WHEN** `EventLog` registra un hecho `EVENT_STARTED`
- **THEN** suena `event` una vez para ese evento

#### Scenario: Informe enviado

- **WHEN** `EventLog` registra un hecho `REPORT_SENT`
- **THEN** suena `report` una vez

### Requirement: Mezcla, voces y silencio

Los SFX SHALL reproducirse en un bus dedicado con volumen uniforme y sin
clipping. Varios SFX simultáneos SHALL usar voces independientes, de modo que
una acción corta no corte una alerta en curso. El jugador SHALL poder silenciar
y restaurar todo el bus con una sola acción.

#### Scenario: Solapamiento

- **WHEN** suena la alarma de radiación y el jugador pulsa un botón de UI
- **THEN** ambos suenan a la vez sin que el clic corte la alarma

#### Scenario: Mute

- **WHEN** el jugador activa el mute
- **THEN** se detienen los SFX en curso y las acciones posteriores no suenan
  hasta que lo desactive

### Requirement: Propiedad y formato de los assets

Los sonidos compartidos por varios sistemas SHALL vivir en
`game/assets/audio/sfx/`. Los sonidos usados solo por la hidroponía SHALL vivir
en `game/content/machines/hydroponics/sounds/`. Cada asset SHALL ser mono, 44.1
kHz, Ogg Vorbis, con su `.import` versionado y sin duplicados entre carpetas.

#### Scenario: Separación por dueño

- **WHEN** se revisan los SFX de sembrar, recoger y quitar
- **THEN** están en la carpeta de la hidroponía y no en `assets/audio/sfx/`

#### Scenario: Formato y clipping

- **WHEN** se mide el pack con `ffprobe`/`ffmpeg`
- **THEN** todos son mono a 44.1 kHz y su pico real no supera -2 dBFS
