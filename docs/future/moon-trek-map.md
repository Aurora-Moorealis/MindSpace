# Futuro: mapa real con Moon Trek

- **Estado:** Idea
- **Prioridad:** P2
- **Esfuerzo:** S
- **Depende de:** pantalla de bienvenida / mapa
- **Documentos relacionados:** `docs/research/nasa-space-apps-2026-junior-astronaut.md` (§3.8)

## 1. Qué es

Usar **datos reales de la Luna** (Moon Trek / LRO) en una pantalla de mapa o en la intro, sin convertir el pixel-art en un mapa satelital.

No es un tileset de gameplay. Es una **tarjeta de ubicación** y, si se quiere, una **imagen de bienvenida** con el polo sur real.

## 2. Por qué

- Refuerza que la base está en un lugar real (Shackleton / polo sur), no en “la Luna genérica”.
- Es una fuente NASA visual, fácil de citar y muy barata.
- El brief valora que el dato NASA sea central; un mapa real con atribución lo hace visible en 5 segundos.

## 3. Datos reales que lo anclan

| Dato | Valor |
| --- | --- |
| Portal | `https://trek.nasa.gov/moon/` |
| Documentación WMTS | `https://trek.nasa.gov/tiles/apidoc/trekAPI.html?body=moon` |
| Mosaico base | LRO WAC global, ~15.000 imágenes (2009–2011), 83 m/px en el ecuador |
| Plantilla de tesela | `https://trek.nasa.gov/tiles/Moon/EQ/LRO_WAC_Mosaic_Global_303ppd_v02/1.0.0/default/default028mm/{z}/{y}/{x}.jpg` |
| Zona | Shackleton / polo sur |
| Licencia | NASA/JPL/SSERVI; obra del Gobierno de EE. UU. (verificar atribución) |

## 4. Cómo funcionaría

### 4.1 Tarjeta de ubicación

En la pantalla de bienvenida o en el panel de datos:

- Una imagen del polo sur (Shackleton) con un marcador.
- Texto: “Shackleton crater rim — 89.9° S, 0.0° E”.
- Enlace a Moon Trek.
- Badge `archived` + fecha de descarga.

### 4.2 Imagen de bienvenida

- Descargar 6–12 teselas del polo sur en build time.
- Unirlas en una sola imagen PNG (p. ej., 1024×1024) y guardarla en `game/assets/images/map/`.
- No usar HTTP en runtime; la imagen va en el build.

### 4.3 Minimapa (opcional)

- Un minimapa de la base, no del cráter; el mapa real es solo contexto.
- No mezclar la estética satelital con los tiles de 32 px; usar la imagen como *backdrop* oscurecido.

## 5. Diseño técnico

- `game/assets/images/map/shackleton_1024.png` + `.import`.
- `game/content/map/location_card.tscn` con `TextureRect`, texto y enlace.
- Atribución visible: “Imagery: NASA/JPL/SSERVI — Moon Trek”.
- Sin dependencia de red; sin nuevos autoloads.
- Si se usan teselas WMTS en runtime (HTML5), probar CORS y cachear; no es el camino recomendado.

## 6. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| Choque estético con el pixel-art | Usar la imagen como fondo oscurecido, no como tiles de juego |
| Resolución/zoom insuficiente | Descargar el nivel de zoom adecuado; 1024 px basta para una tarjeta |
| Peso del archivo | Una sola imagen comprimida; no un tileset completo |
| Atribución incorrecta | Texto visible con NASA/JPL/SSERVI y enlace |
| Dependencia de red | Solo build time; el juego no fetchea |

## 7. Criterios de aceptación

- [ ] Hay una imagen real del polo sur con atribución visible.
- [ ] La tarjeta dice “Shackleton” y enlaza a Moon Trek.
- [ ] El juego funciona sin red.
- [ ] La imagen no sustituye los tiles de gameplay.
- [ ] El archivo pesa menos de ~1 MB.
