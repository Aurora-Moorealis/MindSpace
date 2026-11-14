# Selector de misión en el menú

- **Estado:** pendiente
- **Prioridad:** media
- **Depende de:** menú (`scenes/welcome/`), `databases/submissions.tres`

## Objetivo

El diseño formal (`docs/designs/junior-astronauta-outpost-lunar.md`, punto 20)
define la pantalla de entrada como **título + selector de misión**: 1 misión
jugable y 2 filas grises "coming soon".

El menú actual solo tiene "Iniciar juego" y "Configuración". Falta el selector.

## Alcance

- Tres filas de misión debajo de los botones actuales.
- La jugable, seleccionable; las otras dos, en gris con el texto "(próximamente)"
  desde la tabla de strings, **no** hardcodeado.
- "Iniciar juego" arranca la misión seleccionada.
- Las filas grises no son botones deshabilitados sin más: se tienen que poder
  enfocar para leer por qué están grises.

## Criterios de aceptación

- Cambiar de misión con teclado y con ratón.
- La selección se ve claramente (borde teal, como el hover de los botones).
- Las filas grises usan la rampa de grises más oscura, no un color nuevo.

## Notas

Los presets de demo-jump omiten esta pantalla (ver el diseño formal), así que el
selector no debe tener lógica que el resto de escenas necesiten.
