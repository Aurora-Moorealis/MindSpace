# Investigación — qué miramos y qué concluimos

- **Fecha:** 2026-11-15
- **Alcance:** página oficial del desafío, guías de entrega y juicio, recursos NASA y datos reales para el juego.
- **Informe completo:** `docs/research/nasa-space-apps-2026-junior-astronaut.md`
- **Paquete de datos:** `docs/research/nasa-reference-data.json`

Este documento es la síntesis que alimenta el resto de `docs/future/`. No repite el informe completo: fija lo que sabemos, lo que decidimos y lo que queda abierto.

---

## 1. El desafío

### 1.1 Qué pide

- Un juego o app para **niños de 7–12 años** que gestione una base **lunar o marciana**.
- Decisiones reales sobre **soporte vital, blindaje, energía, comida y retardo de comunicaciones**.
- **Datos NASA** como componente central, no decorativo.
- Un prototipo funcional; formato abierto (navegador, móvil, escritorio).

### 1.2 Reglas de entrega que condicionan el diseño

| Regla | Consecuencia |
| --- | --- |
| Demo de **30 s** o **7 slides** | El demo de 2–5 min no vale para la submission; hay que grabar un corte de 30 s |
| Inglés en la página y materiales | Strings y documentación en inglés; el vídeo puede ir subtitulado |
| Al menos **un dato/recurso NASA** | El juego ya usa varios; hay que listarlos |
| Referencias de todo lo externo | Arte CC0, fuentes, datos y librerías, con URL |
| Declaración de **SI** | Herramientas de IA usadas y cómo; marcar imágenes generadas |
| Sin menores de 18 en el demo | Nada de imágenes de niños |
| Enlaces públicos sin login | El build HTML5 debe abrirse en ventana privada |

### 1.3 Criterios de juicio

**Impact, Creativity, Validity, Relevance, Presentation** (1–5 cada uno). Hay 10 Global Awards; *Best Use of Data* y *Best Use of Science* son los más alineados con el juego.

### 1.4 Recursos oficiales de la pestaña Resources

| Recurso | URL | Uso |
| --- | --- | --- |
| NASA Open APIs | https://api.nasa.gov/ | Portal y API key |
| DONKI | https://ccmc.gsfc.nasa.gov/tools/DONKI/ | Clima espacial |
| OSDR | https://osdr.nasa.gov/bio/repo/ | Salud/biología espacial |
| OSDR search API | https://osdr.nasa.gov/osdr/data/search?term=KEYWORD | Búsqueda |
| RadLab | https://visualization.osdr.nasa.gov/radlab/gui/data-api/ | Dosimetría real |
| Mars Trek | https://trek.nasa.gov/mars/ | Terreno marciano |
| CSA STEM | https://www.asc-csa.gc.ca/eng/youth-educators/resources-stem-and-youth-organizations.asp | Recursos educativos |
| CSA food | https://www.asc-csa.gc.ca/eng/youth-educators/toolkits/food-production/ | Comida en el espacio |

**Lo que la página no nombra explícitamente y sí usamos:** **Moon Trek**, **NASA-STD-3001**, **NASA Moon Facts**, **LRO/CRaTER** (vía RadLab) y **NASA Image and Video Library**. Son fuentes legítimas y refuerzan *Relevance*.

---

## 2. Datos verificados

### 2.1 Radiación

| Magnitud | Valor | Fuente |
| --- | --- | --- |
| GCR superficie lunar | **13,1 µGy/h = 0,314 mGy/día** | LRO CRaTER / RadLab, ene 2010 |
| Dosis equivalente lunar | **0,84 mSv/día** sin blindaje; **0,60 mSv/día** con 20 g/cm² | Matthiä et al. 2024 |
| Medición total en superficie | **1,369 mSv/día** | Chang’E-4 LND |
| ISS | **4,65 µGy/h = 0,112 mGy/día**; **0,731 mSv/día** | RadLab/DosTel 2024; DOSIS 3D |
| Artemis I | **19,5 µGy/h = 0,468 mGy/día**; **~11,9 mGy** en 25 días | HERA / RadLab |
| Límite de carrera | **600 mSv** | NASA-STD-3001 §4.8.2 |
| Límite SPE de diseño | **250 mSv** | NASA-STD-3001 §4.8.3 |
| Blindaje de regolito | **4 g/cm²** → SPE bajo límites de 30 días; **10 g/cm²** → factor 2; **20 g/cm²** → 0,6 mSv/día | Matthiä et al. 2024 |

**Conclusión:** la barra debe ser `dose / 250 mSv`; el GCR es un fondo de ~0,84 mSv/día y el SPE es la crisis. 12,5 días de GCR son ~10,5 mSv (4 % de 250); sin SPE la barra no se mueve.

### 2.2 Soporte vital

| Magnitud | Valor |
| --- | --- |
| O₂ | **0,84 kg/persona/día** (35 g/h) |
| Agua total | **4,35 kg/persona/día** (181 g/h) |
| Comida (sólidos) | **0,62 kg/persona/día** (26 g/h) |
| Comida empaquetada | **2,39 kg/persona/día** |
| CO₂ | **1,0 kg/persona/día** |
| Recuperación de agua ISS | **93–94 %**; **98 %** con BPA |
| Recuperación de O₂ del CO₂ | **~42 %** |
| Misión de 12,5 días | **10,5 kg O₂, 54,4 kg agua, 7,75 kg comida** |

Fuente principal: NASA NTRS 20090034853 y BVAD; recuperación de agua, NASA 2023.

### 2.3 Entorno y energía

| Magnitud | Valor |
| --- | --- |
| Distancia Tierra–Luna | **384.400 km**; luz **1,28 s** ida, **2,56 s** ida/vuelta |
| Irradiancia solar | **1.361 W/m²** |
| Día lunar | **29,53 días** (708,7 h) |
| Ecuador | ~**14,75 días** de luz / ~**14,75** de noche |
| Polo sur | **80–90 %** de iluminación; eclipses de hasta **100 h** |
| Temperatura | **+127 °C / −173 °C**; PSR hasta **−183 °C** |
| Gravedad | **1,62 m/s²** (1/6 g) |
| Atmósfera | Ninguna (exosfera) |
| Polvo | Abrasivo, electrostático, **sin viento**; EDS quita **82–97 %** |
| VSAT 10 kW | 10 kW inicial, **5 kW operativo**, **7 kWh** para ~100 h (keep-alive) |
| Fisión superficial | **40 kW** |

### 2.4 Clima espacial

| Evento | Datos |
| --- | --- |
| **G5 mayo 2024** | Kp **9,0**; X1.6 (3 may), M9.1 (4 may), X1.3 (5 may); CMEs **800–970 km/s**; SEP desde **2024-05-09T13:59Z** |
| **CME 17 oct 2026** | **1.048 km/s**; O-type; semiángulo 38°; no dirigido a la Tierra; M1.3/M1.6; RBE >1.000 pfu; Kp ≤3,67 |
| **SPE de referencia 1989** | Evento de diseño de NASA-STD-3001; **250 mSv** |

### 2.5 Salud (OSDR)

| Accesión | Hallazgo | Tipo |
| --- | --- | --- |
| **OSD-804** | Pérdida ósea en fémur/vértebras tras 37 días | Ratones, vuelo |
| **OSD-471** | 30 días reducen densidad y resistencia ósea | Ratones, Bion-M1 |
| **OSD-195** | 21 días de bed rest cambian el músculo | Humano, análogo |
| **OSD-946** | El ejercicio atenúa el efecto del bed rest | Humano, análogo |
| **OSD-53** | El vuelo cambia la expresión génica | Astronautas |
| **OSD-656** | Panel de inflamación en orina (Inspiration4) | Astronautas |

Datos de contramedidas: pérdida ósea **1–1,5 %/mes**; fuerza muscular hasta **−30 %**; ejercicio ISS **2,5 h/día, 6 días/semana**.

### 2.6 Comida

| Dato | Valor |
| --- | --- |
| Calorías | **1.900–3.200 kcal/día** |
| Lechuga Veggie | ~**28 días** |
| Microgreens | ~**10–14 días** (estimación) |
| Patata | ~**90–120 días** |

**Conclusión:** en 12,5 días el invernadero no puede dar las calorías; da frescura/vitaminas. La comida base es empaquetada.

### 2.7 Mapas

- **Moon Trek:** https://trek.nasa.gov/moon/
- Teselas WMTS (ejemplo): `https://trek.nasa.gov/tiles/Moon/EQ/LRO_WAC_Mosaic_Global_303ppd_v02/1.0.0/default/default028mm/{z}/{y}/{x}.jpg`
- Documentación: https://trek.nasa.gov/tiles/apidoc/trekAPI.html?body=moon

### 2.8 APIs: estado y trampas

| API | Estado |
| --- | --- |
| DONKI (CME/GST/SEP/notifications) | Activo; **FLR devolvió 404** en la revisión |
| OSDR search | Activo; **fetch bloqueado en la prueba** desde HTML5 (CORS/red) |
| RadLab | Activo; **fetch bloqueado en la prueba** desde HTML5 (CORS/red) |
| Moon/Mars Trek WMTS | Activo; teselas reales |
| Mars Rover API | **Archivada** |
| Earth API | **Archivada** |
| APOD legacy | **Se archiva el 2026-12-01** |

**Conclusión:** para HTML5, solo DONKI es seguro en runtime; OSDR/RadLab van por snapshot o proxy.

---

## 3. Conclusiones que afectan al futuro

1. **El demo de 30 s es el requisito más duro.** Cualquier feature futura debe caber en un guion de 30 s o en 7 slides.
2. **La radiación se modela en mSv y 250 mSv de presupuesto.** El 30 %/100 % actual queda obsoleto.
3. **El 12/12 es tiempo comprimido, no Luna real.** Si se mantiene, se etiqueta; si se cambia, el polo sur es la opción con más recorrido.
4. **El invernadero no da calorías en 12,5 días.** Es frescura/vitaminas; la comida es logística.
5. **Cuatro recursos + radiación + salud es el límite.** Cualquier sistema futuro debe reutilizar una barra existente o ser una tarjeta, no una barra nueva.
6. **La pestaña Resources oficial es corta.** Moon Trek, NASA-STD-3001 y NASA Moon Facts son las fuentes que más suben *Relevance*.
7. **La procedencia visible es el activo del proyecto.** Cada número futuro debe llevar `source`, `source_url`, `date_archived`, `archived`, `real_data`.

---

## 4. Decisiones abiertas

| Pregunta | Dueño | Estado |
| --- | --- | --- |
| ¿Se mantiene el 12/12 etiquetado o se mueve la base al polo sur? | Diseño | Abierta |
| ¿Se corta a “provisions” (agua+comida) si el playtest no aguanta? | Diseño | Abierta (gate H12) |
| ¿Se añade el panel Data Sources con 8 fuentes? | UI/Datos | Recomendado |
| ¿Se implementa el modo Marte o solo se documenta? | Producto | Post-evento |
| ¿Se usa DONKI en runtime o solo snapshot? | Técnico | Snapshot primero |
| ¿Se añade ejercicio como rutina diaria? | Diseño | Post-evento |
| ¿Qué worktree/rama implementa los cambios P0? | Equipo | Abierta |

---

## 5. Dónde está el detalle

- **Informe completo, tablas y fuentes:** `docs/research/nasa-space-apps-2026-junior-astronaut.md`
- **JSON con valores y URLs:** `docs/research/nasa-reference-data.json`
- **Roadmap y features futuras:** `docs/future/README.md`
- **Diseño v1:** `docs/designs/junior-astronauta-outpost-lunar.md`
