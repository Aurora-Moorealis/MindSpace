# Goldfish Review — Stage 8: Intermediate Zoom Out

**Target:** `docs/designs/junior-astronauta-outpost-lunar.md` (full file, 1–464)
**Estándar:** `zoom-out-standard.md`
**GoldfishContext:** ninguno; contextos de etapa: `zoom_out_report.md` (Etapa 5), `comprehension_report.md` (Etapa 6), `critic_report.md` (Etapa 7).
**Reviewer:** `egm-zoom-out` (directo; synthesizer no disponible en este harness).

## Estado de hallazgos previos (texto actual verificado)

Los 2 Blockers siguen textualmente vivos en el archivo: **B1** (§7, "arco completo en 2–5 minutos" línea 20 vs techos ×1/×5/×10 en 78/115: 300 ticks × 6 s = 30 min) y **B2** (§5/§7, victoria = 3 informes línea 153 vs fila "5 informes totales" línea 370). La única mitigación nueva en el texto es el guard de exportación de `DataAudit` (438, 445), objeto de un hallazgo nuevo abajo. Los demás hallazgos críticos (M1–M7 de §5; M1–M17 de §7) siguen abiertos sin cambios: pedidos (145/398/433), salud (84/141/433), presets H25–26 (159/376), "cero horas hundidas" (198), "dosis RAD" (15), ensayo H34 (159), sin sección de riesgos.

## Hallazgos nuevos (no cubiertos por Etapas 5–7)

### Major

**J1 — El plan de horas no cierra por agregado de máquinas y no tiene bloque para los ítems 17–24.**
Líneas 291, 399, 401–434. "Una máquina más cuesta ~2–4 h" × 8 máquinas = **16–32 h**; el único bloque con máquinas es H4–8 ("máquinas básicas", 4 h), y los ítems 17–24 (astronauta, 8 máquinas, map/airlock/POIs, base.tscn, evaluación, 7 paneles UI) **no tienen bloque asignado**: caen en un "H12–24 loop completo" indiferenciado. La Etapa 5 (M6) marcó el núcleo sin precio; nadie multiplicó: lo declarado barato es la línea más grande del presupuesto y no cabe en los bloques descritos. Escalation: si no cierra, sube a Blocker.

**J2 — La maquinaria de captura de presets es removible: 2 filas escritas a mano a H27 producen el mismo artefacto y disuelven la clase de problema "presets podridos".**
Líneas 159, 298, 346–347, 376. Nada aguas abajo observa si un preset salió de una partida real; `DataAudit` valida invariantes y el juez ve estado. Escribir los dos presets a mano a H27 (post-hard-lock, desde las filas finales) da salida idéntica, elimina código de captura del núcleo, elimina de raíz el problema de re-horneado/putrefacción (§5 M1, §7 M4) y acorta H8–12. Contraargumento honesto: "sin contenido de demo improvisado" es una afirmación de proceso, no una propiedad del producto; si el equipo valora esa historia de reproducibilidad, conservar la captura — pero como decisión explícita, no default.

**J3 — Dos hogares de strings sin regla de colocación contradicen "un solo lugar para el texto visible".**
Líneas 340–341, 334 vs 352, 382. `hint_text`/`effect_flavor` son **literales** en filas; nombres de máquina y títulos de submisión son **claves** a `strings.tres`. Mecanismos duales sin regla; la línea 382 queda internamente falsa. Decisión de una línea en H1: o todo literal en la fila dueña (strings.tres = chrome de UI), o todo clave.

**J4 — Hambre/sed duplican medición por recurso de sustento.**
Líneas 322, 433, 141, 392. Encima de barras de comida/agua con consumos por tick, dos contadores de saciedad con tasas propias y dos slots más de HUD (9 lecturas para un juego junior). Ninguna frase conecta stock↔saciedad. Dobla la superficie del freeze H1 que §5 M7 marcó como apuesta ciega. Kill YAGNI: daño directo por agotamiento de stock (comida = 0 → daño), sin capa de saciedad; playtest escolar post-evento decide si se añade.

**J5 — El guard de exportación de `DataAudit` conserva el quinto autoload, mantiene roto "cuatro, y solo cuatro" y usa la vía más pesada.**
Líneas 95 vs 125, 438, 445. Autoload registrado + guard custom embarca un no-op en el export y exige exclusión de build no estándar (hay que saber que existe y verificarlo). La vía simple sigue disponible: script `tool` sin registro, invocado por el wrapper de `check-gdscript.sh`. Sin argumento a favor del registro para un script que solo corre en boot headless.

### Nits

- **j1** — Triple capa de rango para un mismo dato (122, 125, 439): `@export_range` + assert de `DataAudit` + clamp de `GameSim`. Dos bastan; el clamp mete una rama defensiva en el núcleo "puro".
- **j2** — "O₂/habitante" (141) pre-arquitecta multi-astronauta (No-Meta, línea 35). Tasa simple para un astronauta.
- **j3** — "solo si existió el bucle" (427): tercera condición sin definir sobre el botón freeplay; resolver con §7 M11.
- **j4** — "datos del astronauta" (346) en `DemoStatePreset` sin enumerar: indecidible mientras salud no esté definida (§7 M1).

## Verdicts pedidos

**(a) Veredicto estructural nuevo:** ninguna J es rediseño; todas son podas o decisiones de una línea. J1+J2 juntos son la señal estructural que faltaba: el plan carga maquinaria que no necesita (captura de presets) y precios que no cierran (agregado de máquinas). No hay Blocker nuevo propio; hay dos Blockers ajenos que persisten y cinco J que devuelven margen de horas.

**(b) ¿Defendible como submisión de 36 h?** **No en su estado actual; sí con una ronda de resolución quirúrgica del autor.** El esqueleto (reloj determinista, filas `.tres`, procedencia desde H1, demo saliendo del motor) sigue correcto. Lo que impide congelar H1: B1 (toca input map, velo, NFR y CUJ 4); B2 (contenido muerto o semántica no declarada justo antes del freeze de submisiones en H12); J1/J5 (contrato de autoloads y cierre del plan). Son correcciones de línea o de hora, no de arquitectura.

**(c) Prioridades:**
- **Antes de H1 (mayor riesgo):** **B1** — la aritmética del arco de demo. Es "la restricción que define todo el diseño" y toca constantes que se congelan en H1. Barato de decidir (techo ×30–×90 o declarar demo-slices), pero H1 congelaría sobre una especificación falsa.
- **Puede esperar a post-evento:** **J4** — capa de hambre/sed. Daño directo por agotamiento de stock; la saciedad se añade si el playtest escolar lo pide. Ninguna rúbrica la juzga.

## Bottom line

El documento es un buen kernel con costra de maquinaria innecesaria: a la lista abierta de Etapas 6–7 se suman cinco hallazgos nuevos de poda/decisión en una línea — el plan de horas no cierra por 8 máquinas × 2–4 h contra bloques de 4 h (J1), la captura de presets es hardware removible (J2), los strings viven en dos hogares (J3), hambre/sed duplican superficie (J4), y la mitigación de `DataAudit` mantiene roto "cuatro, y solo cuatro" por la vía más pesada (J5) — mientras los dos Blockers previos siguen literales en el texto, el de la demo precisamente sobre constantes que se congelan en H1. Veredicto: **el plan no pasa a H1 como está; pasa con una ronda del autor acotada a B1+B2+salud+forma de DataAudit+decisión de captura+asignación de bloques**, tras la cual el margen recuperado devuelve horas justo donde faltaban: el núcleo sin precio.
