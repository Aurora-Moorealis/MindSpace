# Tasks

## 1. Menú

- [x] 1.1 Traducir los botones y el subtítulo en `game/scenes/welcome/welcome.tscn`
- [x] 1.2 Traducir los avisos de error de `welcome.gd`

## 2. Mundos

- [x] 2.1 Traducir títulos, botones y marcador en `game/scenes/worlds/worlds.tscn`
- [x] 2.2 Traducir los avisos y el estado de confirmación en `worlds.gd`
- [x] 2.3 Traducir los mensajes de validación en `world_store.gd`

## 3. Introducción

- [x] 3.1 Traducir los botones de `intro.tscn`
- [x] 3.2 Traducir las siete partes de la historia y la confirmación en `intro.gd`
- [x] 3.3 Cambiar el marcador `{nombre}` por `{name}`

## 4. Specs

- [x] 4.1 Quitar las etiquetas literales de los requisitos de `menu`, `worlds` e `intro`
- [x] 4.2 Añadir la capability `ui-language` con el idioma de la interfaz y el de la documentación
- [x] 4.3 Validar el cambio con `--strict` y archivarlo

## 5. Verificación

- [x] 5.1 `check-gdscript.sh -p game --strict` sin errores ni avisos
- [x] 5.2 Arranque headless sin `ERROR` ni `SCRIPT ERROR`
- [x] 5.3 Recorrer menú, mundos e intro y comprobar que no queda texto en español
