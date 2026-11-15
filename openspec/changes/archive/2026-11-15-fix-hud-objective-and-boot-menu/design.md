# Design

## Context

- `game/project.godot` tiene `run/main_scene="res://scenes/base/base.tscn"`;
  el commit `7f20d9e` cambió el arranque para entrar directo al outpost.
- `game/scenes/welcome/welcome.tscn` es la pantalla de entrada; su botón
  "Start game" navega a `res://scenes/worlds/worlds.tscn` (`START_SCENE`).
- En `game/scenes/ui/hud.tscn`:
  - `ClockLabel`: x718–838, y8–24, arriba a la derecha.
  - `TimeControls`: anclado a la derecha, y30–48.
  - `ObjectiveLabel`: x302–548, y62–76, centrado bajo la barra de vida.
- El HUD usa un lienzo fijo de 850×480.

## Goals / Non-Goals

**Goals:**

- Volver a arrancar en el menú sin tocar el flujo worlds → intro → outpost.
- Mover el indicador de misión a la esquina superior derecha, debajo del reloj y
  de los controles de tiempo, sin solapamientos.

**Non-Goals:**

- Cambiar el contenido del menú, el selector de mundos o la intro.
- Reordenar el resto del HUD.
- Tocar la lógica de misión, victoria o balance.

## Decisions

### 1. El arranque vuelve a la pantalla de entrada

`game/project.godot` pasa a
`run/main_scene="res://scenes/welcome/welcome.tscn"`. El menú ya existe y su
acción "Start game" lleva a worlds; no hace falta una escena router.

**Alternativas descartadas:** una escena de boot que decida entre menú y partida
(añade una escena y un paso sin beneficio); dejar el arranque directo y añadir
un botón "Menu" en el outpost (no resuelve la primera impresión y complica la
salida).

### 2. El indicador se alinea a la derecha bajo los controles de tiempo

`ObjectiveLabel` pasa a:

```
offset_left = 638.0
offset_top = 52.0
offset_right = 838.0
offset_bottom = 68.0
horizontal_alignment = 2
```

Queda debajo de `TimeControls` (que termina en y48) y comparte el borde derecho
con el reloj (x838). No invade la tira de recursos (x8–140), la barra de vida
(centrada, x302–592) ni los controles de tiempo. El texto de 8 px
("MISSION  SURVIVE 300h  300h LEFT") cabe en 200 px.

**Alternativas descartadas:** dejarlo bajo la barra de vida (compite con el
centro y fue la queja del usuario); ponerlo arriba a la izquierda (choca con la
tira de recursos); partirlo en dos líneas para ganar ancho (más ruido visual).

## Risks / Trade-offs

- **El texto es más largo que el ancho disponible** → 200 px a 8 px cubren el
  string actual; la captura a 850×480 lo verifica.
- **El menú no era la primera pantalla por otro ajuste** → solo hay un
  `run/main_scene`; se comprueba con `grep` y con un arranque headless.
- **La escena de bienvenida depende de assets ya presentes** → se abre con el
  proyecto actual; la captura del menú lo confirma.

## Migration Plan

Sin persistencia. Se implementa en la rama `win-condition`, se valida con
`check-gdscript.sh`, arranque headless, capturas y `openspec validate --strict`.
Rollback = revertir el commit.
