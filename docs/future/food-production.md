# Futuro: producción de comida

- **Estado:** Propuesta
- **Prioridad:** P2
- **Esfuerzo:** M
- **Depende de:** invernadero, `economy.tres`, UI
- **Documentos relacionados:** `docs/research/nasa-space-apps-2026-junior-astronaut.md` (§3.7)

## 1. Qué es

Dar al invernadero un papel **realista** en una misión corta: no es la fuente de calorías, es la fuente de **frescura, vitaminas y moral**.

La comida base sigue siendo empaquetada; el invernadero produce **microgreens** (10–14 días) y, si la misión se alarga, lechuga (28 días). Nunca promete alimentar a la tripulación solo.

## 2. Por qué

- El diseño actual hace que el invernadero produzca comida por tick; con una misión de 12,5 días y un cultivo de 28, eso no es real.
- El brief pide “food production” como una de las demandas; la solución honesta es mostrar **por qué es difícil**.
- El CSA y la agricultura de ambiente controlado (CEA) son recursos oficiales del desafío; usarlos sube *Relevance*.

## 3. Datos reales que lo anclan

| Dato | Valor | Fuente |
| --- | --- | --- |
| Calorías diarias | **1.900–3.200 kcal** según tripulante | CSA |
| Comida empaquetada | **2,39 kg/persona/día** | NASA BVAD |
| Sólidos de comida | **0,62 kg/persona/día** | NASA NTRS |
| Lechuga Veggie | ~28 días | NASA |
| Microgreens | ~10–14 días (estimación hortícola) | — |
| Patata | ~90–120 días | Horticultura |
| CEA / Deep Space Food | Agricultura de ambiente controlado | CSA |

**Lectura para el juego:** en 12,5 días, el invernadero puede dar **2–3 cosechas de microgreens**; no puede dar las ~7,75 kg de comida sólida que necesita una persona. La lección es “**la comida es logística; la frescura es un lujo que hay que cultivar**”.

## 4. Cómo funcionaría

### 4.1 Recurso “frescura” (hidden stat)

- El invernadero produce `fresh_food` (0–100), no “comida”.
- `fresh_food` alto → la salud máxima no baja por nutrición; `fresh_food` bajo → penalización pequeña y lenta.
- La barra de comida sigue siendo la comida empaquetada; el invernadero no la llena.
- Tooltip: “Fresh food: vitamins and morale, not calories.”

### 4.2 Costes

- **Agua:** riego y transpiración; el reciclador recupera parte.
- **Energía:** lámparas LED; el consumo compite con el sistema de O₂.
- **Tiempo:** plantar/cosechar cuesta ticks.
- **Riesgo:** plague/hongos/fallo de lámpara → cosecha perdida.

### 4.3 Eventos

- **Fallo de lámpara:** la cosecha se retrasa; el jugador decide si gasta energía en repararla.
- **Plaga:** pérdida de una cosecha; cuesta agua/tiempo.
- **Cosecha récord:** pequeña recompensa de moral/salud.

## 5. Diseño técnico

- `FoodData` (Resource): `calories_per_day`, `packaged_mass_per_day`, `crop_cycle_days`, `fresh_food_yield`, `water_per_crop`, `power_per_crop`.
- `GameState.fresh_food: float` (0–100); `GameSim` aplica crecimiento por tick.
- `EventLog` registra `harvest`, `crop_failure`.
- UI: una tarjeta en el panel del invernadero; no una barra nueva en el HUD.
- Datos: `game/databases/food.tres`; fuentes en `game/databases/sources/`.

## 6. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| El jugador espera que el invernadero dé comida | Tooltip y tarjeta de datos lo explican desde el primer minuto |
| Una barra nueva satura el HUD | `fresh_food` es hidden stat; solo se ve en el panel del invernadero |
| El ciclo de 28 días no cabe | Microgreens de 10–14 días; la lechuga es una mejora de misión larga |
| El coste de energía hace inútil el invernadero | Que la penalización por no tener frescura sea pequeña; es un lujo, no una obligación |
| Datos de microgreens no son NASA | Etiquetar “estimate”, no “NASA data” |

## 7. Criterios de aceptación

- [ ] El invernadero no llena la barra de comida.
- [ ] Producir frescura cuesta agua/energía/tiempo de forma visible.
- [ ] Una cosecha perdida se puede recuperar; no es *game over*.
- [ ] La tarjeta de datos distingue “calorías” de “vitaminas/frescura”.
- [ ] El tooltip dice si el dato es NASA o una estimación.
