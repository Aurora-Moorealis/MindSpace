# Futuro: datos NASA en vivo (o casi)

- **Estado:** Propuesta
- **Prioridad:** P1
- **Esfuerzo:** M
- **Depende de:** schema de procedencia (`source`, `source_url`, `date_archived`, `archived`, `real_data`)
- **Documentos relacionados:** `docs/research/nasa-space-apps-2026-junior-astronaut.md`, `docs/designs/junior-astronauta-outpost-lunar.md`

## 1. Qué es

Un sistema para que el juego use datos NASA **actuales** sin dejar de funcionar offline. La v1 usa snapshots embebidos; este documento describe cómo añadir una capa opcional de actualización, con caché, fallback y badges honestos.

La regla de oro: **el juego nunca se bloquea esperando a una API**. Si no hay red, se usa el snapshot; si la API falla, se usa la última copia buena; si el dato es viejo, se dice.

## 2. Por qué

- El brief valora que el jugador vea “consecuencias reales” y que el dato NASA sea central, no decorativo.
- Un evento de tormenta solar conectado con DONKI es el ejemplo que el brief pone como *stand out*.
- Pero el propio brief acepta un dataset archivado si se etiqueta honestamente; la prioridad es **no romper la experiencia** por una API caída.

## 3. Qué se puede pedir a cada API

| Fuente | Endpoint | CORS desde HTML5 | Rate limit | Uso |
| --- | --- | --- | --- | --- |
| DONKI | `https://api.nasa.gov/DONKI/...` | **Sí** (probado desde otro origen) | 1.000/h; DEMO_KEY 30/h y 50/día | Tormentas, CME, SEP |
| OSDR search | `https://osdr.nasa.gov/osdr/data/search?term=...` | **No** (fetch bloqueado en la prueba) | No documentado | Estudios de salud |
| RadLab | `https://visualization.osdr.nasa.gov/radlab/api/` | **No** (fetch bloqueado en la prueba) | No documentado | Dosis reales |
| Moon Trek WMTS | `https://trek.nasa.gov/tiles/...` | Probablemente sí (teselas de imagen) | No documentado | Mapa |
| NASA Image Library | `https://images-api.nasa.gov/search?q=...` | Probablemente sí | No documentado | Stills |

**Conclusión:** en HTML5 solo DONKI es seguro de llamar directamente. OSDR y RadLab necesitan **proxy** o **snapshot en build time**. No metas una API key personal en un build público; usa `DEMO_KEY` con caché o un proxy que guarde la clave.

## 4. Tres arquitecturas posibles

### A. Snapshot en build time (recomendada)

Un script fuera del juego descarga los datos antes de exportar:

```text
tools/fetch_nasa_data.py
  → game/databases/sources/donki_2026-11-15.json
  → game/databases/sources/osdr_bone_loss.json
  → game/databases/sources/radlab_crater_2010-01.json
```

- **Ventajas:** cero HTTP en runtime; funciona en HTML5 y en Windows; reproducible; el jurado ve la fecha.
- **Desventajas:** no es “live”; hay que re-ejecutar el script para actualizar.
- **Cuándo:** v1.5 o post-evento. Es la opción más segura.

### B. Fetch en runtime con caché (opcional)

Un nodo `NasaDataFetcher` (no autoload) en la consola de comunicaciones:

1. Al abrir el panel, si hay red, pide DONKI con timeout de 5 s.
2. Guarda la respuesta en `user://nasa_cache.json` con `fetched_at`.
3. Si falla, lee el snapshot embebido.
4. La UI muestra `LIVE`, `CACHED`, `ARCHIVED` o `SIMULATED`.

- **Ventajas:** el evento puede reflejar el clima espacial del día.
- **Desventajas:** CORS, rate limits, latencia, HTML5; no debe ser el camino crítico.

### C. Proxy (solo si se quiere OSDR/RadLab en vivo)

Un worker (Cloudflare, Vercel, etc.) que:

- guarda la API key;
- normaliza CORS;
- cachea 1–24 h;
- devuelve un JSON pequeño y validado.

- **Ventajas:** resuelve CORS y claves; permite OSDR/RadLab.
- **Desventajas:** añade un servicio que mantener; el juego deja de ser 100 % offline.
- **Cuándo:** solo si el juego se publica más allá del hackathon.

## 5. Schema de procedencia

Cada fila o tarjeta que muestre un dato debe llevar:

```json
{
  "source": "DONKI",
  "source_url": "https://api.nasa.gov/DONKI/notifications?...",
  "fetched_at": "2026-11-15T12:00:00Z",
  "mode": "live",
  "real_data": true,
  "expires_at": "2026-11-15T18:00:00Z"
}
```

Reglas:

- `mode: live` solo si se ha fetcheado en las últimas **6 h** y la respuesta fue válida.
- `mode: cached` si viene de `user://` y tiene menos de **7 días**.
- `mode: archived` si viene del snapshot de build.
- `mode: simulated` si `real_data: false`.
- Si `real_data: true`, `source` y `source_url` no pueden estar vacíos.
- `date_archived` (ISO-8601) es obligatorio en modo `archived`.

## 6. Fallos y comportamiento

| Fallo | Qué hace el juego | Qué ve el jugador |
| --- | --- | --- |
| Sin red | Usa snapshot | Badge `ARCHIVED` + fecha |
| Timeout (>5 s) | Cancela y usa caché | Badge `CACHED` |
| HTTP 429 | Usa caché; no reintenta en 1 h | “NASA API limit; cached data” |
| HTTP 404 | Usa snapshot; log | Badge `ARCHIVED` |
| JSON malformado | Rechaza; conserva la última copia buena | Badge `CACHED` |
| Datos viejos (>7 días) | Conserva, pero avisa | “Data from 8 Nov” |

## 7. Diseño técnico (Godot)

- **No crear un autoload nuevo.** El fetcher vive en la escena de la consola o en un nodo hijo de `GameSim`.
- `HTTPRequest` con `timeout = 5.0`; `request_completed` → validar con `JSON.parse_string` y un `Dictionary` tipado en la frontera.
- Guardar en `user://nasa_cache.json`; en HTML5, `user://` va a IndexedDB y puede fallar en modo privado: envolver en `try`/`if FileAccess`.
- Cancelar la petición al cerrar el panel (`HTTPRequest.cancel_request()`).
- No bloquear el tick: la simulación sigue; el panel muestra “Updating…”.
- Para el modo A, el script de build es la única fuente de verdad; el juego solo lee JSON.

## 8. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| CORS en HTML5 | Solo DONKI directo; OSDR/RadLab por proxy o snapshot |
| Rate limit de DEMO_KEY | Caché de 6–24 h; no fetchear en cada apertura |
| Clave personal filtrada | Nunca en el cliente; proxy o DEMO_KEY |
| Dato “live” que no lo es | Badge calculado por `fetched_at`, no por texto fijo |
| La API cambia | Contrato de datos + test de integración; fallback |
| El juego se bloquea | Timeout y camino offline primero |

## 9. Criterios de aceptación

- [ ] El juego arranca y es jugable sin red.
- [ ] Un fallo de API nunca impide jugar ni envía un informe.
- [ ] El badge (`LIVE`/`CACHED`/`ARCHIVED`/`SIMULATED`) coincide con la antigüedad real.
- [ ] Ninguna clave personal viaja en el build.
- [ ] Un test manual con red apagada y con 429 produce el mismo comportamiento.
