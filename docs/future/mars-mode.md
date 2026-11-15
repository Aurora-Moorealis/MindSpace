# Futuro: modo Marte

- **Estado:** Propuesta
- **Prioridad:** P2
- **Esfuerzo:** L/XL
- **Depende de:** `live-nasa-data.md`, `south-pole-power.md`, `food-production.md`
- **Documentos relacionados:** diseño v1 (`docs/designs/junior-astronauta-outpost-lunar.md`), datos NASA (`docs/research/nasa-space-apps-2026-junior-astronaut.md`)

## 1. Qué es

Una segunda campaña, después de la Luna: una base marciana con **sol** (24 h 39 min), **tormentas de polvo**, **retardo de comunicaciones de 3–22 min**, **ISRU de oxígeno** y una **dosis de radiación** que hace imposible ignorar el blindaje.

No es “la Luna con otro color”. Marte cambia las reglas:

- El día dura un **2,7 % más** que el terrestre; el reloj de la base ya no coincide con el de Mission Control.
- La luz solar es **~43 %** de la terrestre; los paneles necesitan más superficie o energía nuclear.
- El polvo puede cubrir el planeta durante **semanas o meses**; no es un evento de una hora.
- Cada orden tarda **minutos** en llegar; el jugador no puede reaccionar en tiempo real.
- La radiación de superficie es **0,64 mSv/día**; una misión larga supera el límite de carrera de 600 mSv.

## 2. Por qué

- El brief permite explícitamente “lunar or Martian outpost”.
- Marte es el escenario donde el **retardo de comunicaciones** que pide el brief se convierte en una mecánica real, no en un detalle.
- Da **rejugabilidad** con las mismas piezas: otro perfil de planeta, otras filas de eventos, otras máquinas.
- Es el mejor escenario para enseñar que **la radiación y la logística** son el verdadero cuello de botella de una misión larga.

## 3. Datos reales que lo anclan

| Magnitud | Valor | Fuente |
| --- | --- | --- |
| Duración del sol | **24 h 39 min 35 s** (1,027 días terrestres) | NASA Mars Facts / NSSDC |
| Gravedad | **3,71 m/s²** (0,38 g) | NASA Mars Fact Sheet |
| Atmósfera | **95,3 % CO₂**, presión <1 % de la terrestre | NASA Mars Facts |
| Temperatura | media **−53 °C**; rango **−128 °C a +27 °C** | JPL InSight press kit |
| Irradiancia solar | **586 W/m²** (~43 % de la terrestre) | NASA Mars Fact Sheet |
| Radiación de superficie | **0,21 mGy/día** absorbidos; **0,64 mSv/día** equivalentes | MSL/RAD, Gale |
| Radiación en crucero | **1,84 mSv/día** | MSL/RAD |
| Misión de referencia | 180 días ida + 500 en superficie + 180 vuelta ≈ **1,01 Sv** | MSL/RAD |
| Retardo de comunicaciones | **3–22 min** por sentido, según la distancia | Geometría orbital |
| Polvo | tormentas locales, regionales y globales; meses de sedimentación | NASA Mars Facts |
| ISRU de O₂ | MOXIE: **6–12 g/h**; sistema humano escalado: **2–3 kg/h** con ~25 kW | NASA/MIT |
| Agua | hielo en polos y latitudes medias; recurso ISRU | NASA Mars |

**Lectura para el juego:** una misión de 30 soles a 0,64 mSv/día son ~19 mSv; una de 500 días supera los 300 mSv solo por GCR, y con el crucero se va a ~1 Sv. La lección no es “Marte es radiactivo”, sino “**la duración de la misión es una decisión de dosis**”.

## 4. Cómo funcionaría

### 4.1 Perfil de planeta, no código nuevo

La idea es que `GameSim` lea un `PlanetProfile` (Resource) con:

- `sol_hours = 24.6597`
- `gravity_m_s2 = 3.71`
- `solar_irradiance_w_m2 = 586`
- `day_night_ratio`
- `radiation_mSv_per_day = 0.64`
- `comms_delay_min = [3, 22]`
- `dust_storm_probability`
- `atmosphere_co2_percent = 95.3`

La Luna y Marte comparten el mismo motor; solo cambian las filas.

### 4.2 Bucle de juego

- **Energía:** los paneles producen menos; el jugador elige entre más superficie solar, baterías o un reactor (FSP). Una tormenta de polvo global reduce la producción durante soles enteros.
- **Oxígeno:** el sistema de O₂ puede ser electrólisis (como en la Luna) o **MOXIE** (CO₂ → O₂). MOXIE consume mucha energía; el jugador decide cuándo encenderlo.
- **Agua:** el reciclador es más crítico; el hielo es un POI de largo plazo (ISRU).
- **Comida:** los cultivos tardan semanas; la comida empaquetada es la base. El invernadero da frescura/vitaminas.
- **Radiación:** 0,64 mSv/día; el refugio de regolito reduce la dosis; las tormentas solares pueden añadir 50–250 mSv. La barra de 250 mSv (SPE) y el límite de carrera de 600 mSv conviven.
- **Comunicaciones:** las órdenes se encolan; el jugador ve “Order sent — arrives in 12 min”. No hay control en tiempo real. Los informes se envían por lotes.

### 4.3 Eventos

- **Tormenta de polvo global:** reduce la energía solar un 60–90 % durante N soles; limpiar los paneles no basta; el reactor o las baterías salvan la misión.
- **Tormenta solar:** como en la Luna, pero el retardo hace que el aviso llegue tarde; el refugio debe estar preparado.
- **Fallo de MOXIE:** el O₂ depende de una máquina; repararla cuesta tiempo y energía.
- **Ventana de comunicaciones:** un pase de relay; si se pierde, los informes esperan horas.

## 5. Diseño técnico

- **Reutilizar:** `GameSim`, `GameState`, `EventLog`, `AudioManager`; los 4 autoloads no cambian.
- **Nuevo:** `PlanetProfile` (Resource), filas de `events.tres` para Marte, 2–3 máquinas nuevas (`moxie`, `dust_filter`, `reactor`), un `CommsQueue` dentro de la consola.
- **Datos:** `game/databases/planets/mars.tres` y `game/databases/events_mars.tres`; las fuentes en `game/databases/sources/`.
- **UI:** el HUD muestra “SOL 003 · 14:32” y “Light delay: 12 min”; el jugador no puede abusar del tiempo real.
- **Arte:** tileset marciano (polvo, óxido, cielo butano); reutiliza las reglas de `docs/art-direction.md`.

## 6. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| El retardo de 3–22 min puede ser frustrante para 7–12 | Que afecte a **órdenes**, no a la acción local; el jugador siempre puede moverse/reparar |
| Una misión de 500 días es inviable con 600 mSv | Diseñar una **expedición de 30–60 soles**, no una colonia permanente; o un modo “carrera” con waiver |
| El polvo global es un evento de semanas | En el juego, comprimir a 2–3 soles; mostrar la fuente y la compresión |
| MOXIE a escala humana requiere ~25 kW | Que sea una mejora tardía, no la base del early game |
| Demasiadas máquinas nuevas | Máximo 3; reutilizar el resto del catálogo lunar |

## 7. Criterios de aceptación

- [ ] Un `PlanetProfile` de Marte cambia día, gravedad, solar y radiación sin tocar `GameSim`.
- [ ] Una tormenta de polvo de 2–3 soles reduce la energía y obliga a una decisión.
- [ ] MOXIE produce O₂ y consume energía de forma visible.
- [ ] Una orden tarda un tiempo de retardo visible y se puede cancelar antes de llegar.
- [ ] La barra de radiación muestra 0,64 mSv/día y el límite de 250/600 mSv.
- [ ] Una tarjeta de datos explica por qué una misión larga a Marte supera el límite de carrera.
