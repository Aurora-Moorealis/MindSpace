# Concepto: Build A Junior Astronaut Mission Trainer (Outpost Lunar) — v2 consolidada

- **Autor:** DevGreem
- **Fecha:** 2026-11-14
- **Estado:** material de entrada para la **segunda pasada** de revisión Goldfish (modo BRAINSTORM). La v2 incorpora las decisiones del autor posteriores a la primera revisión.

## Cambios consolidados desde la v1 (resumen para esta pasada)

1. **Formato de datos: Godot Resources nativos (`.tres`), no JSON.** Decisión final del autor: los novatos ya manejan la zona de Resources y el tipado del inspector evita errores de formato. Registros editables en `game/databases/*.tres`; clases tipadas con `class_name` en `resources/<dominio>/*.gd`. Los campos de procedencia NASA van como `@export` en las clases (`source`, `source_url`, `date_archived`, `archived`, `real_data`). La primera pasada había recomendado JSON; descartado.
2. **Motor de ticks aprobado:** 1 tick = 1 hora de juego = 60 s reales a ×1; multiplicadores ×1/×5/×10; demo = tick-rápido + presets de salto (`databases/demo_states.tres`). Aprobado por el autor.
3. **Idioma UI: inglés** (confirmado). Strings en tabla central; localizaciones futuras no contempladas.
4. **Hidden stats: se quedan, invisibles en la UI** — solo velocidad de reparación, velocidad de movimiento, hambre/sed máximas, radiación máxima (las que toca alguna mejora). **Sin aleatoriedad en v1.** "Velocidad de investigación" eliminada (no hay sistema de investigación).
5. **Ventana: 850×480 se mantiene** (~16:9, decisión de estilo del autor). Mitigación: pixel snap de cámara y prueba de temblor de tiles; si fallara, escala entera en export.
6. **Tutorial v1: sistema de diálogos + indicaciones de destino** ("ve ahí"), sin arte de Aurora todavía; el PNG de la mascota puede llegar después sobre el mismo sistema. Sin recorrido animado; intro/aterrizaje = 2–3 stills skippeables.
7. **Datos NASA:** pruebas con números inventados mientras se valida el juego; cada fila lleva `real_data: false` y badge "simulado" desde la hora 1. **Swap por fila en el momento en que ese sistema funciona**, con corte duro pre-golden-build (H28): la fila no verificada sale con badge "simulado". Datasets: DONKI (CME/FLR/SEP) para tormentas, LRO **CRaTER** para dosis de superficie lunar, 1–3 informes **NTRS** para constantes de soporte vital. Mijael recoge datos H12–24.
8. **La 4ª persona del equipo queda fuera por ahora** (no participará).
9. **Aprobaciones tácitas del resto de defaults** (el autor los vio listados y no objetó): excepción de jam a reglas git, autoloads, exterior ≤2 pantallas, día/noche 12/12 + blindaje interior, contadores de evaluación.

## Contexto del evento (sin cambios desde v1)

- NASA Space Apps Challenge 2026, desafío "Build a Junior Astronaut Mission Trainer". **~36 horas** para construir (evento 14–15 nov; el juego se termina antes de la entrega).
- Equipo efectivo: **3 personas.** DevGreem (autor): lógica; Godot ~5/5, Aseprite 4/5, sonido 1/5, 4 jams. Ramerlin: UI y visible; programador sin Godot (aprendiendo), arte/UI 5/5, sin jams; el autor afirma que "ya maneja un poco" la edición de Resources. Mijael: apoyo; sin programación, pixel art 2.5/5; hará además captura, vídeo, diapositivas y recogida de datos NASA. Usan IA para acelerar.
- Entregables fuera del repo (vídeo, diapositivas): fuera de este repositorio. Aquí solo el juego.

## Requisitos del brief oficial (verificados)

- Estudiantes manejan un outpost lunar y equilibran soporte vital, blindaje contra radiación, energía y comida, sintiendo los trade-offs que salvan o matan una misión.
- Aconseja **2–3 recursos núcleo** con reglas que los conecten.
- **No hay dataset NASA para cifras de soporte vital**: citar **NTRS**.
- Usar **DONKI** (eventos solares) y **dosis RAD** como entradas reales de radiación.
- Mostrar **qué dato NASA origina cada evento**; datos embebidos etiquetados **archivados**, no en vivo.
- Público: estudiantes jóvenes.

## Hipótesis anclada (v2)

Juego Godot 4.7 singleplayer, pixel-art 850×480 (tiles 32), tiempo real con **motor de ticks** (1 tick = 1 h de juego), astronauta controlado por teclado con estadísticas visibles (salud, traje como equipo, O₂, hambre %, sed %, radiación acumulada) y **hidden stats invisibles** (velocidad de reparación/movimiento, límites de hambre/sed, radiación máxima). Base lunar fija de **5 salas** (dormitorio-almacén, invernadero, energía con panel solar exterior, taller de reparación, comunicaciones) con **8 máquinas interactuables** (depurador de O₂, reciclador de agua, distribuidor de energía, panel solar, unidad hidropónica agregada ≤4 plantas, mesa de taller, consola de comunicaciones, cerrojo de refugio), 2 mejoras por máquina, costes en `databases/economy.tres`. Recursos: O₂, agua, comida, energía; radiación como riesgo con regla de blindaje (interiores limitan dosis; mejora de refugio; dosis EVA por distancia). **Misión principal** de exploración científica sobre exterior mínimo (≤2 pantallas, 3 POI: estación de temperatura, campo de rocas, depósito mineral; herramienta de escaneo; victoria = 3 informes enviados desde comunicaciones). **4 submisiones opcionales** como plantilla de datos (2 de evento-respuesta, 2 de progreso de misión) con recompensa de conversión directa a recursos (una constante). Eventos lunares **data-driven por 5 arquetipos** (avería, caída de producción, pico de consumo, ventana de radiación, corte de comunicaciones) dirigidos por Resources con procedencia NASA visible y badge archived/simulado. Partida termina en victoria, derrota (muerte o fin del reloj de misión) o continuar; **siempre pantalla de evaluación** con 5 contadores del EventLog. Tutorial v1 por diálogos con indicaciones de destino (Aurora PNG opcional después). Intro = stills. Demo para jueces: multiplicadores + presets de salto.

## Detalles operativos congelados para la implementación

- **Tiempo:** 24 h = 1 sol simplificado estilo Tierra (día/noche 12/12; paneles cargan de día, batería de noche). Reloj de misión ~5 h reales como parámetro; la demostración no depende de completarlo (ticks ×5/×10 + presets).
- **Fin de partida:** hambre 0% o sed 0% → salud decayendo; O₂ 0 → reserva de traje 60 min jugada y muerte; energía 0 → apagado fijo (luces → hidropónica → reciclador → emisor de aire); radiación 100% = muerte; >30% tope de salud máxima y daño progresivo; bajo techo no crece; salud 0 = muerte. Sin tratamiento, refugio como contramedida.
- **Comunicaciones:** pedir recursos = una opción fija con retardo fijo; previsión = "próximo evento en N h" desde la cola.
- **Evaluación:** 5 contadores congelados antes de H12 (informes enviados, submisiones completadas, recursos finales, picos de radiación/uso de refugio, soles transcurridos), alimentados por autoload `EventLog` desde el día 1 (también herramienta de debug).
- **Autoloads (permiso pedido):** `GameSim` (reloj/sim determinista con RNG sembrado por tick y estado serializable), estado de partida, `EventLog`, `AudioManager`. Interacciones sub-tick; velo de fast-forward a velocidad alta.
- **Proceso git (excepción de jam):** rama única `features/jam-outpost-lunar`, commits directos, sin worktrees ni PRs durante el evento; vuelta al flujo normal después. Propiedad: `.gd` = DevGreem; `scenes/ui/` + `themes/` + strings = Ramerlin sobre scaffolds tipados; arte + registros `.tres` + captura/vídeo/diapas = Mijael. Checker estricto antes de cada commit; revisión de diffs de novatos en checkpoints (no bajo demanda).
- **Prohibiciones:** plugin local SceneTime (rompe para otros y en exports), addons nuevos, MCP autoload en build de exportación, mecánicas nuevas post-H24, save system, grid de inventario (objetos se aplican al recoger), crafteo libre, mapa exterior >2 pantallas, cualquier ítem sin línea de rúbrica.
- **Exports:** Windows + HTML5, smoke test H8.
- **Rúbrica oficial:** descargada y mapeada a features en la hora 1 (Mijael/Ramerlin; DevGreem firma).
- **Corte de emergencia pre-acordado (gate H12):** si el exterior no está jugable, misión = enviar informes solo desde consola; si 4 recursos no balancean, comida+agua → "provisiones".

## Fuera del alcance v1 (sin cambios relevantes)

Multiplayer (post-evento, si hay tiempo), otros planetas, varios astronautas y aleatoriedad, construcción pieza a pieza / mover edificios (stretch post-H20 aprobado solo por DevGreem), save, modo continuo con contenido nuevo, datos NASA en vivo, sueño del astronauta.

## Puntos abiertos que siguen abiertos (para revisar en esta pasada)

1. Contenido final de las 4 submisiones (la plantilla está definida; los textos/umbrales, no).
2. Números concretos de `economy.tres` (se congelan en la hora 1 con valores por defecto; aquí solo se pide validar la estructura).
3. La rúbrica exacta de las 8 categorías (tarea de la hora 1 real).
4. Steps exactos de escaneo (¿mantener pulsado? ¿minijuego o progreso simple?) — por defecto progreso simple de 3 s.
5. Qué muestran las 2 opciones en gris del selector de misión (por defecto: filas "(próximamente)").

## Repositorio y tecnología (hechos)

- Repo `MindSpace`, Godot en `game/`, casi vacío. Reglas: tipado explícito GDScript obligatorio (prohibido `:=`), avisos estrictos activados, comentarios en inglés, estructura de carpetas en `AGENTS.md`, addon Godot MCP Toolkit presente. La carpeta de artefactos EGM es `.egm/`.
