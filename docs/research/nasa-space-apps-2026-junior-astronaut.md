# Datos NASA y auditoría del desafío — *Junior Astronaut Mission Trainer* (Space Apps 2026)

- **Fecha de revisión:** 2026-11-15
- **Fuente principal:** página oficial del desafío, pestañas **Details** y **Resources**.
- **Fuentes normativas:** *2026 Project Submission Guide* y *2026 Judging & Awards Guide*.
- **Uso:** documento de trabajo para el equipo de MindSpace. Los valores están pensados para las filas de `game/databases/` y para el panel *Data Sources* del juego; el paquete legible por máquina está en `docs/research/nasa-reference-data.json`.
- **Si solo hay 30 minutos:** leer la sección 0, la tabla de la sección 4.1 y los riesgos de la sección 5.
- **Si se van a tocar datos:** leer 3.1–3.3 y usar el JSON del Apéndice A.

---

## 0. Resumen ejecutivo

1. **El encaje es bueno.** El desafío pide exactamente lo que el diseño ya hace: un juego para 7–12 años sobre una base lunar, con soporte vital, energía, blindaje, comida y decisiones con coste. La estructura de datos con procedencia NASA está alineada con el criterio de *Relevance*.
2. **El mayor riesgo de entrega no es el juego: es el demo.** La guía oficial limita el demo a **30 segundos de vídeo o 7 diapositivas**. El plan actual de “demo del juez de 2–5 minutos” no cumple; hay que grabar un corte de 30 s y tener el fallback de 7 slides.
3. **La radiación debe pasar a mSv y a un presupuesto de misión de 250 mSv.** El 30 %/100 % actual es arbitrario y no se mueve con la dosis real: 12,5 días de GCR lunar son ~10,5 mSv (4 % de 250 mSv). La amenaza dramática tiene que ser un **evento de partículas solares (SPE)**, no el goteo de GCR. Este es el cambio de datos con más impacto educativo y de rúbrica.
4. **El ciclo día/noche 12/12 no es lunar.** El día lunar son **29,53 días terrestres**; en el ecuador hay ~14,75 días de luz y ~14,75 de noche; en el polo sur hay **80–90 % de iluminación** y eclipses de hasta **100 h**. Si se mantiene el 12/12 por jugabilidad, hay que etiquetarlo como “reloj de la base (tiempo comprimido)” y no como dato real. Además, una misión de 12,5 días es más corta que un ciclo de cultivo de 28 días: el invernadero no puede ser la fuente principal de calorías.
5. **La pestaña Resources es corta; el catálogo de APIs de NASA es más rico.** Además de DONKI, OSDR y RadLab, el catálogo incluye **Moon Trek WMTS** (teselas reales de la Luna) y la **NASA Image and Video Library**. Añadir un panel *Data Sources* con 8 fuentes verificadas cuesta poco y sube directamente *Relevance* y *Validity*.

---

## 1. El desafío, sin interpretación

### 1.1 Ficha oficial

| Campo | Valor |
| --- | --- |
| Evento | 2026 NASA Space Apps Challenge |
| Desafío | *Build a Junior Astronaut Mission Trainer* |
| Dificultad | Intermediate; Beginner/Youth |
| Materias | Games, Planets & Moons, Software, Space Exploration, Sun |
| Audiencia | Niños de **7–12 años** |
| Formato | Juego o app interactiva; navegador, móvil o escritorio |
| Duración de la misión | “Over the course of a simulated mission” (no fija) |
| Datos | NASA open data; se acepta dataset archivado si se etiqueta honestamente |

### 1.2 Objetivo, en palabras del brief

> “Your challenge is to design and build an interactive game or app that lets students run a lunar or Martian outpost, balancing competing demands like life support, radiation shielding, power, and food production, so they experience firsthand the decisions that determine whether a mission fails or succeeds.”

> “...kids ages 7–12 manage a lunar or Martian outpost, making real decisions about life support, radiation shielding, power budgeting, food production, and communication delay, and experiencing how those choices play out over the course of a simulated mission.”

El brief insiste en tres cosas:

- **Trade-offs reales:** “no choice is free”.
- **Datos NASA reales:** DONKI para clima espacial, OSDR para salud/biología, Artemis/Mars para entorno.
- **Traducción para niños:** lenguaje claro, sin jerga; explicar “radiation dose”, “microgravity”, “lunar day” en contexto.

### 1.3 Restricciones y errores que el brief pide evitar

| El brief pide | Implicación para el juego |
| --- | --- |
| **2–3 recursos núcleo** (“life support, power, shielding”) | El diseño actual usa 4 recursos + radiación + salud. Es el punto más discutible de *Relevance*. El corte de emergencia a “provisions” ya está previsto; si el playtest no aguanta, hay que ejecutarlo. |
| **Cada elección tiene coste** | Bien resuelto: reparar cuesta ticks/energía; salir cuesta dosis; el refugio cuesta tiempo/energía. |
| **No sustituir mecánica por pulido** | El juego debe enseñar una restricción real, no solo verse bonito. |
| **No saturar con 5–6 sistemas** | 8 máquinas, 7 paneles y 4 submisiones pueden ser demasiado para 7–12 años. La UI debe ocultar lo avanzado. |
| **Atribuir los datos dentro de la herramienta** | El panel *Data Sources* y los badges `archived`/`simulated` son obligatorios de facto. |
| **Rejugabilidad** | Los eventos deben variar entre partidas; con filas deterministas, hace falta un “deck” de 2–3 variantes. |
| **Enlace a datos actuales** | Un evento que se conecte con clima espacial real (DONKI) es el ejemplo que el brief pone como “stand out”. |

### 1.4 Qué haría destacar la solución, según el brief

- Que el jugador **vea la consecuencia real** de una decisión (p. ej., blindaje ↔ clima espacial actual).
- **Rejugabilidad**: eventos/mecánicas que cambian entre partidas.
- Un **prototipo funcional + explicación corta** de qué datasets NASA se usaron y por qué.

### 1.5 Recursos oficiales de la pestaña Resources

La página lista exactamente estos (más dos de CSA):

| Recurso | URL | Qué aporta |
| --- | --- | --- |
| NASA Open APIs | https://api.nasa.gov/ | Portal central; API key gratuita; DONKI, OSDR, etc. |
| DONKI | https://ccmc.gsfc.nasa.gov/tools/DONKI/ | CME, flares, SEP, RBE; clima espacial real. |
| OSDR | https://osdr.nasa.gov/bio/repo/ | Estudios de biología espacial y salud de astronautas. |
| OSDR search API | https://osdr.nasa.gov/osdr/data/search?term=KEYWORD | Búsqueda programática por keyword. |
| RadLab | https://visualization.osdr.nasa.gov/radlab/gui/data-api/ | Dosimetría real de ISS, Artemis I, CRaTER, etc. |
| Mars Trek | https://trek.nasa.gov/mars/ | Terreno marciano real. |
| CSA STEM | https://www.asc-csa.gc.ca/eng/youth-educators/resources-stem-and-youth-organizations.asp | Recursos educativos bilingües. |
| CSA food production | https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/ | Kit sobre comida en el espacio. |

**Observación:** la página oficial lista OSDR y su search API, y RadLab (que contiene datos de CRaTER), pero **no menciona Moon Trek ni NASA-STD-3001** y no explicita que RadLab incluye CRaTER. Esas son las fuentes más útiles para un juego lunar; usarlas es legítimo y refuerza *Relevance*, solo hay que citarlas.

### 1.6 Reglas de entrega que pueden descalificar (críticas)

Del *2026 Project Submission Guide*:

- **Demo:** vídeo de **30 segundos o menos** **o** presentación de **máximo 7 diapositivas** (incluyendo título e intro). “Projects that exceed these limits will not be eligible for Global Judging.”
- **Enlaces públicos:** sin contraseña, permiso ni registro; el jurado debe poder abrirlos.
- **Idioma:** inglés en la página del proyecto y en los materiales enlazados; el vídeo puede ir en otro idioma **con subtítulos en inglés**.
- **Datos NASA:** para ser elegible a un Global Award hay que usar **al menos un dato o recurso NASA**.
- **Referencias:** listar todo el código, texto e imágenes externas, aunque sean open source.
- **SI (Super Intelligence):** declarar qué herramientas de IA se usaron y cómo; las imágenes/vídeo generados con IA deben llevar marca visible; audio y código, declaración en texto/metadatos.
- **Menores:** el demo y el proyecto no pueden incluir imágenes, vídeo, audio ni semejanza de personas **menores de 18 años**.
- **Plazo:** domingo 15 de noviembre de 2026, 23:59 hora local del evento.

### 1.7 Criterios de juicio (2026)

Escala 1–5 en cada criterio:

| Criterio | Qué mira el jurado |
| --- | --- |
| **Impact** | ¿Resuelve un problema real? ¿A cuánta gente inspira/ayuda? |
| **Creativity** | ¿Es original o una mejora significativa? |
| **Validity** | ¿Es científicamente sólido, técnicamente factible y usable? |
| **Relevance** | ¿Responde al desafío? ¿Usa NASA data como componente central, no decorativo? |
| **Presentation** | ¿Comunica bien el problema, la solución y su importancia? |

Hay **10 Global Awards**: Best Use of Science, Best Use of Data, Best Use of Technology, Galactic Impact, Best Mission Concept, Most Inspirational, Best Storytelling, Global Connection, Art & Technology, Local Impact.

---

## 2. Auditoría del diseño actual frente al brief

| # | Brief / realidad | Diseño actual | Estado | Acción recomendada |
| --- | --- | --- | --- | --- |
| 1 | Audiencia 7–12 | 4 recursos, 8 máquinas, 7 paneles, 4 submisiones | **Riesgo de saturación** | Tutorial de 3 pistas; ocultar paneles avanzados; una sola barra de “life support” con sub-barras si se puede |
| 2 | 2–3 recursos núcleo | O₂, agua, comida, energía + radiación + salud | **Riesgo** | Mantener el corte H12 a “provisions”; o agrupar agua+comida en “life support” sin cambiar el sim |
| 3 | Datos NASA visibles | Schema `source`, `source_url`, `date_archived`, `archived`, `real_data` | **Fuerte** | Rellenar con los valores de la sección 3; no dejar filas reales sin fuente |
| 4 | Communication delay | Solo “corte de comunicaciones” | **Gap** | Mostrar “light delay 1.28 s” en la consola; opcional: cola de informes hasta el próximo relay pass |
| 5 | Rejugabilidad | Eventos deterministas por filas | **Parcial** | 2–3 variantes de tormenta con distinto onset/duración; mismo motor |
| 6 | Browser-playable | Windows + HTML5 | **Bien** | Probar el enlace público sin login; es el formato que el brief favorece |
| 7 | Demo 30 s / 7 slides | Demo de 2–5 min | **Bloqueante** | Grabar un corte de 30 s; tener 7 slides de fallback |
| 8 | Día/noche lunar | 12 h luz / 12 h noche | **Inexacto** | Etiquetar “outpost clock (game compression)” o mover la base al polo sur; ver 3.3 |
| 9 | Radiación | 30 % → tope de salud; 100 % → muerte | **Arbitrario** | Barra `dose / 250 mSv`; umbrales 100/250 mSv; la muerte por radiación solo a >1 Sv, si se modela |
| 10 | “Soles” | 12 soles, 24 ticks/sol | **Terminología marciana** | “Mission days” o “lunar days”; el brief no exige “sol” |
| 11 | Reserva de traje | 60 min | **Simplificación** | Etiquetar “game-scaled”; el EMU real da 7–8 h; no cambiar el balance si no hay tiempo |
| 12 | Invernadero | Produce comida por tick | **Inexacto** | Un cultivo tarda 28 días; la misión dura 12,5. Usar microgreens/vitaminas, no calorías |
| 13 | Data Sources | Panel previsto | **Bien** | Añadir 8 fuentes concretas con URL y fecha; ver 4.1 |
| 14 | 8 máquinas / 5 salas | Scope grande | **Riesgo** | No añadir máquinas nuevas; añadir tarjetas de datos y eventos, que son baratos |

### 2.1 Lo que ya está bien (no tocar)

- **Núcleo determinista por ticks** con eventos y contenidos como filas de datos: es la decisión que hace posible añadir datos NASA sin reescribir el juego.
- **Procedencia por fila** (`source`, `source_url`, `date_archived`, `archived`, `real_data`): exactamente lo que pide el brief.
- **El trade-off EVA/radiación**: salir a escanear o limpiar el panel cuesta dosis; es el ejemplo más claro de “no choice is free”.
- **La pantalla de evaluación** con contadores: cierra el arco educativo y sirve para el demo de 30 s.
- **La base de 5 salas y 8 máquinas**: alcance acotado; no hace falta ampliarlo para este desafío.
- **El export HTML5**: el brief favorece “browser-playable, no download”.

---

## 3. Datos verificados para el juego

> Todos los valores se consultaron el 2026-11-15. Las URLs y los ejemplos de API están en el JSON adjunto. “Archived” significa que el juego debe mostrar la fecha del snapshot, no presentarlo como dato en vivo.

### 3.1 Radiación — el sistema que más gana con datos reales

#### Valores medidos / publicados

| Magnitud | Valor | Fuente | Uso en el juego |
| --- | --- | --- | --- |
| GCR en superficie lunar (dosis absorbida) | **13,1 µGy/h = 0,314 mGy/día** | LRO **CRaTER** vía RadLab, enero 2010 | Tasa base del exterior |
| GCR en superficie lunar (dosis equivalente, sin blindaje) | **0,84 mSv/día** | Matthiä et al. 2024 | Tasa base de referencia |
| GCR con 20 g/cm² de regolito | **0,60 mSv/día** | Matthiä et al. 2024 | Mejora de blindaje |
| Medición total en superficie (incluye neutrones) | **1,369 mSv/día** | Chang’E-4 LND | Rango real; no usar como base si se quiere ser conservador |
| ISS (dosis absorbida) | **4,65 µGy/h = 0,112 mGy/día** | RadLab, DosTel, 1 jun 2024 | Comparación “LEO vs Luna” |
| ISS (dosis equivalente) | **0,731 mSv/día** | DOSIS 3D | Comparación |
| Artemis I, entorno lunar | **19,5 µGy/h = 0,468 mGy/día; ~11,9 mGy en 25 días** | HERA vía RadLab | Comparación “espacio profundo” |
| Límite de carrera | **600 mSv** | NASA-STD-3001 Vol. 1 Rev. B §4.8.2 | Stat de largo plazo |
| Límite para un SPE de diseño | **250 mSv** | NASA-STD-3001 §4.8.3 | **Presupuesto de misión** |
| Blindaje de regolito | **4 g/cm²** → SPE bajo límites de 30 días; **10 g/cm²** → factor 2; **20 g/cm²** → 0,6 mSv/día | Matthiä et al. 2024 | Niveles de mejora del refugio |
| Síndrome agudo por radiación | Náuseas ~1 Sv; 50 % de muerte ~4–5 Sv sin tratamiento | Consenso médico | Solo si se modela muerte por radiación |

#### Modelo propuesto (compatible con el diseño actual)

- **Barra de radiación:** `dose_mSv / 250 mSv`, no un porcentaje anónimo.
- **Umbrales:** 100 mSv (amarillo: riesgo biológico creciente), 250 mSv (rojo: límite de misión superado; Misión Control ordena abortar/regresar). Si la barra se clampa a 250, muestra “>250” y un icono de riesgo; 1.000 mSv (síntomas agudos) solo si se modela muerte.
- **GCR:** mostrarlo como **fondo** en el panel de datos (`0,84 mSv/día` sin blindaje, `0,60 mSv/día` con el refugio mejorado), no como una barra que sube sola. Así se mantiene la regla “bajo techo no crece” sin mentir: la barra de misión solo sube con EVA y SPE, y el GCR se explica aparte.
- **SPE:** una tormenta real puede añadir **50–250 mSv** en horas. El refugio reduce la ganancia un 70–90 %; sin refugio, el evento puede agotar el presupuesto de 250 mSv. Esto hace que la decisión “refugiarse o terminar el escaneo” tenga un coste visible y real.
- **Consecuencia:** superar 250 mSv no es “muerte” en la realidad; es un límite que NASA no aceptaría. Para el juego, “misión abortada / evacuación” es más honesto y sigue siendo dramático. Si se quiere mantener el daño progresivo, etiquetarlo como simplificación.

#### Por qué el 30 % actual no funciona

- 12,5 días × 0,84 mSv/día = **10,5 mSv** = **4,2 %** de 250 mSv.
- Sin un SPE, la barra nunca llega al 30 %. El jugador no ve la mecánica.
- Con un SPE de 200 mSv, un solo evento mueve la barra del 4 % al 84 %. Esa es la lección: **la radiación crónica es un impuesto; la radiación aguda es la crisis**.
- Si se mantiene el 30 % de 600 mSv (=180 mSv), está cerca del límite de 250 mSv, pero el denominador no se muestra. Mejor mostrar mSv.

#### Nota educativa

- **GCR** = rayos cósmicos galácticos, crónicos, difíciles de blindar; el regolito ayuda poco.
- **SPE** = partículas solares energéticas, agudas, muy peligrosas sin refugio; 4 g/cm² ya ayudan.
- **Dosis equivalente** en mSv; **dosis absorbida** en mGy. No son lo mismo; el juego puede usar mSv y explicarlo en el glosario.

### 3.2 Soporte vital — cifras para las filas de `economy.tres`

| Magnitud | Valor | Fuente | Uso |
| --- | --- | --- | --- |
| O₂ | **0,84 kg/persona/día** (35 g/h) | NASA NTRS 20090034853 | Consumo base |
| Agua total | **4,35 kg/persona/día** (181 g/h) | Frontiers 2024 / BVAD | Consumo base |
| — bebida | 2,00 kg/día | BVAD | Sub-barra |
| — rehidratar comida | 0,50 kg/día | BVAD | Sub-barra |
| — higiene | 0,40 kg/día | BVAD | Sub-barra |
| — flush | 0,30 kg/día | BVAD | Sub-barra |
| — agua en comida | 0,70 kg/día | BVAD | Sub-barra |
| — agua metabólica | 0,40 kg/día | BVAD | Sub-barra |
| Comida (sólidos) | **0,62 kg/persona/día** (26 g/h) | NASA NTRS 20090034853 | Consumo base |
| Comida empaquetada | **2,39 kg/persona/día** | BVAD | Masa logística |
| CO₂ producido | **1,0 kg/persona/día** | NASA NTRS | Subproducto; el reciclador lo usa |
| Recuperación de agua ISS | **93–94 %** (98 % con BPA) | NASA 2023 | Eficiencia del reciclador |
| Recuperación de O₂ del CO₂ | **~42 %** | ISS OGA/CDRA | Eficiencia del sistema de O₂ |
| Misión de 12,5 días | **10,5 kg O₂, 54,4 kg agua, 7,75 kg comida** | Cálculo | “Días de reserva” en tooltip |

**Cómo mostrarlo sin complicar la UI:** las barras siguen en “unidades”, pero el tooltip dice `Oxígeno: 8,4 kg (10 días)`. Eso convierte una barra abstracta en una cifra real y no añade un sistema nuevo.

**Ejemplo de mapeo a barras 0–100:** si una barra llena representa la carga inicial para 12,5 días, O₂ = 10,5 kg, agua = 54,4 kg, comida = 7,75 kg. Por tick de 1 h: **0,035 kg O₂, 0,181 kg agua, 0,026 kg comida**. Si la barra son 100 unidades, 1 unidad = 0,105 kg O₂, 0,544 kg agua, 0,0775 kg comida. El consumo por tick en unidades es 0,333 / 0,333 / 0,333; es decir, las tres barras duran lo mismo si se llenan con la carga de 12,5 días, que es exactamente lo que el diseño quiere para que ninguna sea “gratis”.

### 3.3 Energía y entorno lunar

| Magnitud | Valor | Fuente | Uso |
| --- | --- | --- | --- |
| Distancia Tierra–Luna | 384.400 km | NASA Moon Facts | Contexto |
| Retardo de luz (ida) | **1,28 s** | c = 299.792 km/s | Consola de comunicaciones |
| Retardo ida y vuelta | 2,56 s | Cálculo | “Live” con lag |
| Irradiancia solar | **1.361 W/m²** | NASA Moon Fact Sheet | Panel solar |
| Día lunar | **708,7 h = 29,53 días terrestres** | NASA SVS | Calendario |
| Luz/oscuridad en el ecuador | ~14,75 / ~14,75 días | NASA | Si se usa el ecuador |
| Iluminación en el polo sur | **80–90 % del año** | NASA NTRS | Si se usa el polo |
| Eclipse polar máximo | **~100 h** | NASA VSAT | Evento de batería |
| Temperatura | **+127 °C / −173 °C** | NASA Moon Facts | Color/ambiente; evento térmico |
| Gravedad | **1,62 m/s²** (1/6 g) | NASA Moon Fact Sheet | Movimiento/animación |
| Atmósfera | Ninguna (exosfera) | NASA | Sin sonido, sin viento |
| Polvo | Abrasivo, electrostático; **sin viento** | NASA EDS | Evento de polvo; no “tormenta de arena” |
| EDS (limpieza eléctrica) | **82 %** en radiador térmico; **97 %** en vidrio | NASA EDS 2025 | Mejora de limpieza |
| VSAT 10 kW | 10 kW inicial, 5 kW operativo; **7 kWh** de baterías ion para ~100 h (keep-alive, no 5 kW plenos) | NASA NTRS 20210011743 | Batería del refugio |
| Fisión superficial | 40 kW | NASA FSP | Referencia de potencia |

**Decisión de diseño recomendada (bajo coste):**

- Mantener el ciclo 12/12 si ya está implementado, pero **llamarlo “outpost clock”** y añadir en el panel de datos: “Real lunar day: 29.53 Earth days; game clock is compressed.” Eso convierte una inexactitud en una decisión declarada.
- Si hay tiempo, mover la base al **polo sur (Shackleton)** y cambiar el evento de “noche” por un **eclipse de 100 h**. Es más real, más Artemis y más interesante: el panel solar produce poco, la batería es crítica y el refugio compite por energía.
- El polvo no viene del viento: viene de impactos, actividad humana y levitación electrostática. Un evento de “polvo” debe ser “el panel ha acumulado regolito”; la acción de limpiar con cepillo lo empeora (real: el cepillo raya y carga más); la mejora EDS lo resuelve.

### 3.4 Comunicaciones

| Magnitud | Valor | Uso |
| --- | --- | --- |
| Retardo Tierra–Luna | **1,28 s ida**; 2,56 s ida/vuelta | Mostrar “Light delay: 1.28 s” en la consola |
| Control en tiempo real | No es posible para un rover | Explicar por qué los informes son asíncronos |
| Relay pass | Ventanas periódicas (LCRNS) | Opcional: los informes salen en el próximo pase, no al instante |
| Marte (futuro) | 3–22 min ida | Solo si se añade modo Marte |

**Uso concreto:** en la consola, un informe enviado muestra “Sent • arrives in 1.28 s” y, si se quiere, “Next relay pass in 2 h”. No es un sistema nuevo; es un texto y un contador.

### 3.5 Clima espacial — eventos reales para `events.tres`

| Evento | Datos clave | Por qué es útil |
| --- | --- | --- |
| **Tormenta G5, mayo 2024** | Kp **9,0**; X1.6 (3 may), M9.1 (4 may), X1.3 (5 may); CMEs **800–970 km/s**; SEP desde **2024-05-09T13:59Z**; eventos SEP hasta el 13 may | El “peor caso” real y reciente; 1–2 días de aviso desde el CME; decisión de refugio |
| **CME O-type, 17 oct 2026** | **1.048 km/s**; semiángulo 38°; dirección −99/−4 HEEQ (no dirigido a la Tierra); M1.3 (16 oct) y M1.6 (19 oct); RBE >1.000 pfu; Kp ≤3,67 | Una semana “tranquila” con un CME rápido que no impacta: enseña que no todo evento es crisis |
| **SPE de referencia 1989** | El evento de diseño de NASA-STD-3001; límite **250 mSv** | Calibra la magnitud de la tormenta del juego |

**Uso concreto:** tres tarjetas de evento, no tres sistemas:

- `storm_g5_2024`: “CME lanzado hace 36 h; llegada prevista en 12 h; dosis estimada 200 mSv sin refugio.”
- `storm_miss_2026`: “CME de 1.048 km/s; no impacta; sin dosis. Aprovecha para mantener la base.”
- `storm_reference_1989`: “Evento de diseño NASA; 250 mSv; el refugio de 10 g/cm² es la diferencia entre misión y aborto.”

Esto da **rejugabilidad** (tres resultados distintos) sin código nuevo: son filas de datos.

### 3.6 Salud del astronauta — estudios OSDR para el “Science Log”

OSDR mezcla estudios humanos, animales y análogos de tierra (bed rest, hindlimb unloading). Las seis entradas siguientes son ejemplos reales y citables; no todas son hallazgos medidos en astronautas, y el juego debe decirlo así en la tarjeta (“study in mice”, “bed-rest analog”, etc.).

| Accesión | Estudio | Hallazgo | Uso |
| --- | --- | --- | --- |
| **OSD-804** | 37-Day microgravity exposure... Rodent Research 1 | Pérdida ósea en sitios de carga (fémur, vértebras) | “Las misiones largas cuestan hueso.” |
| **OSD-471** | Spaceflight-Induced Bone Loss... Bion-M1 | 30 días reducen densidad y resistencia a la flexión | “El hueso no solo pierde masa: pierde resistencia.” |
| **OSD-195** | Effects of 21 days of bedrest on human skeletal muscle gene expression | 21 días de reposo cambian la expresión génica del músculo | “El desuso cuesta músculo.” |
| **OSD-946** | Exercise Training Attenuates the Muscle Mitochondria Genomic Response to Bed Rest | El ejercicio atenúa el efecto del reposo | “El ejercicio es una contramedida real.” |
| **OSD-53** | Spaceflight Modulates Gene Expression in Astronauts | El vuelo espacial cambia la expresión génica | “El cuerpo se adapta de forma medible.” |
| **OSD-656** | SpaceX Inspiration4 Urine Inflammation Panel | Panel de inflamación en orina de la tripulación | “La vigilancia inmunológica es parte de la salud.” |

**Uso concreto:** tarjetas de “Science Log” en la consola; cada una con “What NASA learned” + “What it means for your outpost”. No añaden mecánicas; suben *Relevance* y dan texto educativo real.

### 3.7 Comida y cultivos

| Dato | Valor | Uso |
| --- | --- | --- |
| Calorías diarias | **1.900–3.200 kcal** según tripulante | Tooltip de comida |
| Comida empaquetada | 2,39 kg/persona/día | Masa logística |
| Cultivo de lechuga (Veggie) | ~28 días | Si el invernadero produce lechuga |
| Microgreens | ~10–14 días | Alternativa para una misión de 12,5 días |
| CSA / CEA | Agricultura de ambiente controlado; Deep Space Food Challenge | Contexto/futuro |

**Nota:** el ciclo de ~28 días de la lechuga Veggie es NASA; los 10–14 días de microgreens son una **estimación hortícola**, no un dato NASA. Si se usa, etiquetarlo como “estimación”.

**Decisión recomendada:** con una misión de 12,5 días, el invernadero **no puede sustituir las calorías**. Que produzca **vitaminas/frescura/moral** (microgreens) y que la comida base sea empaquetada. Así el recurso “comida” sigue siendo logístico y el invernadero tiene un papel real sin mentir sobre los tiempos de cultivo.

### 3.8 Mapas reales — Moon Trek

- Portal: https://trek.nasa.gov/moon/
- Teselas WMTS (ejemplo, mosaico LRO WAC):
  `https://trek.nasa.gov/tiles/Moon/EQ/LRO_WAC_Mosaic_Global_303ppd_v02/1.0.0/default/default028mm/{z}/{y}/{x}.jpg`
- Documentación: https://trek.nasa.gov/tiles/apidoc/trekAPI.html?body=moon

**Uso concreto:** no hace falta usar las teselas en el pixel-art; basta con:

- ambientar la base en **Shackleton / polo sur** (es el destino Artemis);
- una tarjeta “Location: Shackleton crater rim” con enlace a Moon Trek;
- opcional: una imagen real del cráter en la pantalla de bienvenida o en el panel de datos.

### 3.9 APIs: estado y trampas (2026)

| API | Estado | Nota |
| --- | --- | --- |
| NASA Open APIs | Activo | 1.000 req/h; DEMO_KEY 30/h y 50/día |
| DONKI (CME, GST, SEP, notifications) | Activo | El endpoint **FLR devolvió 404** en esta revisión; usar CME/GST/SEP/notifications |
| OSDR search | Activo | `https://osdr.nasa.gov/osdr/data/search?term=...` |
| RadLab | Activo | `absorbed_dose_rate` en µGy/h y `dose_equivalent_rate` en µSv/h |
| Moon/Mars Trek WMTS | Activo | Teselas reales; requiere leer `GetCapabilities` |
| Mars Rover API | **Archivada** | No usarla |
| Earth API | **Archivada** | Sustituida por Earthdata GIBS |
| APOD legacy | **Se archiva el 2026-12-01** | Usar el endpoint nuevo |

**Para el juego:** no hace falta HTTP en runtime. Guardar los JSON/CSV en `game/databases/sources/` y mostrar `archived: true` + fecha. Si se quiere una demo “live”, que sea un extra y no el camino crítico.

### 3.10 Recetas para reproducir los números

```text
CRaTER (superficie lunar, enero 2010):
https://visualization.osdr.nasa.gov/radlab/api/?celestial_body=Moon&instrument=CRaTER&absorbed_dose_rate&timestamp%3E=2010-01-01&timestamp%3C2010-02-01&format=json

ISS (DosTel, 1 junio 2024):
https://visualization.osdr.nasa.gov/radlab/api/?spacecraft=ISS&timestamp%3E=2024-06-01T00:00&timestamp%3C2024-06-01T01:00&absorbed_dose_rate&instrument&format=json

Artemis I (HERA, nov-dic 2022):
https://visualization.osdr.nasa.gov/radlab/api/?celestial_body=Moon&instrument=HERA-HSU1&absorbed_dose_rate&timestamp&format=json

DONKI (notificaciones recientes):
https://api.nasa.gov/DONKI/notifications?startDate=2026-10-15&endDate=2026-11-15&api_key=DEMO_KEY

DONKI (tormenta G5 de mayo 2024):
https://api.nasa.gov/DONKI/GST?startDate=2024-05-01&endDate=2024-06-01&api_key=DEMO_KEY
https://api.nasa.gov/DONKI/SEP?startDate=2024-05-01&endDate=2024-06-01&api_key=DEMO_KEY

OSDR (búsqueda):
https://osdr.nasa.gov/osdr/data/search?term=bone%20loss
https://osdr.nasa.gov/osdr/data/search?term=bed%20rest
```

---

## 4. Qué añadir, por prioridad

> Contexto: el hackathon termina hoy. La prioridad es no romper el build y cumplir la entrega. “P0” es lo que se puede hacer en horas y sube rúbrica; “P1” solo si el build ya está estable; “P2” es post-evento.

### 4.1 P0 — hoy, antes de entregar

| # | Cambio | Coste | Criterio que sube |
| --- | --- | --- | --- |
| 1 | **Panel Data Sources** con 8 entradas: DONKI, RadLab/CRaTER, OSDR, NASA-STD-3001, BVAD, Moon Facts, Moon Trek, EDS. Cada una con URL, fecha y badge `archived`/`simulated`. | 1 h | Relevance, Validity |
| 2 | **Radiación en mSv**: `dose / 250 mSv`; GCR 0,84 mSv/día; SPE 50–250 mSv; refugio 4/10/20 g/cm²; umbrales 100/250 mSv. | 1–2 h | Validity, Impact |
| 3 | **Soporte vital en kg**: O₂ 0,84; agua 4,35; comida 0,62 kg/persona/día; tooltip “días de reserva”. | 1 h | Validity |
| 4 | **Tres tarjetas de evento reales**: G5 mayo 2024, CME 2026 que no impacta, SPE de referencia 1989. | 1 h | Relevance, Creativity |
| 5 | **Demo de 30 s** + fallback de 7 slides. | 1 h | Presentation (elegibilidad) |
| 6 | **Strings**: “soles” → “mission days”; “12/12” → “outpost clock”; “30 %” → “250 mSv limit”; “60-min suit” → “game-scaled reserve”. | 30 min | Validity |
| 7 | **Página de proyecto**: campo NASA Data, referencias, declaración SI, enlaces públicos. | 30 min | Elegibilidad |

### 4.2 P1 — solo si el build está estable

| # | Cambio | Coste | Criterio |
| --- | --- | --- | --- |
| 8 | **5 tarjetas OSDR** en el Science Log (OSD-804, -471, -195, -946, -53). | 2 h | Relevance |
| 9 | **Retardo de 1,28 s** en la consola + “next relay pass” para informes. | 1–2 h | Relevance |
| 10 | **Evento de polvo + mejora EDS**: limpiar a mano empeora; EDS recupera 97 %. | 1 h | Validity |
| 11 | **Tarjeta “Shackleton / polo sur”** con enlace a Moon Trek. | 30 min | Relevance |

### 4.3 P2 — post-evento

- **Eclipse polar de 100 h** como evento de energía (sustituye al 12/12).
- **Ejercicio diario** como contramedida de salud (30 min; consume O₂/agua/energía; frena el daño).
- **Modo Marte** con retardo de 3–22 min y cultivos de ciclo largo.
- **Rejugabilidad**: “mission seed” que baraja las filas de eventos; mismo motor.
- **Moon Trek tiles** para una pantalla de mapa o la intro.

### 4.4 Lo que NO añadir ahora

- Un quinto recurso, una novena máquina o un sistema de investigación.
- Multijugador, save/persistencia, mundo abierto.
- Datos “live” en runtime si no están probados; el brief acepta archivado y es más seguro.
- Texto largo en pantalla para niños de 7 años; el glosario debe ser contextual.

---

## 5. Riesgos y trampas

| Riesgo | Por qué importa | Mitigación |
| --- | --- | --- |
| **Demo >30 s** | Queda fuera de Global Judging | Grabar 30 s exactos; usar el guion del Apéndice B |
| **4 recursos vs 2–3** | El jurado puede verlo como sobrecarga | Ejecutar el corte a “provisions” si el playtest no lo sostiene |
| **12/12 lunar** | Un juez con conocimiento lo detecta | Etiquetar “outpost clock (compressed)” o mover al polo sur |
| **Cultivo de 28 días en misión de 12,5** | El invernadero no puede dar calorías | Microgreens/vitaminas; comida base empaquetada |
| **Radiación = muerte a 250 mSv** | 250 mSv es un límite, no una dosis letal | “Misión abortada” o daño progresivo etiquetado como simplificación |
| **Datos “live” falsos** | El brief lo prohíbe explícitamente | Badge `archived` + fecha; no decir “live” |
| **APIs cambiadas** | Mars Rover/Earth archivadas; FLR 404 | Usar snapshots; no depender de endpoints frágiles |
| **Copyright / NASA branding** | El proyecto debe ser original; no usar logos NASA | Arte CC0 propio; citar todo; no usar el logotipo NASA |
| **Enlace HTML5 privado** | El jurado no puede abrirlo | Probar en ventana privada; sin login |
| **Texto en español** | La página debe estar en inglés | Strings en inglés; el vídeo puede ir subtitulado |
| **Menores en el demo** | Prohibido por Terms | No usar imágenes de niños; usar siluetas/avatar |
| **SI sin declarar** | Se evalúa la originalidad | Declarar herramientas y marcar imágenes generadas |

### Checklist de “jurado en 3 minutos”

- [ ] ¿Un niño de 7 años entiende la primera pantalla sin leer un párrafo?
- [ ] ¿Cada decisión tiene un coste visible en un número?
- [ ] ¿Cada número tiene una fuente NASA visible (o badge “simulated”)?
- [ ] ¿El demo dura 30 s o menos?
- [ ] ¿El enlace del juego abre sin login en una ventana privada?
- [ ] ¿La página del proyecto está en inglés y tiene NASA Data + References + SI?
- [ ] ¿El juego no muestra logos NASA ni imágenes de menores?

---

## 6. Fuentes

| Fuente | URL |
| --- | --- |
| Página del desafío (Details) | https://www.spaceappschallenge.org/2026/challenges/junior-astronaut-mission-trainer/ |
| Página del desafío (Resources) | https://www.spaceappschallenge.org/2026/challenges/junior-astronaut-mission-trainer/?tab=resources |
| Project Submission Guide 2026 | https://www.spaceappschallenge.org/resources/project-submission-guide/ |
| Judging & Awards Guide 2026 | https://www.spaceappschallenge.org/resources/judging-awards-guide/ |
| NASA Open APIs | https://api.nasa.gov/ |
| DONKI | https://ccmc.gsfc.nasa.gov/tools/DONKI/ |
| OSDR | https://osdr.nasa.gov/bio/repo/ |
| OSDR search API | https://osdr.nasa.gov/osdr/data/search?term=KEYWORD |
| RadLab | https://visualization.osdr.nasa.gov/radlab/gui/data-api/ |
| Moon Trek | https://trek.nasa.gov/moon/ |
| Moon Trek WMTS docs | https://trek.nasa.gov/tiles/apidoc/trekAPI.html?body=moon |
| NASA Image and Video Library | https://images.nasa.gov/ |
| Mars Trek | https://trek.nasa.gov/mars/ |
| NASA Moon Facts | https://science.nasa.gov/moon/facts/ |
| NASA SVS, 100 Lunar Days | https://svs.gsfc.nasa.gov/12739/ |
| NASA-STD-3001 Vol. 1 Rev. B | https://www.nasa.gov/wp-content/uploads/2020/10/2022-01-05_nasa-std-3001_vol.1_rev._b_final_draft_with_signature_010522.pdf |
| Matthiä et al. 2024 (lunar shielding) | https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2024SW004095 |
| Chang’E-4 LND (Science Advances) | https://www.science.org/doi/10.1126/sciadv.aaz1334 |
| NASA life support mass balance (NTRS) | https://ntrs.nasa.gov/api/citations/20090034853/downloads/20090034853.pdf |
| NASA ISS water recovery | https://www.nasa.gov/missions/station/iss-research/nasa-achieves-water-recovery-milestone-on-international-space-station/ |
| NASA EDS lunar demo | https://www.nasa.gov/image-article/nasas-dust-shield-successfully-repels-lunar-regolith-on-moon/ |
| NASA Lunar Surface Technology | https://www.nasa.gov/lunar-surface-technology/ |
| NASA Fission Surface Power | https://www.nasa.gov/exploration-systems-development-mission-directorate/fission-surface-power/ |
| CSA food production | https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/ |

---

## Apéndice A — Paquete de datos

El JSON `docs/research/nasa-reference-data.json` contiene los mismos valores con campos listos para copiar a `game/databases/sources/`:

- `radiation`: tasas, límites y blindaje.
- `life_support`: consumos por persona/día y totales de 12,5 días.
- `environment`: día lunar, temperaturas, retardo, polvo.
- `power`: VSAT, FSP, iluminación polar.
- `space_weather_events`: G5 2024, CME 2026, SPE 1989.
- `osdr_studies`: 6 accesiones con hallazgo y uso.
- `apis`: endpoints, rate limits y problemas conocidos.

---

## Apéndice B — Guion de demo de 30 segundos

Basado en la estructura que pide la guía oficial (0:00–0:30):

| Tiempo | Qué se ve / dice |
| --- | --- |
| 0:00–0:02 | “We are Team [X].” |
| 0:02–0:05 | “NASA’s challenge: kids 7–12 running a lunar outpost.” |
| 0:05–0:10 | “**Junior Astronaut Mission Trainer**: repair machines, budget power, survive real solar storms.” |
| 0:10–0:20 | Gameplay: a storm warning, a choice (shelter vs scan), the dose bar moving, the data card with the NASA source. |
| 0:20–0:30 | “Every number comes from NASA: CRaTER dose, DONKI storms, OSDR health studies. One choice can save the mission — or cost the crew. Play it in your browser.” |

**Reglas:** 30 s exactos; subtítulos en inglés si se habla en español; sin menores en pantalla; sin logos NASA; enlace público.

## Apéndice C — Fallback de 7 slides

1. Título + equipo.
2. El desafío (7–12, base lunar, trade-offs).
3. El problema (contenido STEM simplificado).
4. La solución: loop de juego y decisiones.
5. Datos NASA usados (DONKI, CRaTER, OSDR, BVAD) y por qué.
6. Validación / impacto / lo que aprende un niño.
7. Futuro + enlaces (juego, repo, vídeo).

---

*Documento de trabajo. Los valores son snapshots verificados el 2026-11-15; si se usan en el juego, cada fila debe llevar su `source_url`, `date_archived`, `archived` y `real_data`.*
