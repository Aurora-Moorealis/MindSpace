# Proposal

## Why

`features` contiene el núcleo por ticks, las ocho máquinas, la red eléctrica, el
astronauta y el scheduler de eventos, pero la escena jugable solo instancia el
mapa y el astronauta: ni máquinas, ni HUD, ni forma de reparar. El reloj, la
radiación y los eventos corren sin que el jugador pueda leerlos ni actuar. Sin
este cambio no hay loop jugable, solo un paseo por el mapa.

## What Changes

- **Outpost jugable**: las ocho máquinas existen como estaciones sobre la
  plataforma de aterrizaje con textura de reemplazo. El panel solar, la batería y
  los cables alimentan a las consumidoras; cortar un cable cambia el reparto.
- **Zona de refugio**: el recinto del outpost cuenta como interior a efectos de
  radiación; la superficie sigue siendo exterior por defecto, así que alejarse
  cuesta dosis.
- **Panel de máquina**: al pulsar `interact` junto a una estación se abre un panel
  con estado, salud, reparación con progreso y mejoras con su efecto.
- **HUD de partida**: recursos, salud, radiación, hambre, sed, hora y sol,
  velocidad y pausa; banner del evento activo y aviso de comunicaciones cortadas.
- **Controles de tiempo**: acciones `speed_up`, `speed_down` y `pause` con los
  multiplicadores ×1/×5/×10 ya existentes.
- **Hidroponía determinista**: el crecimiento de las doce celdas pasa a depender
  del tick en vez de `Time.get_ticks_msec()` y `randf()`, con su panel en la
  estación.
- **Evaluación y fin de misión**: pantalla final con los cinco contadores del
  ledger y un botón de depuración que fuerza el fin de misión.

## Capabilities

### New Capabilities

- `outpost`: estaciones en el mundo jugable, refugio y red eléctrica construida
  desde ellas.
- `game-hud`: overlay de la partida, controles de tiempo y avisos de evento.
- `hydroponics`: crecimiento determinista por tick de las celdas y su panel.
- `evaluation`: pantalla de fin de partida con los contadores del ledger.

### Modified Capabilities

- `machines`: el panel hace accionables la reparación y las mejoras que la spec
  ya define.
- `astronaut`: zona de refugio que anula la exposición y exterior por defecto.
- `game-session`: exposición según refugio, pantalla de evaluación al terminar y
  fin de misión forzado.

## Impact

- **Código nuevo**: `game/scenes/ui/`, `game/scenes/evaluation/`,
  `game/content/machines/machine_station.tscn`,
  `game/content/machines/hydroponics/` (estado y panel) y
  `game/content/outpost/`.
- **Código modificado**: `game/scenes/base/base.gd` y `base.tscn`,
  `game/content/machines/machine_base.gd`, `solar_array.gd`,
  `game/content/entities/astronaut/astronaut.gd`, `game/project.godot`.
- **Datos**: la hidroponía añade la fila `hydroponics_harvest_food` con la comida
  por cosecha; los intervalos de crecimiento son constantes del sistema.
- **Sin tocar**: el diseño de `docs/designs/`, el generador lunar, el scheduler
  de eventos y las escenas de otros módulos.
- **Dependencia**: no depende de `base-and-craters`; cuando esa rama entre, solo
  hay que mover posiciones.

## Fuera de alcance

- Consola, escaneo de POIs, informes y submisiones: aplazados; no hay victoria
  por informes.
- Base de cinco salas, muros, airlock y cráteres visibles: pertenecen a
  `base-and-craters`.
- Arte definitivo de las estaciones: se entregan con textura de reemplazo.
- Persistencia, guardado de partida y presets de demo.
- Datos NASA verificados y badges de procedencia en pantalla.
