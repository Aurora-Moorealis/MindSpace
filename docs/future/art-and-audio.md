# Futuro: arte y audio

- **Estado:** En curso (arte v1) / Propuesta (audio futuro)
- **Prioridad:** P1
- **Esfuerzo:** M
- **Depende de:** `docs/art-direction.md`, pipeline de Aseprite
- **Documentos relacionados:** `docs/art-direction.md`

## 1. Qué es

El arte que falta para cerrar la v1 y el que haría falta para las features futuras. No es una dirección de arte nueva: es la lista de trabajo sobre la identidad ya definida (pixel-art 850×480, 32 px, paleta de 17 colores, Press Start 2P).

## 2. Arte v1 pendiente

Del documento de dirección de arte:

| Asset | Estado | Nota |
| --- | --- | --- |
| Idle 4 direcciones | Entregado | 4 frames × 4 direcciones |
| Walk 4 direcciones | **Pendiente** | Reutilizar máster; no redibujar el casco |
| Interact / scan | **Pendiente** | Barra in-world + pose de escaneo |
| Hurt | **Pendiente** | 1–2 frames; feedback claro |
| Death | **Pendiente** | 2–3 frames; no gore |
| Tileset interior (5 salas) | **Pendiente** | 32 px; floor/wall/door/airlock/window |
| Props | **Pendiente** | Consolas 2×1, cajas 1×1, plantas 1×1 |
| Exterior lunar | **Pendiente** | Panel solar + 3 POIs; ≤2 pantallas |
| Aurora (retrato) | Futuro | PNG sobre el marco de diálogo |

## 3. Arte futuro (features)

| Feature | Asset | Doc |
| --- | --- | --- |
| Polo sur | Luz rasante, sombras largas, eclipse | `south-pole-power.md` |
| Marte | Tileset óxido, cielo butano, polvo | `mars-mode.md` |
| Polvo/EDS | Capa de regolito, chispas EDS | `south-pole-power.md` |
| Moon Trek | Imagen real del polo sur | `moon-trek-map.md` |
| Invernadero | Etapas de cultivo (seed → microgreens) | `food-production.md` |
| Salud | Estación de ejercicio, sudor, fatiga | `astronaut-health.md` |
| Tripulación | 2–4 variantes de traje/rol | `multiplayer-crew.md` |

## 4. Audio

### v1

- **5 SFX**: UI, reparación, informe, alarma de radiación, evento.
- Sin música propia; volumen uniforme; nada de loops a volumen salvaje.
- Los SFX importantes deben tener **subtítulo** o icono (accesibilidad).

### Futuro

- **Ambiente:** zumbido de la base, ventilación, pasos en regolito, viento (no hay viento en la Luna: no usarlo).
- **Música:** 2–3 loops cortos, opcionales, con mute.
- **Voz:** no; texto + subtítulos.
- **Mezcla:** ducking de música durante alertas; -6 dB de headroom.

## 5. Pipeline y QA

1. Dibujar en Aseprite a 1× en la rejilla de 64×64 (personaje) o 32×32 (tiles).
2. Exportar PNG con alpha real; comprobar anchor y bounds.
3. Importar en Godot con nearest, sin mipmaps.
4. Revisar a tamaño real en 850×480, no solo con zoom.
5. Checklist: silueta legible a 1×, outline cerrado, sin píxeles sueltos, paleta consistente, pies en la misma línea, sin jitter.
6. Para SFX: normalizar a -16 LUFS aprox.; comprobar en altavoz pequeño.

## 6. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| El arte pendiente bloquea el build | Placeholders con la paleta; sustituir después |
| El pixel-art se vuelve ilegible al escalar | Escalado entero; probar 1080p |
| Marte/polo sur requieren demasiado arte | Reutilizar tiles y cambiar paleta/luz |
| El audio tapa los diálogos | Ducking + mute + subtítulos |
| Aurora se convierte en una escena animada | Solo retrato + diálogo, como está diseñado |

## 7. Criterios de aceptación

- [ ] Walk, interact, hurt y death existen y se ven a 1×.
- [ ] Las 5 salas y el exterior tienen tileset y props.
- [ ] Los 5 SFX están mezclados y se pueden silenciar.
- [ ] Cada asset nuevo respeta la paleta de 17 colores.
- [ ] Los SFX críticos tienen subtítulo/icono.
