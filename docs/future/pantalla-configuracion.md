# Pantalla de configuración

- **Estado:** pendiente
- **Prioridad:** media
- **Depende de:** `scenes/welcome/`

## Objetivo

El botón "Configuración" del menú hoy solo avisa de que no existe. Falta la
pantalla real.

## Alcance mínimo

- Escena `scenes/settings/settings.tscn` con el mismo fondo y el mismo estilo de
  panel metálico que el menú.
- Ajustes que de verdad se puedan ofrecer en un juego de 36 h:
  - **Volumen** (música / efectos) → `AudioServer.set_bus_volume_db`.
  - **Pantalla completa** → `DisplayServer.window_set_mode`.
  - **Velocidad de simulación por defecto** (×1 / ×5 / ×10) → afecta a
    `game_sim`.
- Botón "Volver" al menú.
- Sin persistencia al principio: se aplica en la sesión. Guardar ajustes es una
  tarea aparte (y el diseño descarta guardado de partida, no de opciones).

## Criterios de aceptación

- Se entra y se sale con ratón y con teclado (focus con flechas/Enter).
- Los valores por defecto se ven correctamente la primera vez.

## Notas

No añadir opciones que el juego no use: en una demo de 2–5 minutos un ajuste
muerto resta credibilidad.
