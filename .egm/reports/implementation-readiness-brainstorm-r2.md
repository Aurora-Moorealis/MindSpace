# Implementation Readiness Brainstorm Report R2 — verificación tras decisiones del autor

Modo: BRAINSTORM (2ª pasada). Foco: los dos cambios materiales de v2 (todo en `.tres` tipados; hidden stats invisibles sin aleatoriedad) y la supervivencia del plan por bloques.
(El revisor no tuvo herramienta de escritura; este archivo conserva el reporte tal como se recibió.)

Veredicto general: el esqueleto por bloques sobrevive. Dos decisiones v2 no están propagadas de forma consistente, y `.tres` convierte la libertad de "JSON editable por cualquiera" en reglas de coordinación que el brief no contiene. Nada exige cortar features; todas las correcciones son entradas de freeze de hora 1 o ajustes de cronograma.

## BLOCKERS

**B1 — Orden golden-build vs swap NASA contradictorio entre secciones del concepto.**
input §7: "corte duro pre-golden (H28)"; brief "Datos NASA": "completa antes del golden (H28)" vs "Metas" y "Plan": "swap H28–32" con captura "desde el golden build". Peligro: si swaps corren H28–32 según el plan de bloques, el vídeo muestra filas "simulado" mientras el build enviado tiene valores reales — divergencia exactamente en el criterio juzgado.
Requisito: propagar la regla v2 en todas partes y borrar la línea H28–32. Filas verificadas se swapean solo hasta H27, en sesiones de revisión por pares. El tag H28 contiene los `databases/` finales. Tras el tag: cero ediciones de datos salvo blocker certificado con re-export y re-tag.

**B2 — Presets de demo-estado: `.tres` fuerza una decisión de diseño en hora 1; el mecanismo está indefinido.**
Ni qué estado captura (tick, seed RNG, niveles de recursos, flags de máquinas, cursor de cola de eventos, hambre/sed/radiación, traje, contadores, posición) ni cómo lo aplica. Dos mecanismos: **(A) snapshot** — la clase espeja el estado serializable de GameSim + herramienta debug exporta la partida viva (~2 h; cada variable de estado futura debe espejarse a mano → drift); **(B) replay sembrado** — seed + condiciones + inputs guionizados, re-recorrer el sim headless (~3–4 h; cero espejo, depende de determinismo total incl. acciones sub-tick).
Requisito: DevGreem congela el mecanismo en H0–1; recomendación para jam de 3: **(A)**. Reglas duras: campos POD escalares + identificadores enum/StringName, nunca rutas absolutas ni refs uid; herramienta de captura en Bloque A (H8–12) con preset stub; bake final solo tras el freeze de contenido H24 (H25–26); el tag incluye los presets horneados; demo-jump dentro del ensayo H34.

## MAJORS

**M1 — Una rama, tres manos, registros `.tres` mono-archivo: ventanas de edición y reglas de merge ausentes.**
Los merges `.tres` son por líneas; añadir/quitar filas renumbra `[sub_resource id="Resource_N"]` → colisiones de id cuya resolución mecánica produce parse errors que un novato no arregla. DevGreem scaffold-ea H1–8 y tunea H24–27 mientras el mapa da registros a Mijael: concurrencia programada por defecto.
Requisito (freeze H1): calendario de ventanas por archivo — DevGreem scaffold-ea todos los `databases/*.tres` H1–8; Mijael escribe filas de eventos H12–24; Ramerlin strings vía scaffolds; economy.tres tune-lock DevGreem desde H24, hard-lock H27; demo_states DevGreem-only. Reglas: "un editor vivo por archivo, declarado en chat" y "pull antes de abrir un registro". Commits de datos atómicos (jamás `.tres` + `.gd` en un commit). DevGreem único resolvedor de conflictos. +30–45 min en gates H12/H24 para review de diffs `.tres` (conteo sane de sub_resources, sin headers uid sueltos, campos de procedencia en cada fila nueva).

**M2 — Duplicación de `.uid` y referencias `res://` rotas ahora se extienden a cada `.tres` que crea un novato.**
Copia OS-level de un `.tres` duplica el header `uid://` → errores de escaneo y negativa a cargar una copia; mover/renombrar fuera del dock rompe referencias `res://`. Clase de fallo inexistente bajo JSON, introducida por la decisión del autor, justo en los archivos del ayudante.
Requisito: briefing de hora 1 — crear/mover/renombrar resources solo desde el dock FileSystem; jamás copiar `.tres` a nivel OS; si es inevitable, borrar/regenerar el header uid en el editor antes de guardar. Añadir `grep uid://` de 2 minutos a ambos checklists de gate.

**M3 — Evolución de Resource classes tipadas: añadir es seguro, renombrar es pérdida silenciosa de datos.**
Añadir `@export` es seguro (defaults). Renombrar/quitar una propiedad suelta silenciosamente todo valor entrado — Godot guarda por lista de propiedades del script, sin migración, y re-guarda el archivo pelado: la pérdida es invisible hasta el playtest. DevGreem renombrará fields durante H12–20, justo cuando las filas de los novatos tienen datos.
Requisito: congelar semántica en H1 — tras H12, cambios de schema solo aditivos; cualquier rename dispara re-inspección obligatoria de cada fila (~30 min, DevGreem, checklist). Mantener churn de schema dentro de H0–8 cuando los registros solo tienen placeholders.

**M4 — El tipado del inspector valida forma, no semántica: costes negativos y duraciones cero posibles.**
La justificación "el tipado evita errores de formato" vale para tipos: un `int` acepta 0/-1; un float acepta tasas absurdas — filas con pinta válida que rompen el tuning.
Requisito: todo export numérico de gameplay usa `@export_range` con min/max sanos desde H0–1; filas de mejora con enum `effect_stat` + `delta` desde el primer schema (las 16 mejoras declaran efecto real, visible u oculto); GameSim clampa valores cargados (~10 líneas de guarda de carga).

## NITS

**N1 — Hidden stats v2: neutral-positivo para readiness; dos residuos.** Quitar aleatoriedad cierra la N5 de 1ª pasada y encoge lo que los presets capturan. Residuo 1: stats invisibles no se verifican mirando el HUD en playtests de 30 min — añadir toggle de overlay de debug (~30 min) en EventLog. Residuo 2: la mejora de velocidad acorta exposición EVA y dosis acumulada; el tuning dosis-por-distancia final debe correr a valores finales (matriz H25–27).

**N2 — El authoring por inspector es más lento que JSON para tablas grandes.** Mantener registros pequeños (~4–10 filas por archivo de arquetipo de evento; 16 filas de mejora máx en economy.tres) o la entrada de filas de Mijael se come horas de arte del Bloque B. Un set pasando ~10 filas es aviso temprano de scope creep, no motivo para construir herramienta de edición.

**N3 — Los nombres de enum son las claves de facto de strings de UI.** EventLog y labels de procedencia/HUD imprimen nombres de máquina/evento. Decidir en H1 que valores enum y claves de la tabla central son idénticos (snake_case); si no, cada label necesita glue de mapeo — fix tardío `.gd`-only en el Bloque C de DevGreem.

## Veredicto de supervivencia del cronograma

- **"Sin mecánicas nuevas tras H24"** sobrevive, con lectura corregida bajo `.tres`: las filas nuevas de CONTENIDO también paran en H24 (una fila nueva tras H24 es cambio de gameplay evadiendo la regla); solo swaps de valores NASA verificados hasta H27.
- **"Golden H28"** sobrevive solo tras la corrección de B1 y con presets horneados dentro del tag; el tag debe contener byte-por-byte los `databases/` enviados.
- **"Swap por fila con corte pre-golden (H28)"** sobrevive; la ejecución por inspector es marginalmente más segura que JSON a mano, pero lleva la exposición de colisiones de M1 — correrlos como ediciones serializadas revisadas por pares (H25–27), un archivo a la vez, commit inmediato, smoke-load tras cada lote.

## Orden de construcción corregido (solo deltas)

- **H0–1 (adiciones):** mecanismo+schema DemoStatePreset al freeze (B2); calendario de ventanas de edición `.tres` (M1); briefing uid/FileSystem (M2); políticas `@export_range` y enum-como-clave (M4, N3); mapa de propiedad extendido de "quién posee archivos" a "quién los posee CUÁNDO".
- **H1–8:** DevGreem scaffold-ea `databases/*.tres` con filas placeholder y badges de procedencia (`real_data: false`, "simulado") — serializado.
- **H8–12 (adiciones):** herramienta debug de captura estado→preset + un preset stub; demo-jump smoke-testeado dentro del smoke H8.
- **H12–24:** sin cambios, más review de diffs `.tres` en gates H12/H24 (presupuesto M1) y chequeo de uid duplicados (M2).
- **H24–27 (reemplaza la cola vieja):** freeze de contenido incl. sin filas nuevas; swaps NASA solo como ediciones serializadas por pares; bake final de presets H25–26; economy.tres hard-locked H27.
- **H28:** tag golden con presets finales + todas las filas swapeadas; captura empieza; nada cambia tras el tag salvo blockers certificados con re-export y re-tag.
- **H28–32:** Mijael captura/vídeo/empaquetado; Ramerlin pass final UI; DevGreem solo blockers. La línea vieja "swap H28–32" se borra (B1).
- **H34–36:** el ensayo incluye explícitamente el camino demo-jump (presets + velo) y verificación de un export fresco.

## Bottom line

La decisión `.tres` no invalida el plan de 36 h ni sus cutoffs, pero convierte la libertad de "cualquiera edita el archivo de datos" en reglas de coordinación por archivo que deben entrar al freeze de hora 1: ventanas de edición por archivo con declaración de un-editor-vivo, higiene uid/FileSystem, schema solo-aditivo tras H12, y exports con rango. Dos ítems bloquean tal como están: el brief lleva dos órdenes contradictorios de swap NASA que deciden qué contienen el golden y el vídeo, y el mecanismo de presets (snapshot vs replay sembrado) está indefinido aunque los presets `.tres` no se pueden author a mano y deben congelarse con la forma de estado de GameSim en hora 1. Hidden stats sin aleatoriedad son una simplificación neta y cierran limpio. Con B1 y B2 resueltos y M1–M4 adoptados como entradas de freeze, lo demás cabe en los presupuestos de gate existentes; la estimación de ~70% se mantiene solo si estos aterrizan en hora 1.
