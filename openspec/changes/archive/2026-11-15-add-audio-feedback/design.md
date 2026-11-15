# Design

## Context

Ver `proposal.md` — Why. La rama jugable (`origin/connect-playable-loop`) ya
tiene el loop completo: `scenes/base/base.tscn`, HUD de hotbar
(`scenes/ui/hud.gd`), panel de máquina (`scenes/ui/machine_panel/`), panel de
hidroponía (`content/machines/hydroponics/panel/`) y el ledger `EventLog`.
`project.godot` solo registra `GameSim` y `EventLog`; no hay bus de audio, ni
assets, ni un solo `AudioStreamPlayer`.

Restricciones que mandan:

- El diseño formal reserva `AudioManager` con 5 SFX y `docs/future/art-and-audio.md`
  fija -16 LUFS aproximados, mute y subtítulos para SFX críticos.
- `AGENTS.md` exige que el audio de un contenido viva en su carpeta y que el
  código vaya tipado y en inglés.
- La simulación (`GameSim`, `SimTick`) no debe conocer la presentación: el audio
  no puede meter llamadas de sonido en el núcleo del tick.

## Goals / Non-Goals

**Goals:**

- Un único punto de reproducción, mezcla y mute para todos los SFX.
- Feedback en cada acción que ya existe, sin sonar en acciones rechazadas ni en
  refrescos automáticos.
- Assets colocados por dueño y con formato uniforme.
- Alertas críticas que suenen una vez y no se corten entre sí.

**Non-Goals:**

- Música, ambiente, pasos, voz y loops.
- Subtítulos/iconos de accesibilidad; quedan como follow-up.
- Cambiar el HUD, el panel de máquina o la simulación para añadir elementos
  visuales nuevos.
- Cablear `scan` a una acción inexistente.

## Decisions

### D1 — Autoload `AudioManager` + bus `SFX`, no un player por escena

Un autoload (`game/scripts/autoloads/audio_manager.gd`) preloada los 12 streams,
reparte la reproducción entre 10 voces y expone un enum `Sfx`. El bus `SFX` vive
en `game/default_bus_layout.tres` y se registra en `project.godot`.

- **Por qué:** el mute, el volumen uniforme y el solapamiento son estado global;
  repartirlos por escenas duplicaría players y haría que cerrar un panel cortara
  una alarma.
- **Alternativa descartada:** un `AudioStreamPlayer` por escena. Es menos código
  al principio, pero no hay mute global ni forma de evitar que dos escenas usen
  volúmenes distintos.
- **Coste:** un autoload más; el diseño ya lo contempla.

### D2 — Pool de 10 voces y jitter solo en acciones de mundo

Cada `play()` toma la siguiente voz libre en round-robin. `plant`, `harvest`,
`remove`, `scan` y `repair` reciben ±4–6 % de pitch; los sonidos de UI mantienen
el tono fijo.

- **Por qué:** una acción repetida no debe sonar idéntica hasta el punto de
  taladrar, pero un botón debe sonar igual siempre.
- **Alternativa descartada:** un player dedicado por sonido. No cubre dos
  instancias simultáneas del mismo sonido y complica el volumen.

### D3 — Tres puntos de enganche, no uno solo

1. **Acciones del jugador:** llamada directa en el código que ya decide el
   resultado (`welcome`, `worlds`, `intro`, `evaluation`, `machine_panel`,
   `hydroponics_panel`, `hud`). Solo suena si la operación devuelve `true`; si
   devuelve `false`, suena `ui_deny`.
2. **Hechos del run:** `run_ui` escucha `EventLog.fact_logged` y suena `report`
   para `REPORT_SENT` y `event` para `EVENT_STARTED`.
3. **Umbral de radiación:** el HUD activo (`hud.gd`) compara la dosis con el
   umbral de cap de la economía en cada tick y dispara `radiation_alarm` una vez.

- **Por qué:** el primer grupo necesita feedback inmediato; el segundo ya tiene
  un ledger canónico; el tercero es una condición de estado que no produce un
  hecho único.
- **Alternativa descartada:** emitir señales de audio desde `SimTick`. Mete
  presentación en el núcleo y obliga a tocar la simulación solo para sonar.

### D4 — Propiedad de los assets

Los sonidos de UI, reparación, informe, radiación, evento y escaneo son
compartidos: `game/assets/audio/sfx/`. `plant`, `harvest` y `remove` solo los usa
la hidroponía: `game/content/machines/hydroponics/sounds/`.

- **Por qué:** cumple la regla de `AGENTS.md` y permite mover la máquina sin
  arrastrar assets globales.
- **Alternativa descartada:** todo en `assets/audio/sfx/`. Es más simple, pero
  deja tres sonidos de contenido fuera de su dueño.

### D5 — Niveles y bus

Los OGG se normalizan por RMS con techo de pico; el bus `SFX` se sitúa a -4 dB
para dejar headroom. No hay música en v1, así que el bus es el único control de
mezcla.

- **Por qué:** el diseño pide volumen uniforme y nada de loops salvajes.
- **Coste:** si más adelante entra música, habrá que añadir ducking; no se
  implementa aquí.

### D6 — Mute global con `M`

`AudioManager._unhandled_input` alterna `_muted`; al mutear se paran las voces.
No hay menú de pausa en esta rama, así que la tecla es la vía mínima y el HUD de
pausa futuro podrá llamar a `toggle_muted()`.

### D7 — `scan` se entrega, no se fuerza

El escaneo de POIs no existe en esta rama. El asset y el enum quedan listos; no
se añade una acción falsa solo para usarlo.

## Files

**Crear:**

- `game/scripts/autoloads/audio_manager.gd`
- `game/default_bus_layout.tres`
- `game/assets/audio/sfx/` (UI, reparación, informe, radiación, evento, escaneo,
  README)
- `game/content/machines/hydroponics/sounds/` (`plant`, `harvest`, `remove`)

**Modificar:**

- `game/project.godot` (autoload `AudioManager`)
- `game/scenes/welcome/welcome.gd`
- `game/scenes/worlds/worlds.gd`
- `game/scenes/intro/intro.gd`
- `game/scenes/evaluation/evaluation.gd`
- `game/scenes/ui/run_ui.gd`
- `game/scenes/ui/machine_panel/machine_panel.gd`
- `game/content/machines/hydroponics/panel/hydroponics_panel.gd`
- `game/scenes/ui/hud.gd` (hotbar, aviso de radiación y controles de pausa y
  velocidad)

No se editan escenas compartidas: los botones ya están conectados por señal en
los `.tscn`; el audio se añade en los métodos que ya existen.

## Risks / Trade-offs

- **Doble sonido si se montan los dos HUD** → la alarma vive solo en `hud.gd` y
  los hechos solo en `run_ui`; `game_hud.gd` solo suena en sus botones.
- **La alarma se repite cada tick** → flag `_radiation_alarm_played`, reseteado
  en `game_reset`.
- **Un botón obsoleto siembra igual** → el panel usa el `bool` que devuelve la
  estación; si es `false`, suena denegación.
- **Mute corta una alerta en curso** → es intencional; el jugador pidió silencio.
- **La rama jugable aún no está integrada en `features`** → el cambio se valida
  en `audio` y se integrará por PR; no se toca `main` ni `features`.
- **Sin subtítulos** → el riesgo de accesibilidad queda documentado como
  follow-up, no oculto.
