# Proposal

## Why

El diseño formal (`docs/designs/junior-astronauta-outpost-lunar.md`) da a la base
lunar un panel solar y una batería, pero no existe un contrato de cómo se conectan.
Hoy la energía es un único depósito global: el panel carga aunque no haya batería
y cualquier máquina consume aunque no esté conectada a nada. Eso elimina el
trade-off que el juego quiere enseñar (generar, almacenar y repartir) y no permite
construir el panel, la batería ni el cable que el jugador debe tocar.

Este cambio define la red eléctrica, crea los dos edificios y el cable que los une,
e integra los tres en el núcleo de simulación.

## What Changes

- Nueva capability `energy-grid`: nodos de energía, cables, redes conectadas,
  carga por batería, producción solar y reparto por red.
- La simulación deja de tratar la energía como un depósito único. Pasa a leer
  baterías conectadas y a apagar máquinas **por red**, no todas a la vez.
- Nuevo contenido en `game/content/machines/`: `solar_array`, `battery` y
  `power_cable`, con sus escenas, scripts y arte pixel-art.
- Nuevas filas y arte de cable: atlas de 16 losetas de 16×16 (arte) con las
  conexiones ortogonales y un TileSet de 32×32 de pantalla.

## Capabilities

### New Capabilities

- `energy-grid`: nodos, cables, redes, baterías, producción solar y apagado por
  red.

### Modified Capabilities

- `simulation-core`: los requisitos "Producción y consumo de recursos" y
  "Apagado por falta de energía" pasan a hablar de baterías y de redes.

## Impact

- `game/scripts/simulation/power_link.gd`, `power_network.gd`, `power_grid.gd`.
- `game/scripts/simulation/sim_state.gd`, `sim_tick.gd`.
- `game/scripts/autoloads/game_sim.gd` (enlaces y señal de red).
- `game/content/machines/machine_base.gd`,
  `solar_array/{solar_array.tscn,solar_array.gd,solar_array.png}`,
  `battery/{battery.tscn,battery.gd,battery.png}` y
  `power_cable/{power_cable.tscn,power_cable.gd,power_cable_atlas.png,power_cable_tileset.tres}`.
- `art/sprites/machines/build-energy.lua` (generador Aseprite) y los maestros
  `.aseprite`.
- `game/scripts/dev/sim_smoke.gd` gana comprobaciones de red; las existentes
  siguen pasando porque la base arranca pre-cableada en una sola red.

## Fuera de alcance

- Construcción pieza a pieza (colocar/quitar edificios): el cable se coloca entre
  dos nodos existentes, no hay modo construcción.
- Tendido automático de cable por el mapa, cruces de sala y presupuesto de longitud.
- Interfaz de la red (panel de reparto, prioridades manuales y gráfico de carga):
  la energía se sigue mostrando en la barra del HUD.
- Varias baterías con políticas de carga distintas; todas comparten las mismas
  reglas y filas.
- Arte de ruptura, chispas o animación de carga: solo estados estáticos.
- Persistencia de la red y de los enlaces entre partidas.
