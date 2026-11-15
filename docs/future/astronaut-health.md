# Futuro: salud del astronauta

- **Estado:** Idea
- **Prioridad:** P2
- **Esfuerzo:** M
- **Depende de:** barra de salud, una estación de ejercicio, `EventLog`
- **Documentos relacionados:** `docs/research/nasa-space-apps-2026-junior-astronaut.md` (§3.6)

## 1. Qué es

Un sistema ligero de salud más allá de la radiación: **hueso, músculo, sueño e inmune**, con el **ejercicio** como contramedida real y visible.

No añade una barra nueva. Usa la salud existente y una **rutina diaria** de una acción:

- **Ejercicio** (1 tick): cuesta O₂, agua y energía; reduce la pérdida de salud.
- **Dormir** (6–8 h): sin coste extra; si no duermes, la salud máxima baja.
- **Beber/comer**: ya existe; ahora afecta también a la recuperación.

## 2. Por qué

- El brief menciona la salud de los astronautas y OSDR; es una fuente NASA que ahora no se usa.
- El ejercicio es una **decisión con coste**: 2,5 h/día es tiempo que no dedicas a reparar o escanear.
- Enseña que la microgravedad no solo es “flotar”: el cuerpo se degrada si no se contrarresta.

## 3. Datos reales que lo anclan

| Magnitud | Valor | Fuente |
| --- | --- | --- |
| Pérdida ósea | **1–1,5 %/mes** en huesos de carga | NASA, *Fundamentals of Human Health* |
| Cuello femoral | hasta **1,5–2,5 %/mes** | NASA NTRS |
| Fuerza muscular | hasta **30 %** de pérdida en misiones largas | NASA NTRS |
| Capacidad aeróbica | **−15 a −22 %** en misiones cortas/largas | NASA NTRS |
| Ejercicio ISS | **2,5 h/día, 6 días/semana** (ARED, T2, CEVIS) | NASA |
| Sueño | ~8 h recomendadas; la ISS tiene ciclos de 24 h | NASA HRP |
| OSDR | OSD-804 (hueso), OSD-471 (hueso), OSD-195 (bed rest), OSD-946 (ejercicio), OSD-53 (genes), OSD-656 (inflamación) | OSDR |

**Lectura para una misión de 12,5 días:** la pérdida es pequeña (~0,4–0,6 % de hueso), pero medible. En el juego no hace falta matar al jugador; basta con que **la salud máxima baje** si no se ejercita, y que el efecto se note en la pantalla de evaluación.

## 4. Cómo funcionaría

### 4.1 Rutina diaria

- Cada “día” (24 ticks) el juego ofrece una rutina de 3 casillas: **ejercicio**, **sueño**, **hidratación**.
- El ejercicio cuesta **1 tick** (1 h de juego; tooltip: “Real ISS: 2.5 h/day”).
- Si se completa la rutina, la salud no decae; si se omite, la salud máxima baja un poco y la recuperación se ralentiza.
- No es un *game over*: es una pendiente. El jugador puede compensar con descanso o comida.

### 4.2 Efectos visibles

- **Salud máxima** (no solo salud actual): 100 % → 95 % → 90 % si no hay rutina.
- **Velocidad de reparación** o **velocidad de escaneo** bajan un 5–10 % con salud baja (hidden stat existente).
- **Pantalla de evaluación:** “Días con rutina: 9/12”; “Salud final: 92 %”.

### 4.3 Tarjetas OSDR

En la consola, una tarjeta por estudio:

- “What NASA learned” (1 frase).
- “What it means for your outpost” (1 frase).
- “Study type” (human / mice / bed rest) para no exagerar.

## 5. Diseño técnico

- `HealthData` (Resource): `bone_loss_per_day`, `muscle_loss_per_day`, `exercise_effect`, `sleep_effect`.
- `GameState.daily_routine`: flags `exercised`, `slept`, `hydrated`.
- `GameSim` aplica la rutina en el tick de cierre del día; `EventLog` registra `exercise`, `sleep`, `routine_complete`.
- No hay barra nueva: la salud existente es el canal.
- UI: una tarjeta pequeña en el HUD o en el panel del astronauta; no un panel nuevo.

## 6. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| Demasiados sistemas para 7–12 | La rutina es **una acción opcional**, no un cuarto recurso |
| Castigar sin explicar | Tooltip con el dato real y el efecto exacto |
| Competir con las reparaciones | El ejercicio cuesta 1 tick, no 2,5 h reales; el jugador elige |
| Confundir salud con radiación | La radiación es acumulativa e irreversible; la salud es recuperable con rutina |
| Estudio animal presentado como humano | Tarjeta con “study in mice” / “bed-rest analog” |

## 7. Criterios de aceptación

- [ ] Existe una acción de ejercicio de 1 tick con coste visible.
- [ ] Omitir la rutina baja la salud máxima de forma gradual, no instantánea.
- [ ] La pantalla de evaluación muestra “días con rutina”.
- [ ] Una tarjeta OSDR explica el hallazgo y su tipo de estudio.
- [ ] Un jugador de 7 años entiende “el cuerpo se debilita si no te mueves” sin leer un párrafo.
