# Comprehension Brainstorm Report — Junior Astronaut Mission Trainer

Mode: BRAINSTORM. Stance: reader novato sin contexto previo, debe construir desde este documento en ~36 h. Regla aplicada: lo que no esté especificado, cada persona lo construirá distinto.
Nota: los revisores no tuvieron herramienta de escritura; este archivo conserva el reporte tal como se recibió.

## BLOCKERS — el equipo construirá juegos distintos si esto queda abierto

**B1 — Misión principal sin objetivos.** Solo verbos: explorar, medir, recoger, enviar. Sin cuántos objetivos, dónde, qué herramienta, qué interacción, cuántos informes, qué marca el final. El loop central de validación, ausente.

**B2 — Cero números.** Tick de hambre/sed, O₂ por hora (base vs EVA), stocks iniciales, rendimiento de plantas, origen del agua inicial, retorno del recycler. El juego entero son números en movimiento y ninguno existe.

**B3 — Lógica de fin de partida a medias.** Solo "radiación max = muerte". ¿Qué más daña salud? ¿Hambre/sed a 0% tiene consecuencia o es decorativo? ¿O₂ a 0 mata al instante o con timer? ¿Qué es la "fecha límite" y superarla falla la partida? ¿Qué hay en "modo continuo"?

**B4 — Registro de máquinas + modelo de reparación/mejora ausente.** Cuántas máquinas, estados, qué rompe, coste de reparar, forma de la interacción, lista de mejoras v1 con costes y efectos. "Sala de construcción crea cosas" choca con "construcción pieza a pieza = solo si sobra tiempo".

**B5 — Loop de energía sin definir (¿existe noche?).** Salida del panel por hora, ¿noche con 0?, capacidad de almacenamiento, drenaje por máquina, orden de apagado a 0 energía.

**B6 — Eventos = lista de palabras.** Cada evento necesita: qué número cambia, magnitud, duración, aviso previo, y qué puede hacer el jugador. ¿Existe blindaje? Dosis por segundo en EVA sin declarar. "Polvo" y "temperaturas" no se sabe si son eventos o ambiente.

**B7 — "Financiación" es un recurso fantasma.** Ausente de la lista de recursos, sin tasas de cambio ni catálogo, y las 4 submisiones se quedaron sin contenido (el autor rechazó las únicas propuestas concretas por ser "más de tutorial").

**B8 — Pipeline de datos NASA: términos sin definir, sin mapping, sin deadline de swap.** NTRS, DONKI, "dosis RAD" nunca se expanden ni enlazan; sin URLs, sin schema, sin fecha de intercambio comprometida. A 36 horas, el swap nunca ocurrirá en silencio — y es criterio de evaluación.

## MAJOR — respuestas equivocadas cuestan horas

- **M1 — Inventario/almacenamiento sin describir:** tipos de ítem, capacidad, contenedores, puntos de consumo, cambio de herramienta.
- **M2 — Topología del mapa y reglas del traje:** ¿los cuartos están unidos por pasillos presurizados o se camina afuera entre ellos? ¿Dónde es obligatorio el traje? Define todo el cálculo de O₂/radiación y el tileset.
- **M3 — Modelo de traje:** tipos, durabilidad, blindaje, cómo obtener uno mejor. ¿Por qué es una estadística visible sin valores mecánicos?
- **M4 — Hidden stats + mecánica fantasma de "investigación":** "velocidad de investigación" existe sin sistema de investigación. "Hambre/sed máximas" ocultas mientras el jugador ve %.
- **M5 — Contradicción en el selector de misión:** "3 opciones aleatorias" vs "solo una implementada". ¿Qué muestran las dos no implementadas? ¿Qué cambia elegir misión?
- **M6 — Tensión con el propio brief:** aconseja 2–3 recursos; el diseño propone 4 + radiación + hidden stats + financiación = 6+ sistemas acoplados. La mayor decisión de alcance del doc, sin abordar.
- **M7 — Contrato de la sala de comunicaciones:** coste y delay de pedir recursos, cómo llegan, forecast de eventos (rango, fiabilidad, cooldown), ¿los informes se envían desde aquí?
- **M8 — Detalle de radiación:** "limita la salud máxima" ¿cómo, en pasos? "daño al pasar 30%" ¿a qué ritmo, para al entrar a interior, hay recuperación?
- **M9 — Métricas de evaluación sin nombrar:** la lista debe existir antes de codificar para que los contadores se registren; no se puede backfill.
- **M10 — Rúbrica desconocida:** "8 categorías" sin rúbrica; imposible ponderar trade-offs.
- **M11 — Sin plan de arte/UI para Ramerlin y Mijael:** sin lista de assets, orden de dibujo, paleta, tamaño de sprites, descripción de Aurora, layout de HUD.
- **M12 — Contenido del tutorial:** Aurora "enseña a protegerte" ¿de qué? Sin lista de beats, el tutorial enseñará lecciones equivocadas.
- **M13 — Idioma del texto del juego:** público joven con edad indefinida; doc en español; jueces internacionales. ¿ES, EN, ambos? Sin font/tamaño a 480p.
- **M14 — Pausa, guardado, y control de velocidad:** sin pause spec; "velocidad ajustable" sin granularidad, UI, ni interacción con el deadline (¿el reloj de 5 h va en tiempo real o de juego a alta velocidad?).
- **M15 — Colisión de reparto de trabajo:** estructura de ramas definida, pero ningún módulo asignado a Ramerlin o Mijael; sin plan de file-only vs MCP para el novato.

## NITS

- N1 — 850×480 vs 32×32: 26.56 tiles de ancho; la rejilla nunca aterriza en tile en el borde derecho.
- N2 — "Fuera de alcance: multiplayer (decidir después)" — "decidir después" contradice "fuera de alcance".
- N3 — 4 personas, 3 con rol de juego: el cuarto no tiene responsabilidad declarada.
- N4 — "traje (tipo)" agrupado entre estadísticas numéricas: ¿es equipo o estadística?
- N5 — La lista de eventos termina en "…": formalmente abierta; gatillo de scope creep.
- N6 — "No se puede mover ni eliminar nada" + mejoras que añaden partes: ¿mejorar = añadir?
- N7 — Controles: teclado declarado una vez; ratón/navegación de menús nunca.
- N8 — Visual de noche lunar: sin descripción de iluminación/paleta; el artista adivinará el look de ~la mitad del runtime.

## TOP 15 PREGUNTAS (antes de implementar)

1. Misión principal paso a paso: objetivos, herramienta, interacción, informes, qué completa cada paso vs la misión entera.
2. Reglas exactas de fin: cada trigger de muerte con umbral; qué es "fecha límite" y si va en tiempo real o de juego; qué es modo continuo.
3. Tabla de ticks: hambre/sed por hora, O₂ base vs EVA, dosis EVA, salida de plantas, drenaje de máquinas, stocks iniciales.
4. Escalera de consecuencias: hambre 0%, sed 0%, O₂ base 0, energía 0, radiación >30% y =100% — qué se pierde y a qué ritmo; qué fallo mata primero.
5. Ciclo energía/tiempo: ¿noche con 0 solar? salida y batería; efecto del polvo; orden de apagado.
6. Registro de máquinas: por sala, estados, triggers de fallo, coste y forma de reparación, lista de mejoras v1 (coste + efecto + stat oculta tocada).
7. Corte v1 de la sala de construcción: ¿qué se fabrica ahora vs stretch pieza a pieza?
8. Spec por evento: efecto por severidad, duración, aviso, contramedida; ¿existe blindaje en v1?
9. Contrato de datos reales: qué campos DONKI alimentan qué eventos (con URL/schema), qué dataset da dosis RAD, qué informes NTRS justifican cada número humano, deadline del swap.
10. Economía de financiación + 4 scripts de submisión: trigger, objetivo, éxito/fallo, recompensa; qué compra la financiación (lista + precios).
11. Contrato de la sala comms: coste y delay de pedidos, cómo llegan, forecast, ¿informes desde aquí?
12. Topología del mapa: pasillos vs exteriores; límites exteriores; dónde se requiere traje; puertas; layout del tileset.
13. Inventario/almacenamiento: tipos, capacidad, puntos de consumo, comportamiento del almacén del dormitorio.
14. Hidden stats: lista completa con unidades y defaults v1, visibilidad, mapping mejora→stat (resuelve también la "velocidad de investigación").
15. Contrato UI/arte para Ramerlin y Mijael: idioma(s), orden de dibujo, font/tamaño, pantallas de pausa y evaluación, lista de métricas desde el día uno.

## Bottom line

El documento declara intención, alcance y tecnología, pero difiere prácticamente todo número de gameplay, script de contenido y regla mecánica a una lista de "puntos abiertos" — y con 36 horas, "tratarlos como supuestos" significa tres constructores asumiendo tres juegos distintos. La función de forzado es Q1–Q4 (pasos de misión, estados finales, tabla de ticks, escalera de consecuencias): congelar antes de que exista escena alguna. Todo lo demás debe podarse, no asumirse — 4 submisiones pueden ser 2, el selector puede salir con una opción, el modo continuo puede caerse — porque el dev senior no puede absorber decisiones de spec además de implementación, y el diseño ya ignora el consejo del propio brief de limitarse a 2–3 recursos mientras propone seis sistemas acoplados más una moneda fantasma. Finalmente, el plan de datos NASA tiene un modo de fallo incorporado: "placeholders primero" sin tabla de mapping, URLs de fuente y deadline de swap comprometido garantiza lo peor de ambos mundos — balance roto y ningún dato real donde es criterio juzgado.
