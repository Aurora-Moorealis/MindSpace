# Design Critic Brainstorm Report R2 — verificación tras decisiones del autor

Modo: BRAINSTORM (2ª pasada). Fuentes: input v2 vs brief vs reporte 1ª pasada. Solo residuos y defectos nuevos.
(El revisor no tuvo herramienta de escritura; este archivo conserva el reporte tal como se recibió.)

## BLOCKER

### BL-1 — Los presets de demo-jump son la puerta de entrada a la demo juzgada, y nadie ha definido qué es un preset
Un preset es efectivamente un **save file manuscrito** del estado completo GameSim (4 recursos, 8 máquinas, 16 mejoras, cola de eventos, contadores de misión, radiación), en manos de Mijael (no-programador). Problemas: (a) la superficie de estado se promete congelada a H4 pero el núcleo integra máquinas, eventos, comms y radiación hasta H24 — cualquier drift de schema carga valores erróneos silenciosamente en la demo H28; (b) un preset de novato puede violar invariantes (O₂ 0 + salud plena = boot de cascada de muerte en el escenario); (c) "primera tormenta al minuto 3–4 de la demo" exige inyectar posición de cola del scheduler — si no, la fila de tormenta ya transcurrió y el momento garantizado no dispara; (d) la serialización solo existe para presets: fidelidad round-trip sin testear.
**Requisito obligatorio para el PRD:** presets **capturados, nunca manuscritos** — botón debug de GameSim (DevGreem, hora ~2) que snapshot-ea una partida real y escribe el `.tres` (recursos, estados de máquinas/mejoras, cursor de cola de eventos, contadores); validador de invariantes al cargar que rechace presets que arrancan en cascada de muerte; la garantía "tormenta al minuto 3–4" definida en offset de cola, no en tiempo de reloj.

### BL-2 — La línea de tiempo del swap de datos contradice el golden build al que alimenta
Input v2: corte duro pre-golden (H28). Brief línea del plan: swap **H28–32**, golden en H28, captura/vídeo "desde el golden build". Como está, el vídeo —el artefacto que el juez ve— muestra filas con badge "simulado" y el criterio NASA se puntúa sobre imágenes sin el trabajo de datos.
Fix de una frase en el draft: recolección H12–24, **gate de swap H27**, golden H28, captura H28–30. Declarar el orden en el PRD.

## MAJOR

### MJ-1 — El pipeline `.tres` para ediciones rápidas de novatos no tiene guardarraíles; la excepción de jam elimina los últimos
Con rama única de commits directos y Mijael dueño de registros `.tres`: (i) **duplicación de uid** — copiar un `.tres` retiene el mismo `uid://` (el propio AGENTS.md dice que rompe el proyecto); "editar filas" del novato hará exactamente eso; (ii) **conflictos de merge** — los `[sub_resource id="Resource_N"]` se renumeran al añadir filas; un novato no resuelve ese blob; (iii) **churn silencioso de schema** — si DevGreem renombra/añade un `@export` a mitad de evento, todo `.tres` editado conserva valores viejos y el campo nuevo lee 0: una "avería" con intensidad 0 es un no-op silencioso.
**Requisito:** (a) freeze de schema explícito a H4 (máquina, evento, mejora, submisión, economía, demo); (b) **validador de datos headless** en el pre-commit (campos requeridos presentes y no-cero, rangos, referencias no-null, unicidad de uid, invariantes); (c) **propiedad exclusiva de archivo completo** por ventana horaria (Mijael edita solo datos; DevGreem solo schema `.gd`); (d) prohibido copy-paste de filas en editor de texto — filas nuevas solo con "New Resource" del inspector; (e) preferir 3 escalares (inicio/pico/fin) a recursos `Curve` para intensidades de evento (la edición de curvas es la entrada de datos más propensa a error del editor).

### MJ-2 — Hidden stats sin loop de feedback de UI violan el principio de visibilidad del propio primer pase
Cuatro mejoras modifican valores que el jugador nunca ve antes ni después de comprar: nadie distingue una mejora rota de una que funciona; ningún juez percibe el efecto; imposible depurar desde screenshot. Sin aleatoriedad, la única justificación original para esconderlas desapareció.
Mitigación: texto de efecto con números en el panel de mejora ("repara 20% más rápido") + eco a EventLog — o eliminar las stats.

### MJ-3 — Reparaciones instantáneas sub-tick contradicen el stat de velocidad de reparación y vacían el arquetipo "avería"
Una reparación instantánea **no tiene duración que multiplicar**: al menos una de las 16 mejoras es código muerto. Además roba consecuencia al arquetipo de avería: un fallo se convierte en "camina, pulsa E".
Mitigación: o las reparaciones consumen ticks (una pulsación compromete ~1 tick de progreso, la velocidad multiplica %) o, si son instantáneas, eliminar el stat y dar a las averías un coste real (energía consumida por el intento). No pueden convivir ambas redacciones.

### MJ-4 — Las 4 submisiones como "filas de plantilla" exigen un motor de condiciones que nadie dimensionó
Las condiciones ("2 lecturas **antes de la tormenta DONKI**", "agua bajo umbral y reciclador reparado", "entregar 3 muestras", "5 informes") presuponen contadores de lecturas, referencias cruzadas a filas de eventos y timing del scheduler, y chequeos de umbral contra estado vivo: un evaluador de condiciones + integración con scheduler y contadores.
Mitigación: enum fijo de **4 tipos de condición en código** (`ReadingBeforeEvent`, `CounterReached`, `ResourceBelowAndRepaired`, `TotalReportsSent`), no expresiones libres; el schema entra en el freeze H4 o las filas no se pueden author antes de H14.

### MJ-5 — Procedencia por fila deja las constantes de soporte vital con granularidad de archivo entero
Las constantes núcleo (consumos O₂/agua/comida, yield del panel, umbrales de radiación) viven como escalares en un solo `economy.tres`. Un `source`/`real_data` a nivel de clase no puede etiquetar honestamente un archivo con 27 valores simulados y 3 con fuente NTRS; y no existe superficie UI donde la procedencia de constantes se renderice.
Mitigación: constantes como filas (un Resource pequeño por constante con sus campos de procedencia) o badge de archivo entero + panel dedicado "data sources" (consola comms o pantalla de evaluación). El PRD debe declarar dónde se renderiza la procedencia a nivel de constante.

## NIT

- **N-1:** Mouse click-to-move no adoptado; demo en portátil controlado por el equipo o fallback de 30 min.
- **N-2:** Sin la 4ª persona, **nadie es dueño del audio**. Congelar 5 SFX generados por IA para H12 o comprometerse a casi-silencio.
- **N-3:** El selector con filas "(próximamente)" estará en pantalla durante el juzgamiento; esconderlas en el preset de demo o recortar a una.
- **N-4:** "RNG sembrado por tick" queda vestigial sin aleatoriedad. Nombrar consumidor o eliminar la afirmación.
- **N-5:** "Soles transcurridos" indefinido (¿24 ticks = 1 sol? ¿sol parcial?). Congelar en el schema H4.
- **N-6:** La ventana H26–28 de Mijael está sobre-reservada (entrada de filas NASA + preparación de captura). Con el fix de BL-2, la recolección termina H24 y las filas se entran H25–27.

## Bottom line

Ninguna decisión v2 debe revertirse, pero dos navegan rotas sin guardarraíles: el **preset de demo** (lo único que experimenta el juez) es hoy un "save file" manuscrito por un no-programador cuya superficie está garantizada a derivar — redefinirlo como snapshots capturados por el motor con validador; y el **pipeline `.tres`** no tiene protección contra uid duplicados, blobs de merge irresolubles o cero silencioso de campos renombrados — justo lo que 3 personas editando 1 repo en 1 rama producirán a H18. Arreglar la contradicción golden/swap (swap H27, no H28–32), resolver instant-repair-vs-repair-speed (una de las dos muere), y dar a las hidden stats al menos texto en el panel de mejora — y el brief es drafteable tal cual.
