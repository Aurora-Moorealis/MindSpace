# Futuro: polo sur, energía y eclipse

- **Estado:** Propuesta
- **Prioridad:** P1
- **Esfuerzo:** M
- **Depende de:** arte del exterior, `economy.tres`, `events.tres`
- **Documentos relacionados:** `docs/research/nasa-space-apps-2026-junior-astronaut.md`, `docs/designs/junior-astronauta-outpost-lunar.md`

## 1. Qué es

Mover la base lunar del ecuador imaginario al **polo sur**, cerca de **Shackleton**, y sustituir el ciclo 12/12 por la iluminación real de la zona:

- **80–90 %** de luz solar al año.
- Eclipses de hasta **100 h**.
- Sol muy bajo en el horizonte → sombras largas y paneles verticales.
- Hielo de agua en cráteres permanentemente sombreados (PSR).
- Polvo abrasivo y electrostático, sin viento.

No es solo un cambio de mapa: cambia el sistema de energía, el arte y el tipo de evento.

## 2. Por qué

- Es el destino real de **Artemis**; da credibilidad y conexión con la misión actual.
- El 12/12 actual es una simplificación; el polo sur permite ser real sin perder el bucle de batería.
- El eclipse de 100 h es un **evento de energía** mucho más interesante que “se hace de noche”.
- Permite POIs reales: borde de Shackleton, PSR con hielo, panel solar vertical, antena.

## 3. Datos reales que lo anclan

| Magnitud | Valor | Fuente |
| --- | --- | --- |
| Iluminación en el polo sur | **80–90 %** del año | NASA NTRS, *Powering the Moon* |
| Eclipse máximo | **~100 h** | NASA VSAT |
| Día lunar | **29,53 días**; 708,7 h | NASA SVS |
| Temperatura superficial | **+127 °C / −173 °C** | NASA Moon Facts |
| PSR (cráter sombreado) | hasta **−183 °C** | NASA NTRS |
| Irradiancia solar | **1.361 W/m²** | NASA Moon Fact Sheet |
| VSAT 10 kW | 10 kW inicial, **5 kW operativo**, **7 kWh** de baterías para ~100 h (keep-alive) | NASA NTRS 20210011743 |
| Fisión superficial | **40 kW** | NASA Fission Surface Power |
| Polvo / EDS | **82 %** en radiador térmico; **97 %** en vidrio | NASA EDS 2025 |
| Mapa real | LRO WAC / Shackleton | Moon Trek |

## 4. Cómo funcionaría

### 4.1 Energía

- **Panel solar vertical** (VSAT): produce según el ángulo del sol, no solo “día/noche”. A 5–10° sobre el horizonte, la producción cae; el jugador puede orientar/limpiar.
- **Batería:** se llena en los periodos de luz y cubre el eclipse. La referencia de 7 kWh para 100 h es de *keep-alive*; la base necesita apagar sistemas no esenciales.
- **Escalera de apagado:** luces → invernadero → reciclador → sistema de O₂. Es la misma del diseño, pero ahora el eclipse es la causa.
- **Reactor de fisión (40 kW):** mejora tardía; elimina el problema del eclipse, pero cuesta masa, disipación de calor y mantenimiento. Es la decisión “energía barata vs complejidad”.

### 4.2 Eclipses y clima

- **Eclipse de 100 h:** evento programado, no aleatorio. El jugador ve “Eclipse in 18 h” y decide qué apagar, qué reparar y cuánta batería reservar.
- **Tormenta solar:** el refugio de regolito sigue siendo la contramedida; el eclipse no cambia la radiación, pero el refugio compite por energía.
- **Polvo:** el panel acumula regolito; limpiar a mano cuesta tiempo/dosis y puede empeorar; la mejora EDS lo resuelve.

### 4.3 POIs reales

- **Borde de Shackleton:** vista, antena, panel solar.
- **PSR cercano:** hielo de agua; futuro ISRU.
- **Estación sísmica/radiación:** ciencia; informes a la Tierra.

## 5. Diseño técnico

- **`SiteProfile`** (Resource) con:
  - `latitude_deg = -89.9`
  - `illumination_percent = 85`
  - `eclipse_max_hours = 100`
  - `sun_angle_deg_range = [1, 10]`
  - `temperature_min_c = -183`, `temperature_max_c = 127`
  - `dust_accumulation_rate`
- **`SolarCurve`** como 3 escalares (inicio/pico/fin) para no usar `Curve` en el editor.
- **Eventos:** `eclipse_100h`, `dust_panel`, `psr_ice_scan`.
- **Arte:** sombras largas, sol bajo, cielo negro, Tierra baja; el filtro nocturno actual se sustituye por “eclipse” (más oscuro y azul).
- **Datos:** `game/databases/sites/shackleton.tres`; fuentes en `game/databases/sources/`.

## 6. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| Un eclipse de 100 h es 1/3 de la misión de 12,5 días | Que sea el evento central de una partida, no de todas; el jugador puede elegir misión “eclipse” o “tormenta” |
| La batería de 7 kWh no da 5 kW durante 100 h | Modelar “carga esencial” y apagado; no prometer 5 kW plenos |
| El arte del polo sur requiere tiles nuevos | Reutilizar tiles lunares + paleta/iluminación; el cambio es de luz, no de geometría |
| El reactor de fisión es un tema político/educativo | Presentarlo como tecnología NASA; no hacerlo la única solución |
| El jugador no entiende “eclipse” | Tarjeta de datos + una frase: “La Tierra tapa el Sol; la sombra dura hasta 100 h” |

## 7. Criterios de aceptación

- [ ] La base se ambienta en Shackleton con una tarjeta de ubicación y enlace a Moon Trek.
- [ ] El panel solar produce según el ángulo del sol, no solo “día/noche”.
- [ ] Un eclipse de 100 h es visible, avisado y obliga a una decisión de apagado.
- [ ] La batería y la escalera de apagado evitan un *soft-lock*.
- [ ] El polvo se puede limpiar a mano (con coste) o con EDS (mejora).
- [ ] La tarjeta de datos explica la diferencia entre eclipses polares y el ciclo 12/12.
