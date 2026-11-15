# Proposal

## Why

Al abrir el panel de una máquina, el HUD se queda por encima: la tira de recursos
tapa el título del panel y la hotbar se cuela entre sus botones. Además, la barra
de vida y la hotbar siguen siendo más grandes de lo que pide su peso en pantalla.

## What Changes

- El HUD se oculta mientras hay un panel de máquina abierto y vuelve al cerrarlo,
  igual que ya ocurre con el resumen de misión.
- El botón de depuración de fin de misión también se oculta con el panel.
- La barra de vida pasa a 164x24 y la hotbar a 144x40 con espacios de 24 px, es
  decir, el arte al 1x en lugar del 2x actual.
- Sin cambios en la simulación, el inventario ni los datos del panel.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `game-hud`: el HUD se retira cuando una interfaz modal (panel de máquina) está
  abierta y reaparece al cerrarse.

## Impact

- `game/scenes/ui/hud.gd`: banderas de partida terminada e interfaz abierta.
- `game/scenes/ui/run_ui.gd`: observa la visibilidad del panel de máquina.
- `game/scenes/ui/hud.tscn` e `inventory_slot.tscn`: geometría al 1x.
- `game/scenes/ui/inventory_slot.gd`: tamaño de la vista previa de arrastre.

## Fuera de alcance

- Controles de velocidad y pausa, prompt de interacción, banners y comunicaciones:
  siguen pospuestos.
- Rediseñar el arte del HUD o de los paneles.
- Igualar el tamaño de la tira de recursos con el de la barra de vida.
