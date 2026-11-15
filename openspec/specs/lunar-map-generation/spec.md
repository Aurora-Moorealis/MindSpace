# lunar-map-generation Specification

## Purpose
Define el comportamiento observable del generador procedural de la superficie lunar: configuración de tamaño y seed, rasgos de terreno, transitabilidad conectada, spawn y puntos de interés, y la visualización de depuración sin assets.

## Requirements

### Requirement: Configuración de tamaño y seed

El generador SHALL aceptar una configuración con ancho y alto en tiles, tamaño de tile, seed y parámetros de rasgos. El ancho y el alto SHALL estar en el rango 16–256 tiles; el tamaño de tile SHALL estar en 8–64 px. Un valor fuera de rango SHALL ajustarse a un valor válido y registrarse como advertencia, sin abortar la generación. La configuración por defecto SHALL ser 64×64 tiles de 32 px (2048×2048 px).

#### Scenario: Tamaño por defecto

- **WHEN** se genera un mapa con la configuración por defecto
- **THEN** la rejilla mide 64×64 tiles, cada tile mide 32 px y el mapa ocupa 2048×2048 px

#### Scenario: Tamaño personalizado

- **WHEN** se configura un mapa de 120×80 tiles con tiles de 16 px
- **THEN** la rejilla mide 120×80 tiles, el tamaño de tile es 16 px y el tamaño en mundo es 1920×1280 px

#### Scenario: Valores fuera de rango

- **WHEN** se configura un ancho de 1 tile o un tamaño de tile de 0 px
- **THEN** el generador usa el mínimo válido, produce un mapa válido y añade una advertencia a la lista de warnings

### Requirement: Determinismo por seed

La misma configuración y la misma seed SHALL producir siempre el mismo mapa: mismos tipos de terreno, misma elevación, mismo spawn, mismos POIs y mismas advertencias. El generador no SHALL usar fuentes de aleatoriedad globales ni el reloj.

#### Scenario: Reproducibilidad

- **WHEN** se generan dos mapas con la misma configuración y seed
- **THEN** ambas rejillas de terreno, elevaciones, spawns y POIs son idénticos

#### Scenario: Seed distinta

- **WHEN** se generan dos mapas con la misma configuración pero seeds distintas
- **THEN** al menos una celda de terreno o una posición de POI difiere

### Requirement: Terreno lunar con rasgos

El generador SHALL producir una rejilla de ancho×alto con los tipos `MARE`, `HIGHLAND`, `CRATER_FLOOR`, `CRATER_RIM`, `EJECTA`, `RIDGE`, `ROCK` y `LANDING_PAD`. Los rasgos opcionales (cráteres, rocas, crestas y eyección) SHALL activarse o desactivarse mediante su densidad o multiplicador; la zona de aterrizaje SHALL tener radio configurable. La elevación SHALL ser finita y estar normalizada en `[0, 1]`.

#### Scenario: Cráteres

- **WHEN** la densidad de cráteres es mayor que cero y el mapa tiene tamaño suficiente
- **THEN** existen celdas de `CRATER_FLOOR`, `CRATER_RIM` y `EJECTA`

#### Scenario: Mares y tierras altas

- **WHEN** se genera un mapa con la configuración por defecto
- **THEN** existen celdas de `MARE` y de `HIGHLAND`

#### Scenario: Rocas y crestas

- **WHEN** las densidades de rocas y crestas son mayores que cero y el mapa tiene tamaño suficiente
- **THEN** existen celdas de `ROCK` y de `RIDGE`, y ambas son no transitables

#### Scenario: Rasgo desactivado

- **WHEN** la densidad de rocas se configura a cero
- **THEN** el mapa no contiene celdas de `ROCK`

### Requirement: Zona de aterrizaje y spawn

El generador SHALL crear una zona de aterrizaje circular plana de radio configurable, sin rocas ni crestas, y SHALL colocar el spawn dentro de ella. La zona SHALL estar completamente dentro de los límites del mapa; si el centro configurado no cabe, SHALL ajustarse. Todas las celdas de la zona SHALL ser transitables.

#### Scenario: Spawn en la zona

- **WHEN** se genera un mapa
- **THEN** el spawn está dentro de la zona de aterrizaje y es una celda transitable

#### Scenario: Zona sin obstáculos

- **WHEN** un cráter, una roca o una cresta intersecta la zona de aterrizaje
- **THEN** la zona se aplana y queda libre de obstáculos

#### Scenario: Centro fuera de límites

- **WHEN** el centro de la zona de aterrizaje está en el borde del mapa
- **THEN** el centro se ajusta para que la zona quede completa dentro del mapa

### Requirement: Transitabilidad y conectividad

La rejilla SHALL exponer para cada celda si es transitable. Las celdas `ROCK` y `RIDGE` SHALL ser no transitables; el resto SHALL ser transitable. Todas las celdas transitables SHALL pertenecer a una única componente conexa con vecindad de 4 direcciones. Si la generación produce componentes aisladas, el generador SHALL abrir pasillos transitables a través de los obstáculos hasta conectarlas.

#### Scenario: Componente única

- **WHEN** se genera un mapa
- **THEN** un recorrido en anchura desde el spawn alcanza todas las celdas transitables

#### Scenario: Pasillo a través de un obstáculo

- **WHEN** una cresta o un grupo de rocas divide el mapa en dos regiones transitables
- **THEN** el generador convierte las celdas necesarias en transitables para que ambas regiones queden conectadas

#### Scenario: Celda fuera de límites

- **WHEN** se consulta la transitabilidad de una celda fuera de la rejilla
- **THEN** la consulta devuelve `false` sin producir errores

### Requirement: Puntos de interés

El generador SHALL colocar `poi_count` puntos de interés (por defecto 3) en celdas transitables, distintas, dentro de límites, a una distancia mínima del spawn y con separación mínima entre ellas. Si no caben, SHALL relajar las restricciones, registrar una advertencia y colocar solo los POIs válidos. Nunca SHALL colocar un POI en una celda no transitable o fuera de límites. Todos los POIs SHALL ser alcanzables desde el spawn.

#### Scenario: Tres POIs por defecto

- **WHEN** se genera un mapa con la configuración por defecto
- **THEN** hay exactamente 3 POIs, todos transitables, alcanzables y separados entre sí

#### Scenario: Cantidad personalizada

- **WHEN** se configura `poi_count` a 5
- **THEN** el mapa intenta colocar 5 POIs y reporta cuántos colocó si no caben

#### Scenario: Mapa pequeño

- **WHEN** se genera un mapa de 16×16 tiles con 3 POIs y `poi_min_distance=13.0` (restricción imposible)
- **THEN** el generador coloca los POIs que caben con las restricciones relajadas y añade una advertencia

### Requirement: API de consulta y coordenadas

`LunarMap` SHALL exponer el ancho, alto, tamaño de tile, seed, terreno, elevación, transitabilidad, alcanzabilidad, spawn y POIs. SHALL exponer conversiones tile→mundo y mundo→tile coherentes con el tamaño de tile. Las consultas fuera de límites SHALL devolver un valor seguro.

#### Scenario: Conversión de coordenadas

- **WHEN** se convierte el tile (3, 4) a mundo con tiles de 32 px
- **THEN** el resultado es (96, 128) y la conversión inversa devuelve (3, 4)

#### Scenario: Consulta fuera de límites

- **WHEN** se consulta el terreno de un tile negativo o mayor que la rejilla
- **THEN** la consulta devuelve un valor inválido seguro sin fallar

### Requirement: Visualización de depuración sin assets

El cambio SHALL incluir una escena de depuración que dibuje el mapa con rectángulos de color plano mediante `_draw()`, sin PNG, TileSet ni sprites. La escena SHALL encuadrar el mapa completo con una cámara y SHALL marcar el spawn y los POIs. La escena SHALL cargar sin errores en modo headless.

#### Scenario: Carga de la escena

- **WHEN** se carga la escena de depuración en headless
- **THEN** la escena se instancia sin errores y contiene un `LunarMap` generado

#### Scenario: Sin assets

- **WHEN** se revisa la carpeta del módulo
- **THEN** no hay archivos de imagen ni TileSet; los colores se definen en el script de depuración

### Requirement: Aislamiento y verificación

El módulo SHALL ser independiente del núcleo de simulación: no SHALL modificar `GameSim`, `EventLog`, `project.godot`, autoloads, escenas existentes ni archivos de `add-sim-core`. El código SHALL pasar el checker GDScript en modo estricto y SHALL incluir un harness headless que verifique tamaño, determinismo, rasgos, conectividad, POIs y límites. El mapa máximo de 256×256 SHALL generarse sin errores.

#### Scenario: Sin cambios fuera del módulo

- **WHEN** se revisa el diff del cambio
- **THEN** solo aparecen archivos bajo `game/content/map/lunar/`, el harness y los artefactos de OpenSpec; `project.godot` y el código de simulación no cambian

#### Scenario: Checker estricto

- **WHEN** se ejecuta el checker GDScript en modo estricto
- **THEN** no hay errores ni warnings de tipado

#### Scenario: Mapa máximo

- **WHEN** se genera un mapa de 256×256 tiles
- **THEN** la generación termina sin errores y produce una rejilla completa y transitable conectada
