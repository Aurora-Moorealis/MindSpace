# Comprehension Brainstorm Report R2 — verificación tras decisiones del autor

Modo: BRAINSTORM (2ª pasada), stance de constructor novato. Fuentes: input v2, brief, reporte 1ª pasada. Solo residuos y ambigüedades nuevas.
(El revisor no tuvo herramienta de escritura; este archivo conserva el reporte tal como se recibió.)

## BLOCKERS

**BLK-1 — Final de partida dividido en tres caminos.** v2 dice "victoria, derrota… o continuar" mientras la lista de fuera-de-alcance corta silenciosamente el modo continuo. Dos lecturas posibles: ¿tras 3 informes se corta a evaluación, o se sigue hasta el reloj de misión? Si corta, "soles transcurridos" siempre lee ~0–2 en una sesión de juez; si sigue, la evaluación es inalcanzable en la demo. Y "derrota = muerte o fin del reloj sin informes" deja indefinido "reloj acaba con 1–2 informes".
Requisito: una línea — victoria dispara la evaluación inmediatamente (recomendado); fin de reloj con informes parciales = derrota con evaluación parcial.

**BLK-2 — La decisión topológica no está en ninguno de los dos documentos.** El "pasillos + exterior ≤2 pantallas" existe solo como tema en la lista de aprobaciones; la palabra "pasillos" no aparece en ningún archivo. El novato no puede responder: ¿corredores presurizados o paseos exteriores entre salas? ¿el panel solar es pantalla exterior separada? ¿qué áreas consumen el presupuesto de ≤2 pantallas (3 POIs + panel + cerrojo podrían ser 5)? ¿dónde está el límite interior/exterior — el airlock jamás se menciona — y dónde cambian las reglas de O₂/EVA?
Requisito: un párrafo — pasillos presurizados unen las 5 salas; un nodo airlock define el límite de reglas; enumerar qué áreas exteriores existen dentro de las ≤2 pantallas.

**BLK-3 — Recuperación de radiación sin especificar y "tratamiento" nombra una mecánica cortada.** "Sin tratamiento, refugio como contramedida" — pero "tratamiento" solo aparece en esa frase; no existe mecánica de tratamiento. Tampoco se dice si la dosis decae en interiores o solo deja de acumular. Si la dosis es permanente y acumulativa, economy.tres debe balancearse para ello.
Requisito: declarar "la dosis nunca decae; solo existen acciones que añaden dosis; refugio/blindaje reduce ganancias futuras" (o la regla elegida con tasa) y borrar/renombrar "tratamiento".

## MAJOR

- **MAJ-1 — Funciones de máquinas implicadas por su nombre, no definidas.** Distribuidor de energía (¿manual/automático?); mesa de taller (¿la reparación es in-situ o en el taller?); "emisor de aire" en el orden de apagado vs "depurador de O₂" en la lista — una máquina, dos nombres; hidropónica (¿1, 2 o 3 mejoras dado "mejora compartida" + "2 mejoras por máquina"?); limpieza del panel con dosis solo aparece en la sección de blindaje: ¿evento, acción permanente, o beat de tutorial? No existe sistema de polvo definido.
Requisito: línea por máquina en el draft (función, punto de interacción, reparación in-situ vs taller, ≤2 mejoras nombradas y hidden stats tocadas, costes); unificar el nombre de la máquina de O₂.
- **MAJ-2 — POI ↔ informe ↔ muestra sin mapeo.** 3 POIs y victoria = 3 informes es probablemente 1:1 pero nunca se dice; "escanear" produce informes mientras la submisión #3 pide "entregar 3 muestras" — segundo sustantivo sin punto de entrega; POI 1 "leer" vs POIs 2–3 "escanear".
Requisito: cada POI produce un resultado de escaneo; un informe solo se envía desde la consola comms; las muestras se entregan en la misma consola.
- **MAJ-3 — Dónde vive la barra de progreso de escaneo.** Barra flotante in-world vs HUD; ¿el movimiento cancela? ¿rango/LOS?
Requisito: barra in-world sobre el POI; cancelar al moverse; sin requisito de rango más allá de la distancia de interacción.
- **MAJ-4 — El roster de equipamiento/recogibles está vacío pero las reglas lo referencian.** "Los objetos se aplican al recogerlos" y "traje máx. 2 tipos" sin lista de objetos, sin vía de adquisición del traje 2, sin consecuencia de selección de traje para la regla de reserva de 60 min. "Dormitorio-almacén" nombra un almacén tras cortarse el almacenamiento.
Requisito: lista fija en el draft — traje (EVA por defecto), traje v2 (mejor reserva + blindaje), muestra, contenido del cráter de suministros, puntos de adquisición y aplicación; renombrar la sala si no almacena nada.
- **MAJ-5 — La tormenta del juez no está alineada con los presets de demo.** "Primera tormenta al minuto 3–4" choca con demo = multiplicador + presets (mitad de partida, hora final): si la fila de tormenta está en sol-1 hora ~3 y el preset salta a mitad de partida, la tormenta ya pasó. "Guiada" también contradice el scheduling data-driven.
Requisito: los dos estados preset deben situarse inmediatamente ANTES de una ventana de radiación programada; describir la tormenta como "primera fila de tormenta a hora de juego 3–4", no "guiada".
- **MAJ-6 — `.tres` arregló el formato, no los números; el freeze no tiene dueño ni defaults.** Tick rates, stocks, batería, costes de reparación y la constante de recompensa siguen ausentes; "congelados a hora 1" sin dueño nombrado y sin defaults pre-establecidos.
Requisito: "DevGreem commitea los defaults de economy.tres directamente para H1" y pre-declarar defaults placeholder en el handoff para que el sim pueda codearse contra filas reales de inmediato.
- **MAJ-7 — Pausa sin especificar.** El motor de ticks, multiplicadores y velo están especificados; pausa no existe. ¿La pausa congela GameSim? ¿El velo durante pausa? ¿Pausa permitida en demo? También: "5 h reales = 300 ticks ≈ 12.5 soles" nunca está derivado por escrito, y "mitad de partida" depende de ello.
Requisito: una línea de pausa (congela solo el procesamiento de ticks); una línea: reloj de misión = 300 ticks ≈ 12 soles.
- **MAJ-8 — Punto de llegada de suministros e interacción con cortes de comunicaciones.** ¿Llegan como subida de barra al instante, caja en el airlock...? ¿El arquetipo "corte de comunicaciones" bloquea envío de informes y pedidos o solo el forecast? Si bloquea la condición de victoria, un corte programado durante la demo de juez puede congelar la victoria silenciosamente.
Requisito: punto de llegada declarado; conjunto de bloqueos enumerado (forecast / pedidos / informes).
- **MAJ-9 — Definiciones de contadores de evaluación y el contador doble.** "Picos de radiación/uso de refugio" es un contador con dos métricas; EventLog debe registrar ambos campos desde el día 1. "Recursos finales" son 4 cifras — el layout de pantalla para "5 contadores" que expanden a ~8 cifras está indefinido; Ramerlin lo necesita antes de H12.
Requisito: lista de campos EventLog (informes, submisiones, finales por recurso, evento de dosis máx, usos de refugio, soles) y los slots de pantalla que los muestran.

## NITS

- **N-r2-1** — "24 h = 1 sol" + "reloj ~5 h reales" = 300 ticks = 12.5 soles; una frase evita que un novato construya 5 ticks como "el juego entero".
- **N-r2-2** — Las mejoras que tocan hidden stats necesitan texto de efecto ("+20% velocidad de reparación") en las filas de economía o se sienten inertes.
- **N-r2-3** — La plantilla de fila de evento ("máquina objetivo, intensidad...") no encaja con "pico de consumo" (objetiva un recurso, no una máquina); el schema necesita `objetivo: máquina|recurso`.
- **N-r2-4** — El corte H12 "informes solo desde consola" dice dónde se envían pero no de dónde salen sin POIs; declararlo o parece paradoja.
- **N-r2-5** — ¿Los upgrades cambian sprites de máquinas? Los artistas necesitan saberlo (16 estados de mejora + arte = no).
- **N-r2-6** — "Dormitorio-almacén" sin mecánica de almacenamiento; renombrar o atar la llegada de cratas de suministros ahí.
- **N-r2-7** — Look nocturno: 12 de 24 horas son noche; sin paleta/iluminación (arrastrado de la 1ª pasada).
- **N-r2-8** — Las opciones grises del selector no tienen nombres de display — a la tabla de strings.
- **N-r2-9** — Tutorial máx. 3 pistas: ¿cuáles? (refugio, pedido comms, reparación — la lista es barata; sigue ausente).
- **N-r2-10** — Mapping nivel-campo DONKI y URLs de archivo diferidos a H28; el mapping debe escribirse antes del swap o las filas se llenan con campos sin verificar.

## MUST-answer-before-code (máx. 5)

1. **Contrato de final de partida (BLK-1):** victoria = evaluación inmediata; reloj con informes parciales = derrota con evaluación; borrar "o continuar".
2. **Contrato de mapa escrito (BLK-2):** pasillos presurizados, airlock como límite de reglas, presupuesto de pantallas exteriores, dónde cambian O₂/EVA.
3. **Regla de recuperación de radiación (BLK-3):** la dosis nunca decae (o una tasa); borrar/renombrar "tratamiento".
4. **Micro-contratos de máquina (MAJ-1):** función e interacción por máquina, in-situ vs taller, nombre unificado O₂, trigger de limpieza de panel, excepción de mejoras hidropónicas.
5. **Números con dueño (MAJ-6):** defaults placeholder pre-establecidos en el handoff; DevGreem commitea economy.tres/demo por H1 — `.tres` arregló el formato, no los números.

## Bottom line

v2 ya no está sobredimensionado ni carece de modelo de contenido: tiene rosters, formato de datos con procedencia, escalera de final, propiedad y gates. Lo que sigue abierto es el contrato espacial y de final de partida —"pasillos" sin escribir, airlock sin nombre, victoria-vs-continuar autocontradictorio— más la letra pequeña del loop de riesgo: sin regla de recuperación de radiación, referencia a mecánica cortada, y funciones de máquina que solo existen en sus nombres. Todo cierra con texto y cada uno, abierto, produce un juego distinto. El riesgo nuevo genuino de v2: `.tres` respondió al formato, no al contenido — el freeze de hora 1 no tiene escritor nombrado ni defaults pre-establecidos, así que "congelado" es virtual hasta que números placeholder entren al repo en la hora más ocupada del evento.
