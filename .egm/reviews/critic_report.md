# Goldfish Review — Stage 7: Critic Review (Ronda 1)

**Target:** `docs/designs/junior-astronauta-outpost-lunar.md` — FeatureRange 1–288
**Reviewers:** `egm-design` (feature-spec-standard), `egm-structural` (feature-spec-standard), `egm-style` (sin estándar)
**GoldfishContext:** ninguno.
**Nota:** los hallazgos marcados **[dup §5]** repiten (mismo alcance, misma cuestión) hallazgos ya registrados en `zoom_out_report.md` (Etapa 5); no se consideran nuevos, pero se mantienen abiertos hasta decisión.

## Findings consolidados por severidad (con dedup)

### Blockers

**B1 — El arco "2–5 minutos" es aritméticamente imposible a ×10.**
(`egm-structural-r1-1`, `egm-design-r1-1`) Líneas 20, 27, 75–79, 115, 264. A ×10 un tick = 6 s reales → la misión completa (300 ticks) dura **30 min**; el preset "mitad de partida" (~tick 150) dura 15 min. Solo ×30–×90 cumplirían la restricción declarada "que define todo el diseño". CUJ 4 esquiva mostrando *slices*, pero la restricción y el CUJ no pueden ser verdad a la vez. El NFR "pasada de ~300 ticks en segundos" implica además un modo de cómputo no definido en el rango.

**B2 — Semántica de victoria vs. submisión `total_reports_sent = 5`: contenido muerto o victoria postergable.** [dup §5 B1]
(`egm-design-r1-13`; §5 `zoom-out B1`) Líneas 153–154, 370. O victoria corta inmediatamente al 3er informe (la fila de 5 es inalcanzable), o el sim continúa hasta tick 300 y los informes siguen enviables tras ganar — cosa que también hay que declarar. El documento no decide ninguna de las dos.

### Majors

**M1 — La estadística "salud" (condición de derrota) nunca se define.** (`egm-structural-r1-4`, `egm-design-r1-3`) Lines 11, 29–30, 84, 141. Salud no está entre los 4 recursos del Resumen, ni en el estado del sim, ni en el modelo de datos, ni en los canales de hidden stats; no tiene valor inicial, modelo de recuperación ni posición de HUD. CUJ 5 la usa como death-gate y la escalera le aplica "tope de salud máxima". Adicionalmente CUJ 5 lista hambre/sed como causas directas de muerte mientras la línea 141 las modela como fuentes de daño hacia la salud indefinida.

**M2 — "Pedidos" (pedido de recursos a la Tierra) referidos y jamás especificados.** (`egm-design-r1-8`; §6 `comprehension M3`; `egm-structural-r1-n3`) Línea 145 (y 398, 433 fuera de rango). El corte de comunicaciones bloquea "pedidos"; nada define qué se pide, qué cuesta, qué entrega, con qué latencia ni en qué filas de datos vive. La previsión sí está definida; el pedido no. Un arquetipo de evento con efecto contra un sistema inexistente.

**M3 — `DataAudit` como quinto autoload viola "cuatro, y solo cuatro" y el mecanismo de no-exportación no existe.** [dup §5 M3] (`egm-structural-r1-5`) Línea 95 vs 125 y 166. El contrato de carpetas lo pone en `scripts/` (no `scripts/autoloads/`) y nada dice CÓMO un autoload "no se exporta" (feature tag? registro solo-editor?). Reconciliar conteo y modo de registro (recomendado: script `tool`/headless invocado por el checker).

**M4 — Los presets de demo se re-hornean (H25–26) dentro de la ventana de tuning (H24–27) y antes del hard-lock (H27): entran al golden como fósiles.** [dup §5 M1] (`egm-design-r1-7`) Líneas 45, 124, 159. Un preset `snapshot` desde valores a medio tuning está obsoleto por definición a H28, y el validador solo rechaza cascadas de muerte. Falta: re-horneado post-hard-lock (tarea explícita post-H27) y un fallback definido si el validador rechaza en el ensayo (jamás un botón muerto ante el juez).

**M5 — El corte H12 del exterior no tiene spec de merge, y "cuesta cero horas hundidas" es falso.** [dup §5 M4] (`egm-design-r1-2`) Líneas 31, 141, 149, 153, 192, 198. Si se corta el exterior se rompen al menos: polvo/limpieza de paneles, dosis EVA (el trade-off central del doc), el camino de victoria (3 POIs), `reading_before_event` (lectura en exterior no especificada), y solar_array/airlock pasan a assets muertos construidos H4–8. La Alt. 3 demuestra que el equipo sabe escribir estos specs (food+water → provisiones); el del exterior no existe.

**M6 — Falta la sección "Riesgos y Mitigaciones" que exige el estándar.** (`egm-structural-r1-1`, `egm-design-r1-12`) Fallos de modo distribuidos en 6 secciones (uid, borrado de `@export`, cascadas de preset, fallo H12, tres manos); sin registro de riesgos con dueño que un lector nuevo pueda encontrar. Su ausencia es lo que dejó pasar M7/M9/M10/M11 sin identificar.

**M7 — Jerarquía de títulos rota: dos H3 huérfanos.** (`egm-structural-r1-2`) Líneas 272 y 278 (`### Recursos adicionales`, `### Mejoras futuras`) cuelgan bajo el H2 de NFR por la barra separadora; deben ser `##`.

**M8 — Preguntas abiertas sin tupla uniforme; una sin dueño.** (`egm-structural-r1-3`) Líneas 43–51: Q4 declara "Sin dueño nombrado"; Q2/Q5 sin deadline; Q7 asigna rol ("el artista") en vez de nombre. Formato uniforme dueño+hora por pregunta.

**M9 — Valores que las Preguntas abiertas declaran no-congelados se afirman como hechos decididos en CUJs y Plan Técnico.** (`egm-structural-r1-6`) Q1/Q2/Q4 abiertos vs CUJ 2 (tormenta en tick 3–4), CUJ 3 (2 lecturas) y línea 153 (barra 3 s in-world) redactados como hechos. Cada constante necesita ancla de decisión o tag "placeholder/default".

**M10 — No existe cronograma consolidado de gates; H8, H20 y H34 aparecen una sola vez sin definición.** (`egm-structural-r1-7`) Líneas 26, 31, 36, 159. El esqueleto del plan (el atributo del documento) está disperso; y la "lista de cortes escrita en H1" que promete Meta 6 no figura en el documento.

**M11 — Disponibilidad del freeplay contradictoria.** (`egm-structural-r1-8`, `egm-design-r1-n2`) Alt. 9 (botón desde evaluación, sin restringir resultado) + Meta 5 (evaluación en victoria y derrota) vs CUJ 5 ("disponible tras victoria"). Y no se define qué estado entra el botón tras una derrota (¿freeplay desde salud 0?).

**M12 — Error factual en el problema: "dosis RAD" para la Luna.** (`egm-design-r1-5`) Línea 15 usa RAD (instrumento MSL, Marte); la línea 145 usa CRaTER (correcto). El error está en el enunciado del problema, justo en el eje juzgado.

**M13 — El primer export HTML5 es el golden (H28).** (`egm-design-r1-6`) Cero margen para fallos específicos de web (wasm del tick ×10, arranque de autoloads, carga de `sources/`) ~8 h antes de la entrega. Smoke web throwaway en H16–20.

**M14 — Procedencia de valores derivados/escalados sin regla.** (`egm-design-r1-4`) Líneas 21, 28, 67, 124–125. "DONKI… para dimensionar" implica interpretación/escalado; `DataAudit` solo pide fuente no vacía: un número inventado con URL real adjunta pasa la validación — el fallo exacto que la Meta 3 promete evitar. Regla necesaria: valor copiado crudo ⇒ `real_data: true`; cualquier interpretado/escalado ⇒ `real_data: false` + badge, o campos `derived_from`/`scale_factor` renderizados en la tarjeta de fuente.

**M15 — El plan de descarga NASA asume internet del venue durante H12–24.** (`egm-design-r1-9`) La rúbrica permite pre-descargar commits de fuentes archivadas antes del evento (el brief prohíbe datos *en vivo* en runtime, no la preparación). Pre-fetch obligatorio; descarga del venue solo como refresco.

**M16 — Single point of failure: Ramerlin como dueño duro de toda la capa UI que gatea H12/H24.** (`egm-design-r1-10`) Si el menos experimentado se atasca, la regla "solo Ramerlin" prohíbe a DevGreem desbloquear, y ambos gates dependen de UI. Ownership por defecto + escape hatch de pairing (DevGreem puede tocar `scenes/ui/` en sesión pareada) o trigger de delegación explícito en H12.

**M17 — El riesgo #1 auto-declarado del repo (duplicación uid://) no lo chequea ninguna herramienta.** (`egm-design-r1-11`) `DataAudit` valida ids de filas, no escanea `.tscn`/`.tres` por colisiones de `uid://`. Añadir scan barato al pre-commit (texto, no protocolo humano).

**M18 — Style: etiquetas subjetivas de skill del equipo.** (`egm-style-r1-1`) Líneas 11, 19: "programador fuerte", "novel", "ayudante" sin métrica; la segunda ocurrencia usa rótulos neutros — usar roles de propiedad, no ratings.

**M19 — Style: juicio de opinión como justificación de diseño.** (`egm-style-r1-2`) Línea 145: "el peor editor para novatos" (sobre `Curve`) — la razón objetiva (3 escalares inspeccionables) ya está; quitar el superlativo o calibrarlo al modo de fallo concreto.

**M20 — Style: afirmación conductual sin evidencia.** (`egm-style-r1-3`) Línea 215: "los jueces y los niños se saltan las intros" — sin calibración ni atribución (experiencia de 4 jams previas serviría); los hermanos de la misma sección sí están calibrados.

**M21 — Style: NFR de rendimiento sin presupuesto numérico.** (`egm-style-r1-4`) Línea 264: "sin lag perceptible… en segundos" admite 2 s y 90 s; fijar presupuesto (pasada de 300 ticks ≤ N s en hardware de referencia) y proxy medible.

**M22 — Style: afirmación de motor sin reproducción citada.** (`egm-style-r1-5`) Línea 124: "renombrar un @export borra en silencio" sin versión/test; calibrar con la repro (Godot 4.7, `.tres` mínimo) o reescribir como posibilidad.

### Nits

1. **N1** (`egm-style-r1-n1`) L155: "ancla diegético" → "el ancla diegética".
2. **N2** (`egm-style-r1-n2`) Jerga sin definir al primer uso: "guardarraíles", "clampa", "snapshot-ea", "stretch", "diegético", "mapping por fila" — una línea por término o vocabulario plano.
3. **N3** (`egm-style-r1-n3`) Ceros absolutos en rechazos: "cero horas hundidas" (198), "cero problemas de alineación" (244) → "sin horas desechadas" / "sin riesgo adicional".
4. **N4** (`egm-style-r1-n4`) Calificadores morales sobre reglas mecánicas: "honestamente", "disfrazados" (21, 28) — el mecanismo ya está; quitar el color.
5. **N5** (`egm-style-r1-n5`) Reafirmaciones duplicadas (L20≈79; L115≈268; L21≈257): declarar una vez, referenciar.
6. **N6** (`egm-style-r1-n6`) Resumen con oración de ~85 palabras y fragmentos sin verbo (L11): dividir; reducir negritas a términos decisivos.
7. **N7** (`egm-style-r1-n7`) Taquigrafía figurativa: "conjetura ordenada" (¿ordenada por qué?), "queda detrás" (¿de qué?), "pierde superficie educativa" (¿qué lección?), "estado puro" → "estado autoritativo del sim".
8. **N8** (`egm-style-r1-n8`) "sin incidencia conocida" (Jolt, 266) sin alcance/test/fecha.
9. **N9** (`egm-structural-r1-n1`) Deriva terminológica dosis/radiación y dos modelos de dosis exterior ("según distancia" L11 vs "distancia/duración" L149).
10. **N10** (`egm-structural-r1-n2`) "taller de reparación" (11) vs "sala de trabajo" (37): un nombre.
11. **N11** (`egm-structural-r1-n4`) Q6 vs L141: la pregunta mantiene movimiento condicional mientras el loop ya opera la hidden stat de reparación como decidida.
12. **N12** (`egm-structural-r1-n5`) El roster 8×2 de máquinas/mejoras no está enumerado/enlazado; el artefacto del que depende Q6 es externo al documento.
13. **N13** (`egm-structural-r1-n6`) Granularidad de atribución en Alternativas: Alt. 9 sin atribución; mezcla de lentes nombradas.
14. **N14** (`egm-structural-r1-n7`) "la hora 1" (21, 47) vs "H1": unificar.
15. **N15** (`egm-structural-r1-n8`) Título CUJ 3 "Submisión y financiación" usa el término de la mecánica rechazada; lo real son recompensas de recurso directas.
16. **N16** (`egm-structural-r1-n9`) Concordancia en nodo Mermaid ("capturados por el motor" con nombre singular).
17. **N17** (`egm-structural-r1-n10` + `egm-design-r1-n3`) Meta 5: 5 contadores con ítem compuesto "pico/uso de refugio" (→6); y "recursos finales" NO es derivable del ledger append-only (estado final del sim, no un hecho loggeado) — "5 contadores del EventLog" debe ser "contadores del ledger + snapshot de estado final".
18. **N18** (`egm-design-r1-n1`) CUJ 4: ¿qué preset cabe en 2–5 min? solo "hora final"; y el velo "render solo-HUD" impide al juez pilotar durante la ventana — velo = solo tránsito; en la ventana bajar a ×5/×1.
19. **N19** (`egm-design-r1-n4`) Mapping máquina→sala ausente para storm_shelter, o2_system, water_recycler — decidir en el freeze H1, no en tiles.
20. **N20** (`egm-design-r1-n5`) Freeze H1 y mapeo de rúbrica en la misma hora sin orden definido: rúbrica primero, freeze después, con escape de re-freeze.
21. **N21** (`egm-design-r1-n6`) Idioma de strings (inglés) vs audiencia joven hispanohablante: una frase en Goals/No-Metas; no improvisar en el string pass.
22. **N22** (`egm-design-r1-n7`) Canal de distribución del build HTML5 sin decidir (host estático/itch/GitHub Pages) — decidir en H1.
23. **N23** (`egm-design-r1-n8`) Portabilidad del pre-commit asumida: bash + Godot headless en las 3 máquinas; añadir tarea H0 de verificación del hook en todas.
24. **N24** (`egm-design-r1-n9`) "Ventanas de edición por registro" sin enumerar; colisión en el límite H24 (Mijael termina, DevGreem tunea): asignación quién-qué-horas por registro en la lista de H1.

## Veredicto de ronda (anterior a la resolución)

Round con 2 Blockers y 22 Majors → **no limpia**. La ronda descubre dos defectos nuevos de alto valor (la aritmética imposible del arco a ×10 y la procedencia de valores derivados) y reconfirma desde contexto fresco 3 defectos ya vistos en la Etapa 5 (submisión de 5 informes, quinto autoload, presets podridos) — señal de que no se arreglaron en el documento y siguen abiertos. Los nits son en su mayoría ediciones de una línea.
