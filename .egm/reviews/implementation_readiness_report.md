# Goldfish Review — Stage 9: Implementation Readiness Test (Ronda 1)

**Target:** `docs/designs/junior-astronauta-outpost-lunar.md` — DetailedRange 289–464
**Reviewers:** `egm-implementation-readiness` + `egm-codebase-details` (implementation-readiness-standard), `egm-style` (sin estándar)
**GoldfishContext:** ninguno. Repo verificado por la lente codebase (hechos sobre el estado actual del repo: **veraces**).
**Nota:** los hallazgos marcados **[dup §N]** repiten hallazgo abierto de otra etapa (mismo alcance/cuestión); no cuentan como nuevos.

## Findings consolidados por severidad (con dedup)

### Blockers

**B1 — La lista unificada de archivos omite toda la capa de assets: no sirve de allowlist.**
(`egm-implementation-readiness-r1-1`) Ningún `assets/audio/` (los 5 SFX congelados en H12), sprite del astronauta, arte de máquinas, stills de intro ni tilesets aparecen en los ítems 1–27, pese a que la spec (177) declara `assets/` como existente. Un allowlist construido desde esta lista bloquea todo el trabajo de arte/SFX de Mijael. Falta: globs de arte + las 5 rutas de SFX enumeradas.

**B2 — "Pedido" (reabastecimiento) referido 4 veces, especificado cero.** [dup §7 M2 / §6 M3]
(`egm-implementation-readiness-r1-2`) Sin campo de coste/latencia/cantidad en `economy_data.gd`, sin paso de pipeline para entregas, sin comportamiento de UI. Si es un stub hasta el corte H12, el contrato del stub (qué hace el botón, qué significa "pedidos bloqueados") debe declararse.

**B3 — El plan de verificación no tiene casos de prueba; el determinismo, que es el claim fundacional, no se testea.**
(`egm-implementation-readiness-r1-3`; `egm-codebase-details-r1-4`) Solo comandos de build/smoke/grep. Cero aserciones para: aritmética del tick, ramas de la escalera (O₂ 0 → reserva 60 min; radiación 30%/100%; orden de apagado), las 4 condiciones del enum de submisiones, rechazo de presets en cascada, clamps. El estándar exige casos concretos happy-path y edge-case.

**B4 — El enum `effect_stat` jamás se congela; los ítems 1, 8, 10 y 15 no son codificables.**
(`egm-implementation-readiness-r1-4`) `GameSim` necesita el `match` por stat; `strings.tres` declara claves idénticas al enum; Q6 depende de la matriz. La única candidata nombrada es velocidad de reparación. El plan — que ES el artefacto de H1 — no congela la lista.

**B5 — El gate anti-uid no puede detectar duplicados tal como está escrito.** [dup §7 N23/N13 parcial]
(`egm-implementation-readiness-r1-5`) `grep -r "uid://"` lista ocurrencias, no duplica: siempre "pasa", inunda con refs legítimas y arrastra `.godot/`. La única defensa ejecutable contra el riesgo nº1 declarado del repo es falsa seguridad. Fix inmediato: `grep -rhoE 'uid://[0-9a-z]+' --include='*.tscn' --include='*.tres' game/ | sort | uniq -d` debe devolver vacío.

**B6 — El mecanismo de `DataAudit` como está especificado no ejecuta, y el pre-commit no-op silencioso.** [dup §7 M3 / §8 J5]
(`egm-codebase-details-r1-3`; `egm-implementation-readiness-r1-7`) En un run headless `Engine.is_editor_hint()` es false → el guard como está escrito nunca dispara el único trigger útil; "flag de build" queda como elección del implementador; si `economy.tres` no existe aún (H0), nada dice si salta o falla; no hay canal pass/fail (exit code); y "invariantes de presets" es una propiedad conductual que un validador de forma no puede comprobar sin ejecutar GameSim (dependencia circular). El "único net de seguridad del pipeline de datos" es un falso negativo silencioso tal como está.

### Majors

**M1 — Autoload "cuatro y solo cuatro" roto dos veces: DataAudit como 5º, y MCPRuntimeServer sin mencionar.** [dup §7 M5 / §8 J5]
(`egm-codebase-details-r1-1`) El `project.godot` real ya registra `MCPRuntimeServer` (único autoload hoy). El ítem 26 dice "los 4 autoloads (+ DataAudit)" sin reconciliar el invariante, ni avisar que el autoload del addon se preserva intacto (un implementador puede "limpiarlo" y romper el MCP Toolkit).

**M2 — Falta el wiring de escena principal: `run/main_scene` ausente y el "main scene glue" prometido en la spec no tiene archivo en la lista.**
(`egm-codebase-details-r1-2`; `egm-implementation-readiness-r1-1`) `project.godot` real no tiene `[application] run/main_scene`; bootear el juego no carga nada. La FSM de fases (selector→stills→tutorial→juego→evaluación) no tiene host. El boot de verificación de la línea 456 no instancia nada.

**M3 — `content/map/` y `scenes/ui/` doblan las reglas de carpetas de AGENTS.md, y solo una desviación está registrada.**
(`egm-codebase-details-r1-6`, `-r1-nit2`) `content/map/` viola `content/<tipo>/<nombre>/` sin excepción registrada (a diferencia de `databases/sources/`); `scenes/ui/` con HUD + `pause_menu.tscn` no es "pantallas, menús, flujo" (y choca con el ejemplo del repo `scenes/pause_menu/`). Registrar ambas o reestructurar.

**M4 — Colocación máquina→sala y topología exterior sin asignar.**
(`egm-implementation-readiness-r1-2`) 8 máquinas + 3 POIs sobre "5 salas + pasillos + airlock + ≤2 pantallas" sin mapa de placement; eso decide hints del tutorial, duración EVA, polvo/dosis. Decisión de level-design dejada al implementador.

**M5 — Dos de los 5 contadores no se pueden derivar del EventLog como está spec'd.** [dup §7 N17]
(`egm-implementation-readiness-r1-3`) "Recursos finales" y "soles transcurridos" son estado, no hechos. O snapshots por tick en el ledger (schema no definido) o la evaluación lee estado vivo, contradiciendo líneas 30/310/427.

**M6 — Comms duplicadas sin interfaz, y contrato de propiedad máquina-escena vs s sim sin definir.**
(`egm-implementation-readiness-r1-5`) Cinco funciones (informes, submisiones, pedido, previsión, data sources) reclamadas a la vez por `comms_console/` (DevGreem) y `comms_panel.tscn` (Ramerlin) sin interfaz declarada. Igual: `GameSim` posee "máquinas (estado, mejoras)" mientras `machine_base.gd` + 8 máquinas existen — sin id-wiring ni contrato read/write.

**M7 — Las "lecturas de temperatura" no tienen productor.** [dup §6 M2]
(`egm-implementation-readiness-r1-6`) Ninguna máquina/POI/sistema de la lista produce lecturas; la fila 1 de `submissions.tres` cuenta "2 lecturas". Y los parámetros de `SubmissionData` (target de contador, ref a evento, umbral) no están mapeados a qué miembro del enum usa cuál.

**M8 — Los bloques de horas no son verificables ni cerrados.** [dup §8 J1]
(`egm-implementation-readiness-r1-8`) Ningún archivo tiene horas asignadas; H0–4 reclama ~16 archivos incl. el pipeline completo; el gate H12 pide casi toda la lista en la hora 12 con la UI en manos de un novato sin contratos definidos. "Orden de construcción por bloques" es una posición, no un cronograma.

**M9 — El schema de costes de reparación/mejora se contradice entre archivos.**
(`egm-implementation-readiness-r1-9`) `economy_data.gd` promete "costes de reparación y mejoras"; `UpgradeData` no tiene campo de coste; ningún archivo lleva el coste de energía de reparar. Decidir dónde viven y granularidad.

**M10 — Umbrales congelados en el plan mientras Q2 los declara abiertos.** [dup §7 M9 parcial]
(`egm-style-r1-1` Std: Major) Línea 370 fija los 4 umbrales contra Q2 ("no congelados"). O marcar las filas como candidatas al freeze H1, o actualizar Q2.

**M11 — "cada fila muestra su dato NASA" contradice la regla de honestidad.**
(`egm-style-r1-2`) Contra la línea 145 (`real_data: false` + badge donde no hay fuente). Calibrar: "cada fila declara su procedencia (fuente NASA o simulated)".

**M12 — `MachineData` ausente del contrato de clases de la spec (122).**
(`egm-style-r1-3`) El plan introduce sigilosamente una clase nueva (con 2 `class_name` en un archivo) después del cierre del contrato. Reconciliar la enumeración.

**M13 — Predicados no evaluables y gate no ejecutable.**
(`egm-style-r1-4`, `-r1-5`) "solo si existió el bucle" (427) sin definición (la spec dice "tras victoria"); "captura 2–3 min desde él" (459) sin nombrar el artefacto ni el referente. Los gates son la espina del proyecto; deben ser ejecutables literalmente.

**M14 — Clash de propiedad en `scenes/ui/`.** [dup §7 M10]
(`egm-style-r1-6`) "solo Ramerlin" (folder) vs scaffolds `.gd` de DevGreem en la misma carpeta. Regla por tipo de archivo, explícita.

**M15 — Atribuciones sin evidencia en "Por qué".**
(`egm-style-r1-7`) "la revisión declaró inoperable" (347) sin citar reporte; estándar de citas del propio doc (174–175, 186). Calibrar con ruta del reporte R2 o quitar la cláusula.

### Nits (consolidados)

1. **N1** (`egm-style`): nombre de fase "stills" vs "intro" en 5 sitios; unificar (fase = intro, medio = stills).
2. **N2** (`egm-style`): "clamps defensivos" redundante; "único net" falso (GameSim clampa + validador de presets); recalibrar.
3. **N3** (`egm-style`): "las 12 horas centrales" (299) sin origen; "volumen salvaje… sala de jueces" (317) dramatización inventada; quitar.
4. **N4** (`egm-style`): ejemplo de string en español ("repara 25% más rápido") dentro de tabla en inglés (340).
5. **N5** (`egm-style`): "datos del astronauta" + "POD" (346) sin enumerar — indecidible mientras salud no exista [dup §8 j4].
6. **N6** (`egm-style`/`codebase`): "código bespoke" ×2 → "código a medida"; "garantiza" → "reduce".
7. **N7** (`egm-style`): "1–3 PDFs NTRS" precisión falsa; → "informes identificados durante H12–24".
8. **N8** (`egm-style`): "sustitución propia cuando sobre" (403) hedge sin dueño/gate → futuras mejoras.
9. **N9** (`egm-style`): "la topología cerrada en el brief" (405) atribución errónea → decisión de la ideación.
10. **N10** (`egm-style`): absolutos: "evita conflictos" (422) → "reduce"; "única forma" (434) falso (worktrees existían).
11. **N11** (`egm-style`): "tick de umbral" (433) ambiguo → "marca del umbral 30%".
12. **N12** (`egm-style`): "guarda `Engine.is_editor_hint()`" (438) → "se protege con"; "el repo la dejó TODO" sin antecedente (452); "llave enum" fragmento (382).
13. **N13** (`egm-codebase`): `export_presets.cfg` ausente de la lista (vive fuera de `project.godot`); error-visibility del smoke HTML5 sin canal.
14. **N14** (`egm-codebase`): registro de excepción solo para `databases/sources/`; añadir nota explícita para `scenes/ui/`.
15. **N15** (`egm-codebase`): aprobación explícita del dueño para los nuevos autoloads (regla AGENTS.md) — anotar sign-off en el freeze H1.
16. **N16** (`egm-implementation-readiness`): look nocturno (Q7) sin archivo/dueño en la lista.
17. **N17** (`egm-implementation-readiness`): host de los dos botones de preset sin especificar (¿overlay debug? ¿pause? ¿base?).
18. **N18** (`egm-implementation-readiness`): datos del traje sin contenedor (clase/`.tres` de tipos de traje y coeficientes).
19. **N19** (`egm-implementation-readiness`): "render de filas para los gates" sin canal de salida (pantalla? stdout? file?).

## Veredicto de readiness (antes de resolución)

El documento **no pasa la Etapa 9 en la ronda 1**: 6 Blockers y 15 Majors impiden ejecutar el plan tal como está escrito. El repositorio real no contradice al plan (los hechos citados sobre el estado actual son veraces), pero un implementador fresco tendría que inventar: la capa completa de assets (B1), el sistema de pedidos (B2), cada caso de prueba (B3), el enum de stats (B4), y tendría dos comandos de verificación que "pasan" sin verificar nada (B5, B6). Media docena de Majors son además decisiones de diseño dejadas al implementador con violaciones del Zero-Decision Rule. Los nits se resuelven en una edición de media hora. §5/§7/§8 ya habían señalado 2 Blockers idénticos (arco de demo, "5 informes") que siguen vivos en el texto — esta etapa los confirma una vez más desde contexto fresco.
