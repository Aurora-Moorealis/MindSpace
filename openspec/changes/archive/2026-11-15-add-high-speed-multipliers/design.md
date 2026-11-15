# Design

## Context

- `GameSim.Speed` = `X1, X5, X10`; `get_rate()` devuelve 1/5/10.
- `SECONDS_PER_TICK = 60`; `MAX_TICKS_PER_FRAME = 10`.
- El HUD pinta el multiplicador en `ClockLabel` (x718–838) y en
  `SpeedValue` (26 px de ancho dentro de `TimeControls`, 140 px), y recorre
  x1 → x5 → x10 con `_step_speed`.
- La misión dura 300 ticks; a x10 son 30 minutos reales, demasiado para probar
  el final. El usuario pide x100, x1000 y x10000.

## Goals / Non-Goals

**Goals:**

- Añadir los tres multiplicadores altos sin cambiar la duración del tick.
- Que el HUD muestre y seleccione los seis valores sin recortes.
- Que un frame pueda procesar los ticks de x10000 sin quedarse atrás.

**Non-Goals:**

- Cambiar la simulación, el render o el flujo de escenas.
- Añadir un desplegable o botones directos de velocidad.
- Un modo fast-forward visual (solo avanza el reloj).

## Decisions

### 1. Los multiplicadores son valores del enum y de `get_rate`

Se añaden `X100`, `X1000` y `X10000` al enum, y `get_rate()` devuelve 100.0,
1000.0 y 10000.0. El resto del código que consume `GameSim.speed` solo compara
con `X1/X5/X10` en el HUD (`_speed_text` y `_step_speed`), que se amplía.

**Alternativas descartadas:** un `float` de velocidad libre (rompe el patrón de
enum y permite valores no representables en el HUD); un desplegable nuevo (más
UI y arte para una acción que ya tiene botones).

### 2. El cap de frame sube a 400 ticks

A x10000, 60 s reales / 10000 = 0,006 s por tick; a 60 fps eso son ~167 ticks
por frame, y a 30 fps ~333. `MAX_TICKS_PER_FRAME = 400` cubre ambos sin dejar
crecer el acumulador. Sigue siendo un tope de seguridad: si un frame rinde menos
de 30 fps, el sobrante se acumula y se recupera en frames siguientes.

**Alternativas descartadas:** quitar el cap (riesgo de bucle de muerte si el
frame se alarga); cap proporcional a la velocidad (más código para el mismo
resultado); bajar `SECONDS_PER_TICK` en los modos altos (rompe la regla de que
el tick siempre es 1 hora de juego).

### 3. El HUD ensancha el reloj y el marcador

- `ClockLabel.offset_left`: 718 → **690** (148 px) para
  `SOL 1  DAY  00:00  x10000`.
- `SpeedValue.custom_minimum_size.x`: 26 → **40**; `TimeControls` sigue en
  140 px (18 + 40 + 18 + 46 + 9 de separación = 131).
- `_speed_text()` añade `x100`, `x1000`, `x10000`.
- `_step_speed()` encadena X1 → X5 → X10 → X100 → X1000 → X10000 y al revés.
  En X10000, subir no hace nada; en X1, bajar no hace nada.

**Alternativas descartadas:** abreviar `x10k` (el usuario pidió x10000 y el
reloj tiene espacio); mover el objetivo de misión (ya está debajo y no choca).

## Risks / Trade-offs

- **A x10000 el frame puede costar más de 16 ms** → el cap de 400 evita el
  bucle de muerte; el reloj avanza en dos frames y la simulación es ligera.
- **El acumulador crece si el frame baja de 30 fps** → el sobrante se recupera
  en frames posteriores; no se pierde ningún tick.
- **El texto `x10000` se recorta** → anchos ampliados y captura a 850×480.
- **`clock_check.gd` local está desactualizado** (52 filas, cap 10) → se
  actualiza como prueba ignorada, no se commitea.

## Migration Plan

Sin persistencia. Se implementa en `win-condition`, se valida con
`clock_check`, `check-gdscript.sh`, arranque headless y captura; después se
archiva y se commitea.
