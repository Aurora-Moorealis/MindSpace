# Design

## Context

Diagnóstico medido con la economía real y `is_outside = false`:

- Carga total de las máquinas: **1.9/tick** (luces 0.2, hidropónica 0.4,
  reciclador 0.4, O₂ 0.5, taller 0.1, consola 0.2, refugio 0.1).
- Panel solar: **1.5/tick** de día; noche de 12 ticks sin producción.
- Batería inicial: **5/10**.
- Tick 12: energía a 0 → blackout y apagado de luces → hidropónica →
  reciclador → O₂.
- Las máquinas no se vuelven a encender: `_apply_energy_consequences()` solo
  apaga; cuando la carga vuelve, limpia el flag de blackout y sigue.
- O₂/agua/comida a 0 hacia el tick 108–113; reserva del traje a 0 en 172; muerte
  por hipoxia en el **tick 210**.
- Bajar la misión a 200 haría ganar al run pasivo, pero con la base apagada
  desde el tick 12. No se considera una solución.

Ver `proposal.md` para la motivación. La victoria a 300 ticks ya existe
(`add-mission-victory`); este cambio la hace alcanzable.

## Goals / Non-Goals

**Goals:**

- Que la base pueda recuperarse de un blackout cuando vuelve a tener carga.
- Que un run pasivo, sin eventos, llegue vivo al tick 300 con la economía real.
- Mantener la escalera de apagado y el orden determinista.

**Non-Goals:**

- Añadir un toggle manual de energía.
- Cambiar el consumo de las máquinas o la producción de O₂/agua/comida.
- Cambiar la duración de misión ni el HUD/evaluación.

## Decisions

### 1. La recuperación es el espejo del apagado

En `game/scripts/simulation/sim_tick.gd`, `_apply_energy_consequences()` llama a
`_restore_machines()` cuando `network.total_charge(state) > 0.0`. La función
recorre `SimState.BLACKOUT_ORDER` al revés (O₂ → reciclador → hidropónica →
luces) y enciende como máximo `blackout_steps_per_tick` máquinas por tick,
saltando las que ya están encendidas y las averiadas.

No se añade estado nuevo: `MachineState.powered` ya distingue encendida/apagada
y el orden es una constante. La recuperación ocurre después de consumos, así que
la máquina encendida no consume hasta el tick siguiente; eso evita un doble
cobro en el mismo tick y hace la regla fácil de testear.

**Alternativas descartadas:** encender todas a la vez (puede vaciar la batería
de golpe y producir un ciclo apagón/encendido); un flag `restoring` en
`SimState` (estado redundante); un toggle manual en el panel (es una feature de
UI aparte y no la pidió el usuario). Bajar la misión a 200 (victoria en una base
muerta).

### 2. El balance sube el techo solar y la batería, no el consumo

Se editan dos filas de economía:

- `game/databases/economy_rows/solar_output_per_tick.tres`: 1.5 → **4.0**.
- `game/databases/economy_rows/capacity_energy.tres`: 10 → **26**.

La producción se aplica antes del consumo, así que al final del día la batería
queda en `capacidad − 1.9`, no en `capacidad`. Con 24 el fin de día es 22.1 y la
noche consume 22.8: falta 0.7 y hay un blackout de un tick cada noche. Con 25 el
fin de día es 23.1 y sobran 0.3; con **26** el fin de día es 24.1 y sobran 1.3,
que reproduce el margen de 1.2 que buscaba el diseño. El ciclo es estable sin
tocar las máquinas ni el consumo, y un run pasivo llega al tick 300.

Se mantiene `initial_energy = 5`: el primer día llena la batería antes de la
primera noche. Si el jugador no repara una avería del panel, la batería se vacía
y el blackout vuelve; la recuperación lo enciende cuando el panel vuelva a
producir. Los eventos siguen creando trabajo.

**Alternativas descartadas:** bajar el consumo de las 7 máquinas (toca 7 fichas
y cambia la sensación de todas las máquinas); subir solo `initial_energy` (no
arregla el déficit estructural de 0.4/tick); añadir una fuente de energía nueva
(más contenido y arte).

### 3. Tests

`game/scripts/dev/sim_smoke.gd`:

- `_check_300_ticks` pasa a exigir `run_result == VICTORY` con la economía real
  (sin eventos), no solo `game_over`.
- Nuevo `_check_blackout_recovery`: fuerza un blackout (batería a 0), comprueba
  que las máquinas de `BLACKOUT_ORDER` quedan apagadas; devuelve carga a la
  batería, avanza ticks y comprueba que se encienden en orden inverso, una por
  tick, y que una máquina averiada no se enciende.
- `_check_mission_defeat` (radiación exterior) sigue igual: la recuperación no
  salva una muerte por dosis.

`machines_smoke.gd` solo se toca si alguna expectativa fija de energía deja de
cumplirse; el conteo de filas de economía no cambia (55).

### 4. Hambre y sed duran la misión completa

Se editan `hunger_drain_per_tick.tres` y `thirst_drain_per_tick.tres`: 0.5 →
**0.3**. Con 100 puntos, el drenaje actual llega a 0 en el tick 200 y el daño de
inanición/deshidratación mata en el 249 aunque la energía sea perfecta. Con 0.3
los 100 puntos duran 333 ticks: al llegar al 300 quedan 10. No hay mecánica de
comer/beber en el repo y añadirla es otro cambio; el baseline pasivo debe poder
ganar. La comida y el agua siguen importando si la hidropónica o el reciclador
se averían.

**Alternativas descartadas:** añadir comer/beber (UI/items nuevos, fuera de
alcance); subir `player_max_hunger`/`player_max_thirst` (el máximo de la fila es
100 y habría que tocar el esquema); dejar 0.5 (victoria inalcanzable sin la
mecánica de comer).

## Risks / Trade-offs

- **La base se vuelve demasiado autosuficiente** → el run pasivo gana, pero los
  eventos, la radiación exterior y las averías siguen siendo la fuente de
  tensión; el objetivo del cambio es que la victoria sea alcanzable, no que sea
  difícil.
- **Recuperación en ciclo si la batería está justa** → el margen de 1.2/tick y
  el límite de una máquina por tick evitan el encendido brusco; el test de
  recuperación lo verifica.
- **`machines_smoke` con valores fijos** → lee `solar_output_per_tick` y
  `capacity_energy` del registro, no los hardcodea; se ejecuta como regresión.
- **La spec de apagado sigue diciendo que una máquina apagada no produce** → la
  recuperación solo cambia `powered`; el tick siguiente ya aplica producción y
  consumo normalmente.

## Migration Plan

Sin persistencia. Se implementa en la rama `win-condition`, después de
`add-mission-victory`, y se valida con `sim_smoke`, `machines_smoke`, el checker
estricto y un arranque headless. Rollback = revertir el commit; no hay datos que
migrar.
