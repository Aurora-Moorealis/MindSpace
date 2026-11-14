# Goldfish Review — Stage 5: Initial Zoom Out

**Target:** `docs/designs/junior-astronauta-outpost-lunar.md` (full file, líneas 1–464)
**Estándar:** `resources/document_standards/zoom-out-standard.md` (lente zoom-out); lente TRIZ sin estándar asignado.
**GoldfishContext:** ninguno (lista vacía).

## Reviewer Status

| Reviewer | Status |
| --- | --- |
| `egm-zoom-out` | completed |
| `egm-inventive-catalyst` | completed |

Nota del reviso zoom-out: el repo fue re-verificado (`game/` greenfield; `.egm/` con brief + 14 reportes; citas internas veraces). El brief y la revisión R2 previa contradicen varias afirmaciones de este documento (detalladas abajo).

## Prioritized Findings (Blockers → Majors → Nits)

### B1. La submisión "5 informes totales" es inalcanzable por construcción — Severity: Blocker

- **Reviewer Lens:** `egm-zoom-out` + `egm-inventive-catalyst` (M4).
- **Affected Scope:** "Misión, submisiones y tutorial" (línea 153), "Archivos §13" (líneas 367–371), CUJ 3 (línea 71), CUJ 5 (línea 84).
- **Discrepancy Description:** victoria se dispara *inmediatamente* al 3er informe, y solo existen 3 POIs. La condición `total_reports_sent = 5` de la 4ª submisión solo puede completarse en freeplay *después* de haber ganado, e incluso entonces solo se vería en una segunda evaluación si el jugador muere después. El 25% del presupuesto de contenido de submisiones es muerto; paneles adyacentes le dicen al niño "envía 5 informes" mientras la misión dice que 3 ganan. Además, las otras filas presuponen generadores sin definir en el documento (¿de dónde salen las "muestras"? ¿la "lectura" la produce el escaneo?).
- **Rationale & Recommendation:** o bajar el umbral a ≤3 (lo que degenera con la victoria → cortarla), o hacer los informes repetibles por POI manteniendo victoria = "3 POIs únicos informados", o declarar la fila explícitamente post-victoria ("designed"). Hoy es una decisión de rediseño en el gate H24; es barato corregirla ahora.

### M1. Los presets de demo se pudren por *significado*, y el validador no puede verlo — Severity: Major

- **Reviewer Lens:** `egm-inventive-catalyst` (M1); `egm-zoom-out` confirma que la afirmación "resuelto por captura+validador" es parcialmente falsa.
- **Affected Scope:** "Demo para el juez" (157–159), CUJ 4 (75–79), swaps (258), validador (159, 439).
- **Discrepancy Description:** el validador prueba solo invariantes de carga ("sin cascada de muerte"). El re-horneado a H25–26 y los swaps en sesiones de pares hasta H27 dejan una ventana de un día donde estados semánticamente viejos pasan toda auditoría: el preset "mitad de partida" con 40% de agua cuando H26 encareció el agua; "hora final" vivo al 60% de dosis cuando una fila nueva habría matado al 45%; números del preset en desacuerdo con las tarjetas de fuente justo en el panel que se juzga por procedencia.
- **Rationale & Recommendation:** la validación de forma no detecta estados imposibles-pero-bien-formados. (a) Mínimo: mover el re-horneado de H25–26 a **H27 post-hard-lock** (edición de datos en fase data-only; minutos) y añadir un paso de coherencia a `DataAudit` comparando los POD del preset contra las filas vigentes; (b) ideal: capturar el preset como **journal de inputs** (extensión de lo que ya loggea EventLog: reparaciones, escaneos, airlocks) y re-derivar el estado con replay headless bajo las filas actuales — a prueba de pudrición por construcción, reusando el boot headless que ya existe.

### M2. Los costes del jugador viven en dos dominios de tiempo; el multiplicador cambia el precio del trade-off central — Severity: Major

- **Reviewer Lens:** `egm-inventive-catalyst` (M2).
- **Affected Scope:** loop del tick (139–141) vs. barra de escaneo (48, 153, 404), multiplicadores (115), dosis (147–149).
- **Discrepancy Description:** todo es sub-tick salvo la reparación (1–2 ticks), pero el escaneo es una barra de 3 s **en tiempo real** mientras dosis EVA y O₂ se cobran **por tick**. A ×1, 3 s ≈ 0.05 ticks; a ×10 ≈ 0.5 ticks: el coste didáctico del EVA cambia un orden de magnitud según qué multiplicador mire el juez. Tampoco se dice si cruzar el airlock a T+0.9 paga el tick completo, ni en qué paso del pipeline aterriza la finalización de una reparación.
- **Rationale & Recommendation:** una sola moneda de tiempo: cola de **compromisos** en `GameSim` — escaneo/reparación/limpieza se comprometen sub-tick y se resuelven en el límite del tick T+N; dosis/O₂ se cobran por tick comprometido en zona. La barra de 3 s pasa a ser indicador de progreso en ticks ("escaneo listo para la próxima hora"), y cancelar = descomprometer. Declarar además (determinismo): la reparación resuelve en el límite del tick N y sus efectos aplican desde N+1.

### M3. `DataAudit` viola "cuatro, y solo cuatro" y es ciego a la pérdida de datos — Severity: Major

- **Reviewer Lens:** `egm-zoom-out` (M3) + `egm-inventive-catalyst` (M3).
- **Affected Scope:** Autoloads (95) vs. Modelo de datos (125), ítems 25 y 26 (436–446); restricción 4 (22), reglas de integración (180).
- **Discrepancy Description:** (1) `DataAudit` como quinto autoload contradice el contrato propio del documento y re-importa el riesgo de export-strip que este repo ya sufrió (SceneTime, autoload MCP); un `tool` script invocado por el wrapper de `check-gdscript.sh` hace las mismas aserciones sin tocar `[autoload]`. (2) El audit valida **forma** (ids únicos, refs, rangos, procedencia) pero no prueba que el dato **llegó**: una fila perdida en un merge de `.tres` produce datos con pinta válida y pasa; la pérdida de filas es la firma del fallo de merge y mata el criterio de procedencia en silencio.
- **Rationale & Recommendation:** `DataAudit` = script `tool`/headless invocado por el checker (no autoload). Añadir contadores monotónicos por registro (`row_count`, versión; decrementos solo DevGreem pre-H12) y asertar "filas nunca decrecen, ids jamás reutilizados"; durante H24–27, swaps de una-fila-por-commit para encoger la superficie de conflicto.

### M4. El exterior sigue programado antes de su propio gate; el fallback sigue sin spec; "cero horas hundidas" es falsable y falso — Severity: Major

- **Reviewer Lens:** `egm-zoom-out` (M1) + `egm-inventive-catalyst` (N2).
- **Affected Scope:** Alternativa 2 (194–198), bloque H8–12 (291), gate H12 (459).
- **Discrepancy Description:** el documento declara adoptada la inversión de orden, pero su plan pone escaneo y consola en el mismo bloque sin orden interno, con el gate que podría cortar el exterior *después* de esas horas. La vía de fallback ("informes solo desde consola") sigue sin definir qué genera los informes sin exterior (señalado ya en la R2). Y "cero horas hundidas" solo sería cierto si "victoria = 3 informes" y los targets de misión fueran filas de datos — el documento nunca los declara como filas: el corte de emergencia re-author submisiones y textos del tutorial (~1 h).
- **Rationale & Recommendation:** ordenar consola→escaneo dentro del bloque; escribir el párrafo del fallback en H1; mover "victoria = N informes" y los targets de misión a filas de `economy/mission` para que el corte sea edición de datos.

### M5. "Ensayo de H34" no existe en un marco de 36 horas — Severity: Major

- **Reviewer Lens:** `egm-zoom-out` (M2).
- **Affected Scope:** "Demo para el juez" (159: "el ensayo de H34"), vs. Resumen/Problema (~36 h), gates solo H8/H12/H24/H28.
- **Discrepancy Description:** a H34 no queda evento; son 6 horas muertas tras el golden. La afirmación de calendario no sobrevive contacto con la realidad; el brief usa H28–32.
- **Rationale & Recommendation:** mover el ensayo a H28–32 o explicitar horas por persona.

### M6. La aritmética H0–4 no se cierra: el único dev también dibuja y el coste del núcleo es el único sin precio — Severity: Major

- **Reviewer Lens:** `egm-zoom-out` (M4).
- **Affected Scope:** bloque H0–4 (291), ítem 1 GameSim (295–299), ítem 18 (399: "una máquina más ~2–4 h" — el núcleo nunca se preció); arte del dev ausente del documento (el brief lo cubre con CC0, aquí ni se menciona).
- **Discrepancy Description:** el trabajo de mayor riesgo (ciclo determinista + validación + captura) va en el primer cuarto del evento sin presupuesto propio, y el doc preció lo barato (máquinas) y silenció lo caro (motor + arte del propio dev).
- **Rationale & Recommendation:** una línea de presupuesto honesto para GameSim (con su fallback de alcance si se desliza) y mencionar el plan de arte CC0 dentro del documento, no solo en el brief.

### M7. Cuatro recursos congelados antes de la primera señal de playtest; el fallback está diseñado como corte, no como kernel — Severity: Major

- **Reviewer Lens:** `egm-inventive-catalyst` (M5).
- **Affected Scope:** escalera (141), Alt. 3 (200–204), Q1 (45), playtests (460).
- **Discrepancy Description:** el split comida/agua se apuesta a valores de papel congelados en H1; la única ventana de tuning es H24–27 sin evidencia previa; y el fallback H12 "comida+agua → provisiones" está diseñado como una *remoción de feature* (barras construidas H8–12, strings, hint_text, presets capturados) — justo cuando remover es más caro.
- **Rationale & Recommendation:** construir el fallback primero (**Inversion**): capa de recursos como filas sobre un kernel interno de "sustento" (producción en paquetes, drenajes por barra como filas); el merge H12 pasa a ser **un edit de registro**, no un corte de features. Añadir una prueba base headless de 300 ticks sin input (política solo-supervivencia) como probe de `DataAudit` desde H4: el balance gana un instrumento de alerta temprana y el freeze H1 deja de ser una apuesta ciega.

## Nits (consolidadas)

1. **N1 — Hidden stats resucitadas contra el disenso registrado** (Alt. 8, Q6): el patrón "la guardamos por si una mejora la toca" es exactamente el YAGNI que esta lente debe marcar; empezar en 0 stats y añadir solo cuando una mejora lo exija.
2. **N2 — Selector con 2 opciones grises "coming soon"** (Q5, ítem 20): escaparate UI para una fantasía que está en No-Metas; se poda en 30 min.
3. **N3 — Tres superficies de verificación solapadas** (render de filas en runtime, DataAudit, overlay debug): los gates pueden consumir la salida de DataAudit; consolidar.
4. **N4 — `StringTable` con llaves-enum para un juego monolingüe** (ítems 10, 15): indirección sin amortización; strings `@export` en las escenas UI o un `.tres` plano.
5. **N5 — Dependencias entre documentos sin definición local** ("pedir recursos" y el loop lectura/muestra/informe no se explican en este documento): una frase por objeto lo cierra.
6. **N6 — "Jolt + Web sin incidencia conocida"** (NFR, 266): hedge sin sujeto en un juego 2D; decir que Jolt solo afecta 3D o no mencionarlo.
7. **N7 — ítem 27 (README)**: ruido como entrada numerada de un plan de 36 h; línea suelta en H28+.
8. **N8 — Freeze de schema H12 no cubre los `.tres` locales de máquinas** (`content/machines/*/*.tres` escritos H4–8): congelar cada uno desde su primer commit (solo-aditivo).
9. **N9 — `grep -r "uid://"` no detecta duplicados** (458): ambos copias matchean; usar `grep -ohE 'uid://[a-z0-9]+' game | sort | uniq -d` en el checklist.
10. **N10 — Posición de la reparación en el pipeline sin declarar** (141): resolver en el límite del tick N, efectos desde N+1 (ya recogido en M2).

## Bottom line (ambas lentes)

El núcleo (reloj determinista por ticks, filas `.tres`, procedencia en schema desde H1, demo saliendo del mismo motor, alternativas honestamente registradas) es arquitectónicamente correcto y de la altitud adecuada. El defecto raíz recurrente es que el documento audita **forma pero no comportamiento**: el validador no ve estados semánticamente podridos (M1), no ve filas perdidas en merge (M3), no ve una submisión estructuralmente inalcanzable (B1), ni detecta que la unidad didáctica central (coste EVA) está denominada en un segundo reloj que depende del multiplicador (M2). Todos los fixes caben en los bloques H1/H4/H25 ya existentes o son podas de una línea; si B1 y M1/M4 no se resuelven antes del freeze de H1, el plan incumple su propia promesa de "ninguna decisión disfrazada de aplazamiento".
