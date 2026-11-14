# Tasks

## 1. OpenSpec

- [x] 1.1 Crear el cambio `harden-worlds-and-intro-defaults` con proposal, delta specs de `worlds` e `intro`, design y tasks.
- [x] 1.2 Ejecutar `openspec validate harden-worlds-and-intro-defaults --strict` y dejarlo en verde.

## 2. Mundos

- [x] 2.1 Hacer que `WorldStore.create_world()` valide el nombre con `validate_name()` y devuelva `null` si no cumple.
- [x] 2.2 Añadir `_cancel_form()` y hacer que ESC cierre el formulario y vuelva a la lista cuando hay mundos; en el resto de casos, volver al menú.
- [x] 2.3 Comprobar en local que crear con nombre vacío, largo o repetido devuelve `null` y no escribe, y que ESC en el formulario vuelve a la lista sin cambiar de escena.

## 3. Intro

- [x] 3.1 Cambiar el nombre de reserva de `"astronauta"` a `"astronaut"`.
- [x] 3.2 Comprobar en local que la intro sin mundo seleccionado muestra `"astronaut"`.

## 4. Verificación

- [x] 4.1 `check-gdscript.sh -p game --strict` sin errores ni avisos.
- [x] 4.2 `godot --headless --path game --quit` sin `ERROR` ni `SCRIPT ERROR`.
- [x] 4.3 `sim_smoke` sigue en verde.
- [x] 4.4 Instanciar en headless `welcome`, `worlds` e `intro` sin errores.

## 5. Cierre

- [x] 5.1 Archivar el cambio y validar `--all --strict`.
- [x] 5.2 Commit, push y PR a `features` con la verificación adjunta.
