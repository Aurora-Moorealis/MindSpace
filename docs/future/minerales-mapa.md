# Minerales y depósitos en el mapa

- **Estado:** pendiente
- **Prioridad:** media
- **Depende de:** `add-lunar-map-tile-render`, cambio de misión/POIs

## Objetivo

Colocar las calcas de mineral de `content/map/props/props_atlas.png` sobre el
mapa renderizado: ilmenita, material silícico, hielo de agua y basalto. Hoy la
fila de minerales del atlas no se usa; solo se pintan rocas y crestas.

## Alcance

- Definir una distribución determinista por seed y terreno, sin RNG global ni
  reloj: por ejemplo, hielo en fondos de cráter, ilmenita en mares y sílice en
  tierras altas.
- Usar las coordenadas `(1,1)`, `(2,1)`, `(3,1)` y `(4,1)` del atlas de props;
  no son props sólidos y no deben bloquear el paso.
- Decidir si los depósitos son solo decorativos o si se convierten en los POIs
  de la misión. Esa semántica pertenece al cambio de misión, no a este.
- Mantener la regla de `art-style`: el mineral es una calca sobre regolito, no
  una loseta de terreno de otro color.

## Criterios de aceptación

- Los depósitos aparecen de forma determinista y reproducible con la misma seed.
- Se distinguen a tamaño de juego y no forman un cuadrado de color.
- No alteran la transitabilidad ni la conectividad del mapa.
- El cambio se especifica con OpenSpec antes de implementarse y no modifica el
  generador salvo que la distribución necesite datos nuevos.

## Notas

La fila de minerales está documentada en `art/tiles/README.md` y el contrato
visual en `openspec/changes/add-lunar-map-tile-render/`. El usuario pidió
explícitamente no añadirlos todavía; esta nota es solo el recordatorio.
