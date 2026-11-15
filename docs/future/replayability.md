# Futuro: rejugabilidad

- **Estado:** Propuesta
- **Prioridad:** P1
- **Esfuerzo:** S/M
- **Depende de:** `events.tres`, `GameSim`
- **Documentos relacionados:** `docs/research/nasa-space-apps-2026-junior-astronaut.md`

## 1. Qué es

Que dos partidas no sean la misma sin romper el núcleo determinista:

- **Semilla de misión** (`mission_seed`) que elige una baraja de eventos.
- **2–3 variantes de tormenta** con distinto aviso, duración y dosis.
- **Barajas** por duración de misión (corta/media/larga).
- **Puntuación final** que compara estrategias entre partidas.

El brief lo pide explícitamente: “Replayability—mechanics or events that vary between playthroughs encourage kids to try different strategies and learn from failure without it feeling punitive.”

## 2. Por qué

- Con eventos fijos, el jugador aprende la secuencia y deja de decidir; con variantes, tiene que leer la situación.
- Es barato: no añade máquinas ni recursos, solo filas y un selector.
- Permite enseñar que **no hay una única estrategia correcta**: a veces conviene refugiarse, a veces arriesgar.

## 3. Cómo funcionaría

### 3.1 Semilla

- Al empezar, el juego genera o recibe `mission_seed` (entero).
- `GameSim` usa un `RandomNumberGenerator` con `seed = mission_seed`.
- La semilla se muestra en la pantalla de evaluación (“Mission seed: 1842”) para reproducir una partida.
- No hay guardado: la semilla es el “save” mínimo.

### 3.2 Barajas de eventos

Cada baraja es una lista de filas de `events.tres` con pesos:

| Baraja | Eventos | Sensación |
| --- | --- | --- |
| `quiet` | 1 tormenta menor, 1 avería, 1 pico de consumo | Tutorial / primera partida |
| `standard` | G5 2024 + avería + eclipse + corte | Partida “de verdad” |
| `harsh` | G5 2024 + SPE 1989 + 2 averías + eclipse | Para veteranos |

La baraja se elige por dificultad, no por aleatoriedad pura. La semilla decide el orden y la severidad dentro de un rango.

### 3.3 Tres tormentas reales

| Evento | Aviso | Dosis | Lección |
| --- | --- | --- | --- |
| **G5 mayo 2024** | 1–2 días | 150–250 mSv sin refugio | El peor caso real; refugiarse |
| **CME oct 2026** | 1–2 días | 0 mSv (no impacta) | No toda alerta es una crisis; no gastes recursos |
| **SPE 1989** | Horas | 250 mSv | El evento de diseño NASA; el refugio es la diferencia |

### 3.4 Puntuación

- **5 contadores** del `EventLog`: informes, submisiones, recursos finales, pico de dosis/refugio, días.
- **Grado** (A–D) por misión, no solo “victoria/derrota”.
- **Récord local** por semilla/dificultad; sin servidores.
- La pantalla de evaluación explica **por qué** se obtuvo ese grado (“te refugiaste a tiempo”, “gastaste energía en el invernadero”).

## 4. Datos reales que lo anclan

- **G5 mayo 2024:** Kp 9,0; X1.6/M9.1/X1.3; CMEs 800–970 km/s; SEP desde 2024-05-09T13:59Z.
- **CME 2026:** 1.048 km/s; no dirigido a la Tierra; Kp ≤3,67.
- **SPE 1989:** evento de diseño de NASA-STD-3001; límite 250 mSv.
- **Dosis lunar:** 0,84 mSv/día; **SPE** 50–250 mSv; **carrera** 600 mSv.

## 5. Diseño técnico

- `MissionDeck` (Resource): `id`, `difficulty`, `event_rows: Array[EventRow]`, `weight_range`.
- `GameSim.start_mission(seed: int, deck: MissionDeck)`.
- `EventScheduler` consume la baraja; no hay aleatoriedad fuera del RNG sembrado.
- `Evaluation` muestra seed, deck y grado.
- Tests: mismo seed + deck → misma secuencia de eventos; seeds distintos → secuencias distintas.

## 6. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| La aleatoriedad rompe el determinismo | Solo el RNG sembrado; nada de `randf()` global |
| El jugador no entiende por qué cambió | Mostrar “Mission seed” y la baraja al empezar |
| Contenido insuficiente | 3 barajas × 3 tormentas = 9 combinaciones; suficiente para el evento |
| Balance entre barajas | La `quiet` no debe ser aburrida; la `harsh` no debe ser imposible |
| Récords sin servidor | `user://records.json`; local, sin cuentas |

## 7. Criterios de aceptación

- [ ] El mismo seed + deck produce exactamente la misma partida.
- [ ] Tres seeds distintos producen secuencias visiblemente distintas.
- [ ] La pantalla de evaluación muestra seed, deck y grado.
- [ ] La baraja `quiet` se puede ganar en la primera partida.
- [ ] La baraja `harsh` se puede perder sin que parezca injusta.
