# Inventive Catalyst Brainstorm Report R2 — verificación tras decisiones del autor

Modo: BRAINSTORM (2ª pasada). Fuentes: `.egm/brainstorm-input.md` (v2), `.egm/concepts_brief.md`. Solo contradicciones NUEVAS o residuales.
(El revisor no tuvo herramienta de escritura; este archivo conserva el reporte tal como se recibió.)

## Blocker

**B1 — Presets de demo como snapshots de estado (.tres) vs. sim determinista + tuning continuo hasta H28.**
Un salto a sol-N exige estado materializado (máquinas, recursos), pero escribirlo a mano en `demo_states.tres` crea una segunda fuente de verdad que se pudre: cada edición de tuning y cada swap NASA (permitidos hasta H28) invalida el snapshot; los novatos duplicando filas re-introducen el peligro de `.uid` duplicados; y reaparece un "save system" prohibido disfrazado de estados estáticos. Es la ruta que ve el juez.
→ IFR: un preset es una fila {seed, tick_destino, lista opcional de acciones sub-tick}; el salto recomputa ticks 0..N a velocidad de CPU (el núcleo tick-puro convierte ~288 funciones de tick en milisegundos). Estado siempre derivado, nunca almacenado.
→ Transform: **Inversion + Preliminary Action** (guardar la causa —seed+acciones—, no el efecto —estado—) y **Cheap Dispensables** (snapshots = derivaciones desechables).

## Major

**M2 — Plazo del swap NASA vs. orden del golden build: auto-contradicción del brief.**
"golden build taggeado H28" vs "datos H28–32" y vídeo "desde el golden build": o el vídeo muestra filas "simulado" vendiendo mal el criterio, o el tag se re-aplica en silencio, o los swaps se amontonan en las horas finales más arriesgadas.
→ IFR: el golden build ya contiene cada fila verificada; los swaps corren continuamente según el orden de go-live de cada sistema (fila DONKI primero, el sistema H0–12); **freeze de swaps en H26** dejando H27–28 para re-export; filas sin verificar salen con badge "simulado" coherente en build y vídeo.
→ Transform: **Preliminary Action + Beforehand Cushioning**.

**M3 — Hidden stats invisibles vs. perceptibilidad de mejoras para niños y jueces.**
Una mejora a "hambre máxima" o "velocidad de reparación" gasta recursos sin rastro visible, rompiendo el principio de la 1ª pasada (todo sistema deja marca visible al juez).
→ IFR: cada hidden stat con UN canal de comportamiento visible y cero superficie HUD permanente: velocidad de reparación = el contador de la reparación; límites de hambre/sed = la pendiente de las barras %; velocidad = el caminar mismo; radiación máxima = un tick de umbral en la barra de radiación; más una línea `effect_flavor` por UpgradeData ("repara 25% más rápido") visible al comprar; EventLog registra compras.
→ Transform: **Inversion** (renderizar el efecto, esconder el número) + **Dynamics** (revelar en el momento de decisión).

## Nit

**N4 — Autoría de datos por novatos vs. cuello de botella del schema .tres tipado y diffs ruidosos.**
Los campos del Resource solo puede extenderlos DevGreem; los reviews de gate sobre diffs `.tres` crudos son ilegibles (pesados en uid).
→ IFR: schema congelado en la hora 1 con una columna spare por clase (`extra: Dictionary`); los gates consumen un render de filas (consola de debug que vuelca cada registro como tabla) en vez de diffs crudos.
**N5 — Tutorial solo-diálogo vs. identidad de narrador ausente para público joven.**
→ IFR: ancla de hablante sin arte — overlay diegético de radio "Mission Control" a través de la consola de comunicaciones existente, con tag de hablante y un color; el PNG de Aurora encaja después en el mismo marco sin tocar el sistema de diálogo.
→ Transform: **Extraction + Blessing in Disguise**.

## Bottom line

El núcleo es sólido: motor tick-puro y tablas `.tres` disuelven los blockers de la 1ª pasada. Los residuos viven donde dato toca tiempo y visibilidad: (1) matar presets como snapshots — presets = seed+tick recomputados, o la demo de juez se pudre; (2) freeze de swap a H26, delante del tag H28, para que vídeo y build cuenten la misma historia NASA; (3) canal de comportamiento + línea de sabor por hidden stat. Riesgo residual #1: el mecanismo de presets tal como está redactado es el punto más probable de fallo visible ante el jurado.
