# Design

## Contexto

- `hydroponics_station.tscn` declara `extra_panel_scene`; `MachinePanel` lo
  instancia como hijo **full-rect** de su propio `Control` (que ya ocupa
  850×480), oculta su marco y conecta la señal `closed` si existe.
- `growth_interface.tscn` es una escena `Node2D` dibujada a coordenadas
  absolutas de 850×480, con estado propio (`HydroponicsState.new(DEMO_RUN_SEED)`),
  acumulador de ticks propio y un botón que salta a `growth_demo.tscn`.
- `HydroponicsStation` ya expone `cultivation`, `plant_cell()`, `harvest_cell()`,
  `remove_cell()` y `can_cultivate()`, que es justo lo que la interfaz necesita.

## Decisiones

### 1. Modo enganchado, no una copia

`growth_interface.gd` gana `bind_station(station)`:

- guarda la estación y usa `station.cultivation` como estado;
- deja de alimentar ticks (`_process` no acumula cuando hay estación enganchada:
  los ticks los pone `GameSim` y la estación los reenvía);
- plantar/cosechar/retirar pasan por `plant_cell`, `harvest_cell` y `remove_cell`,
  así que respetan potencia, salud y capacidad de comida;
- el botón de demo se oculta y el de volver emite `closed`.

Sin enganchar, la escena se comporta exactamente como la demo de siempre. Es una
rama, no una segunda implementación.

### 2. Envoltorio `Control`

`MachinePanel` exige que la escena extra tenga raíz `Control`. La interfaz es
`Node2D`, así que se añade una escena envoltorio mínima
(`panel/growth_panel.tscn` + `growth_panel.gd`) que:

- es `Control` full-rect con `mouse_filter = ignore` (los clics los resuelve la
  interfaz por `_unhandled_input`, igual que en la demo);
- instancia la interfaz, la engancha a la estación con `setup(station)` (el
  `MachinePanel` llama `setup` si existe) y reemite `closed`;
- cierra con `ui_cancel` para que el jugador no dependa solo del botón.

### 3. Textos en inglés

La interfaz pasa a `SOWN`, `MATURE`, `HARVESTED`, `Harvest`, `Remove`, `Back` y
los mensajes de estado. La demo también, porque comparte escena y la regla de UI
del repo no admite español hardcodeado.

### 4. Se retira la rejilla antigua

`panel/hydroponics_panel.tscn` y su script quedan sin consumidor. Mantener dos
interfaces de cultivo duplica mantenimiento y vuelve a abrir la duda de cuál es
la buena, el mismo problema que ya se resolvió con el HUD numérico.

## Alternativas descartadas

- **Duplicar la interfaz en una escena nueva para gameplay**: 334 líneas
  duplicadas y dos sitios donde corregir el mismo bug.
- **Abrir la demo como escena suelta (`change_scene_to_file`)**: pierde el run,
  el HUD y el estado de la estación.
- **Dejar la rejilla y añadir la interfaz al lado**: dos UIs y dos specs.

## Riesgos

- La interfaz mide 850×480 en coordenadas absolutas; si algún día cambia el
  lienzo, hay que revisarla. Mitigación: el envoltorio mantiene el full-rect y la
  verificación se hace a 850×480 y 1280×720.
- Al reutilizar `_unhandled_input` para los clics, si otro control captura el
  ratón la interfaz no recibe el evento. Mitigación: `mouse_filter = ignore` en
  el envoltorio y en el `Dim` del panel.
