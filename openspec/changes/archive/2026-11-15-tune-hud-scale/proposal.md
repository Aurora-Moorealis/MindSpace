# Proposal

## Why

Las tres piezas del HUD estaban a escalas distintas: la tira de recursos a 2x, y la
barra de vida y la hotbar a 1x. Esa mezcla hace que la esquina superior izquierda
domine y que el resto parezca pequeño y descolgado. Además, los rellenos de las
barras (`TextureProgressBar`) se dibujan a tamaño de textura, así que al reducir
solo el control el relleno se salía del marco.

## What Changes

- Todo el HUD pasa a 1,5x: tira de recursos 132x54, barra de vida 246x36 y hotbar
  216x60 con espacios de 36 px.
- Los cinco rellenos (vida y los cuatro recursos) escalan a 0,75 con el control,
  de modo que quedan dentro de su marco con el mismo margen que el arte.
- Las etiquetas de porcentaje y el reloj del Sol se quedan a 8 px para que sigan
  legibles; solo cambian de sitio.
- Sin cambios en la simulación, el inventario, los paneles ni las especificaciones:
  la disposición y el comportamiento son los mismos, cambia la escala.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

Ninguna. Es un ajuste de escala dentro de requisitos ya cubiertos, por eso el
cambio va con `skip_specs: true`.

## Impact

- `game/scenes/ui/hud.tscn`: geometría de la tira, la barra de vida, el reloj y la
  hotbar, y `scale` en los cinco rellenos.
- `game/scenes/ui/inventory_slot.tscn`: espacio de 36 px.
- `game/scenes/ui/hud.gd` e `inventory_slot.gd`: iconos en la mano y de arrastre a
  24 px.

## Fuera de alcance

- Redibujar el arte a otra escala o cambiar la paleta.
- Controles de velocidad y pausa, prompt, banners y comunicaciones.
- Cambiar la disposición de las cuatro zonas del HUD.
