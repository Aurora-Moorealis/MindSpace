# Proposal

## Why

El proyecto arranca sin escena principal y sin arte conectado: no hay forma de
que el jugador entre al juego. El arte base ya existe (fondo lunar y los dos
cohetes), así que el coste de tener una pantalla de entrada presentable ahora es
bajo y desbloquea todas las fases siguientes.

Es también la primera pantalla que valida el pipeline visual completo: fuente de
píxel, paneles nine-patch y escalado entero conviviendo con el arte de 425×240.

## What Changes

- Nueva escena de entrada `scenes/welcome/welcome.tscn` con el fondo lunar a
  pantalla completa, título, subtítulo y dos acciones.
- Acción **Iniciar juego** y acción **Configuración**. Como sus destinos todavía
  no existen, ambas muestran un aviso temporal en vez de quedar inertes.
- Tema compartido `themes/pixel_theme.tres` con la fuente Silkscreen y los estilos
  de botón (normal, hover con borde teal, pulsado).
- Paneles metálicos nine-patch generados con Aseprite en `assets/images/ui/`.
- Ajustes de proyecto para pixel art: filtro de textura Nearest, aspecto fijo
  `keep` y escalado entero.

## Capabilities

### New Capabilities

- `menu`: pantalla de entrada del juego. Cubre el arranque, las acciones
  principales, el aviso cuando una acción no tiene destino y la nitidez del arte.

### Modified Capabilities

- Ninguna. No hay specs previas en el proyecto.

## Impact

- **Escenas:** `game/scenes/welcome/welcome.tscn` y `welcome.gd`.
- **Tema:** `game/themes/pixel_theme.tres`.
- **Assets:** `game/assets/fonts/silkscreen/` (Silkscreen + OFL) y
  `game/assets/images/ui/` (tres paneles de botón).
- **Configuración:** `game/project.godot` (escena principal, stretch y filtro).
- **Documentación:** `docs/guia-estetica.md` y `docs/future/`.
- No toca simulación, datos ni autoloads.

## Fuera de alcance

- El selector de misión del diseño formal (`docs/future/selector-mision.md`).
- La pantalla de configuración real (`docs/future/pantalla-configuracion.md`).
- Los paneles de intro (`docs/future/intro-stills.md`).
- Textos localizados: el menú usa literales provisionales.
