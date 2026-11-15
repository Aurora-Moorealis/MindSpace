# Tasks

## 1. Atlas de techo

- [x] 1.1 Dibujar `art/tiles/base/roof_atlas.aseprite` con 4x5 losetas de 16x16
- [x] 1.2 Exportar `game/content/map/tiles/roof_atlas.png` a 2x (128x160)

## 2. Lámina de diseño

- [x] 2.1 Escribir `art/tiles/base/build-plan.lua` componiendo con el arte real
- [x] 2.2 Generar `base_plan.aseprite` con los tres frames de la base
- [x] 2.3 Exportar las tres capturas `_plan-*.png` a 850x480

## 3. Verificación

- [x] 3.1 Revisar la lámina a tamaño de juego y comprobar que la base cabe en la
      cámara de 850x480
- [x] 3.2 Comprobar que el atlas no colisiona con ningún `uid` del proyecto
- [x] 3.3 `openspec validate add-roof-atlas-art --strict`
