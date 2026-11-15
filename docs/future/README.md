# Tareas futuras

Ideas y trabajos pendientes que **todavía no se han empezado**. Cada archivo es
una tarea o un dossier autocontenido: qué hay que hacer, de qué depende y cómo
saber que está terminado.

## Reglas de esta carpeta

- **Una tarea o dossier por archivo**, nombre en `kebab-case` descriptivo.
- Todo archivo lleva la misma cabecera: `Estado`, `Prioridad`, `Depende de`.
- Si una tarea o feature se convierte en trabajo real, se especifica con OpenSpec
  (`openspec/changes/<change>/`) o se diseña con EGM (`docs/designs/<feature>.md`)
  y **se actualiza o archiva aquí**. Esta carpeta no es un backlog eterno: es una
  lista de recordatorios viva.
- No dupliques contenido de `docs/designs/`: si algo ya está en el diseño formal,
  enlázalo en lugar de copiarlo.

## Índice

| Tarea | Prioridad | Depende de |
| --- | --- | --- |
| [animacion-aterrizaje](animacion-aterrizaje.md) | Media | Cohetes finales |
| [sombra-cohetes](sombra-cohetes.md) | Baja | — |
| [morro-cohete](morro-cohete.md) | Baja | — |
| [pantalla-configuracion](pantalla-configuracion.md) | Media | Menú |
| [selector-mision](selector-mision.md) | Media | Menú, `submissions.tres` |
| [intro-stills](intro-stills.md) | Media | Menú |
| [crateres-visibles](crateres-visibles.md) | Media | `add-lunar-map-tile-render`, arte de cráteres |
| [minerales-mapa](minerales-mapa.md) | Media | `add-lunar-map-tile-render`, misión/POIs |
| [report-victory](report-victory.md) | Alta | consola de comunicaciones, POIs, escaneo |

## Investigación y features grandes

Estos documentos son **dossiers de investigación y features completas**, no
tareas atómicas. Usan una escala propia (`P1`/`P2`/`P3`) y un formato de 7
secciones. La base de investigación está en [`research.md`](research.md); el
informe completo y el JSON están en `docs/research/`.

| Documento | Feature | Prioridad | Esfuerzo |
| --- | --- | --- | --- |
| [research.md](research.md) | Investigación, reglas y datos NASA | P1 | — |
| [mars-mode.md](mars-mode.md) | Base marciana: sol, polvo, retardo, ISRU | P2 | L/XL |
| [live-nasa-data.md](live-nasa-data.md) | DONKI/OSDR/RadLab con caché y fallback | P1 | M |
| [south-pole-power.md](south-pole-power.md) | Shackleton, eclipse de 100 h, VSAT/FSP, polvo | P1 | M |
| [replayability.md](replayability.md) | Semilla de misión, barajas de eventos, 3 tormentas | P1 | S/M |
| [astronaut-health.md](astronaut-health.md) | Hueso/músculo/sueño; ejercicio como contramedida | P2 | M |
| [food-production.md](food-production.md) | Invernadero como vitaminas/frescura, no calorías | P2 | M |
| [moon-trek-map.md](moon-trek-map.md) | Teselas reales de la Luna para mapa/intro | P2 | S |
| [multiplayer-crew.md](multiplayer-crew.md) | 2–4 astronautas, roles, co-op local | P3 | XL |
| [accessibility-education.md](accessibility-education.md) | Lenguaje claro, daltonismo, aula, localización | P1 | S/M |
| [art-and-audio.md](art-and-audio.md) | Animaciones que faltan, SFX, ambiente, Aurora | P1 | M |

Cuando una feature se implemente, se crea un cambio de OpenSpec y el dossier se
actualiza o se archiva; no se copia el contenido.
