# Variantes del rack hidropónico

Cada versión está guardada en **su propio archivo** (`.aseprite` editable + PNG
a 1×). La versión activa del juego sigue siendo `../sprites/hydroponics_rack.png`
(copia de `rack_v7_current`).

| Archivo | Qué propone |
| --- | --- |
| `rack_v1_shelf.aseprite` / `.png` | Estantería metálica abierta de 3 pisos con bandeja y plantas pequeñas. La primera entrega del pack. |
| `rack_v1_shelf_empty.aseprite` / `.png` | Derivada de la v1: sin plantas y con divisorias de 3×3 celdas. Es la vitrina base del ejemplo de crecimiento por semilla (`../../../../map/greenhouse/art/growth/`). |
| `rack_v2_curtain.aseprite` / `.png` | Primera cámara cilíndrica de vidrio, con plantas en cortina continua y costillas finas. |
| `rack_v3_clumps.aseprite` / `.png` | Cámara con masas de vegetación orgánicas (grupos irregulares, sin pisos marcados). |
| `rack_v4_tiers.aseprite` / `.png` | Cámara con tres pisos y plantas escasas, casquete metálico cerrado. |
| `rack_v4_tiers_empty.aseprite` / `.png` | La v4 sin plantas y con los pisos visibles; base del ejemplo de 12 celdas. |
| `rack_v4_back.aseprite` / `.png` | **Capa trasera de la v4**: estructura, interior, pisos, casquetes, rail y plinto. Sin vidrio frontal. |
| `rack_v4_cover.aseprite` / `.png` | **Capa frontal de la v4**: tapas de vidrio con costillas, tinte translúcido y reflejos. Va sobre las plantas. |
| `rack_v5_glass.aseprite` / `.png` | Pisos más llenos, vidrio más claro, casquete con ventana y luces de crecimiento. |
| `rack_v6_dense.aseprite` / `.png` | Vegetación densa tipo seto, tres pisos muy cubiertos. |
| `rack_v7_current.aseprite` / `.png` | **Versión actual**: tres pisos despejados, plantas individuales con tallo y hojas, casquete de vidrio y luces tenues. |

`variants_sheet_x3.png` es una hoja de contactos a 3× con las siete versiones en
orden (fila superior: v1–v4; fila inferior: v5–v7).

Todas mantienen 96×64 px, ancla bottom-center `[48, 64]` y la paleta del
invernadero, así que se pueden intercambiar sin tocar `sprites.json` ni la
escena. Para activar otra versión, copia su PNG sobre
`../sprites/hydroponics_rack.png` (y su `.aseprite` sobre
`../hydroponics_rack.aseprite`) o referencia el PNG de `variants/` directamente
desde la escena.
