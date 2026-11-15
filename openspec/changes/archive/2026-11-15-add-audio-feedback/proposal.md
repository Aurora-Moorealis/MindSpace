# Proposal

## Why

La demo jugable ya tiene acciones (menús, siembra, cosecha, reparación, HUD y
eventos), pero ninguna suena. El diseño formal ya reserva un `AudioManager` con
5 SFX (`docs/designs/junior-astronauta-outpost-lunar.md`, sección `AudioManager`)
y `docs/future/art-and-audio.md` fija el criterio de mezcla. Este cambio lleva
ese audio al juego real y lo extiende a las acciones que ya existen, sin tocar la
simulación ni añadir mecánicas.

## What Changes

- Se añade un **bus `SFX`** y un **sistema de audio central** con 12 one-shots,
  pool de voces, jitter de tono para acciones repetidas y mute global con `M`.
- Se colocan los sonidos según su dueño: los compartidos en
  `game/assets/audio/sfx/` y los exclusivos de la hidroponía en
  `game/content/machines/hydroponics/sounds/`.
- Se cablea el feedback en: menú, selección de mundo, intro, evaluación,
  panel de máquina (reparar/mejorar/abrir/cerrar), panel de hidroponía
  (sembrar/recoger/quitar), hotbar, pausa/velocidad del HUD, aviso de radiación y
  eventos/informes del `EventLog`.
- El sonido de escaneo queda disponible para cuando exista el escaneo de POIs;
  no se inventa una acción para usarlo.
- Se mantiene `repair`, `report`, `radiation_alarm` y `event` como los SFX del
  diseño formal, además de los de UI y jardín.

## Capabilities

### New Capabilities

- `audio-feedback`: contrato observable de la respuesta sonora de una acción
  (qué suena, cuándo, con qué mezcla y cómo se silencia), la propiedad de los
  assets y la regla de una sola voz por acción.

### Modified Capabilities

Ninguna. Las specs existentes (`menu`, `hud`, `machines`, `hydroponics`,
`events`, `evaluation`) describen comportamiento de juego; el audio se añade
como una capability transversal sin cambiar sus requisitos.

## Impact

- **Archivos nuevos:** `game/scripts/autoloads/audio_manager.gd`,
  `game/default_bus_layout.tres`, `game/assets/audio/sfx/` y
  `game/content/machines/hydroponics/sounds/`.
- **Archivos modificados:** `game/project.godot` (autoload), menús y flujo
  (`scenes/welcome`, `worlds`, `intro`, `evaluation`, `ui/run_ui`), máquinas
  (`machine_panel`, `hydroponics_panel`), HUD (`hud.gd`, `game_hud.gd`) y el
  gancho de hechos de `EventLog`.
- **Sin cambios de simulación:** ni `GameSim`, ni `SimTick`, ni el modelo de
  datos. El audio solo reacciona a acciones y hechos ya existentes.
- **Dependencias:** ninguna externa; los SFX son originales y se versionan como
  OGG mono 44.1 kHz.

## Fuera de alcance

- Música, ambiente, pasos, voz y loops.
- Subtítulos o iconos de accesibilidad para SFX críticos (queda como follow-up
  de `docs/future/art-and-audio.md`).
- Menú de pausa completo: la rama jugable actual solo tiene los controles del
  HUD; el mute por tecla `M` cubre el requisito mínimo.
- Escaneo de POIs: `scan` se entrega listo, pero no se cablea a una acción que
  todavía no existe.
