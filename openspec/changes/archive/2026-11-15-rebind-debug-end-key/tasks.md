# Tasks

## 1. Input map

- [x] 1.1 Sustituir el evento `F10` de `debug_end_run` por `keycode = 59` (`;`) con `physical_keycode = 0`

## 2. Verificación

- [x] 2.1 Comprobar en headless que la acción carga `keycode 59 (Semicolon)` y que `InputMap.event_is_action()` acepta `;` y rechaza `F10`
- [x] 2.2 Comprobar que `;` no coincide con ninguna otra acción del input map
- [x] 2.3 Arrancar el proyecto en headless sin errores de script
- [x] 2.4 Ejecutar `full_run_check`, `machines_api_check`, `clock_check`, `ledger_check` y `playable_flow_check` en el worktree y comparar con `features`
- [x] 2.5 Checker estricto de GDScript sin errores (`checked=69 parse_errors=0 style_issues=0`)
- [x] 2.6 `openspec validate rebind-debug-end-key --strict`
