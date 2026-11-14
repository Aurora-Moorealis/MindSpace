# Spec Delta

## Purpose

Representar una superficie lunar generada sobre el mundo de losetas: cobertura
completa del terreno, correspondencia entre tipo de terreno y loseta, plataforma
de aterrizaje, props sólidos de rocas y crestas, y una escena de mapa real
construida con los TileSets existentes.

## ADDED Requirements

### Requirement: Cobertura completa de la rejilla

La representación SHALL pintar una loseta de suelo por cada celda de la rejilla
generada, sin huecos ni celdas fuera de los límites. El número de celdas pintadas
SHALL ser igual a ancho × alto y SHALL corresponder a las mismas coordenadas que
la rejilla de terreno.

#### Scenario: Mapa por defecto

- **WHEN** se representa un mapa de 64×64 celdas
- **THEN** la capa de suelo contiene 4096 celdas, todas dentro de los límites y sin huecos

#### Scenario: Mapa de tamaño distinto

- **WHEN** se representa un mapa de 120×80 celdas
- **THEN** la capa de suelo contiene 9600 celdas y ninguna queda fuera de la rejilla

### Requirement: Correspondencia entre terreno y loseta

Cada tipo de terreno SHALL tener una representación visual definida. Las celdas
`MARE`, `HIGHLAND`, `CRATER_FLOOR`, `CRATER_RIM` y `EJECTA` SHALL pintarse con
losetas de regolito; su diferencia SHALL expresarse con la variante de detalle,
no con un suelo de otro material. Un tipo de terreno desconocido no SHALL
producir una loseta inválida ni abortar la representación.

#### Scenario: Terreno conocido

- **WHEN** se representa una celda de cada tipo de terreno del generador
- **THEN** cada una recibe una loseta válida del TileSet de suelo o de la plataforma

#### Scenario: Terreno desconocido

- **WHEN** la rejilla contiene un valor de terreno fuera del enum conocido
- **THEN** la celda se pinta con una variante segura de regolito y no se produce un error

### Requirement: Variación determinista e idempotente

La variante visual de cada celda SHALL depender solo de la seed del mapa y de sus
coordenadas. Dos representaciones de la misma `LunarMap` SHALL producir
exactamente las mismas celdas, y volver a representar un mapa SHALL limpiar la
representación anterior antes de pintar.

#### Scenario: Misma seed

- **WHEN** se representa dos veces la misma rejilla con la misma seed
- **THEN** ambas representaciones contienen las mismas losetas en las mismas coordenadas

#### Scenario: Repintado

- **WHEN** se representa un mapa nuevo sobre una capa que ya contenía celdas
- **THEN** no quedan celdas del mapa anterior fuera de los límites del nuevo mapa

### Requirement: Plataforma de aterrizaje

Las celdas `LANDING_PAD` SHALL pintarse como una plataforma metálica construida,
completamente cubierta y sin props sólidos dentro de ella. La celda de spawn
SHALL quedar sobre una loseta de plataforma.

#### Scenario: Zona de aterrizaje

- **WHEN** se representa un mapa generado
- **THEN** todas las celdas de la zona de aterrizaje son de plataforma y la celda de spawn es una de ellas

#### Scenario: Borde de la plataforma

- **WHEN** la zona de aterrizaje limita con regolito
- **THEN** el borde se distingue del regolito con una variante propia de la plataforma y no aparecen rocas dentro de ella

### Requirement: Props de rocas y crestas

Las celdas no transitables `ROCK` y `RIDGE` SHALL recibir un prop de roca sólido
del TileSet de props. Ninguna celda transitable SHALL recibir un prop sólido. Las
rocas y las crestas SHALL distinguirse entre sí por la variante elegida. En esta
capability no SHALL colocarse ninguna calca de mineral.

#### Scenario: Obstáculos

- **WHEN** se representa un mapa con celdas `ROCK` y `RIDGE`
- **THEN** cada una recibe un prop sólido y ninguna celda transitable recibe uno

#### Scenario: Sin minerales

- **WHEN** se revisa la capa de props terminada
- **THEN** no contiene ninguna loseta del atlas de minerales

### Requirement: Escena de mapa real

El cambio SHALL incluir una escena de mapa real con tres capas de losetas
—suelo, base y props— que usen los TileSets existentes, genere el mapa desde una
configuración exportada y centre la cámara en el spawn a escala de juego, sin
reducir el arte a un zoom no entero. La escena SHALL cargar sin errores en modo
headless.

#### Scenario: Carga de la escena

- **WHEN** se carga la escena de mapa real en headless
- **THEN** la escena se instancia sin errores y contiene las tres capas con sus TileSets

#### Scenario: Encuadre en el spawn

- **WHEN** la escena termina de generar el mapa
- **THEN** la cámara está centrada en la celda de spawn y mantiene la escala 1:1 del mundo

### Requirement: Aislamiento y verificación

La representación SHALL consumir el generador sin modificarlo y no SHALL tocar
`project.godot`, autoloads, escenas compartidas ni el arte existente. El código
SHALL pasar el checker GDScript en modo estricto y SHALL incluir un harness
headless que verifique cobertura, mapeo, plataforma, props, determinismo y carga
de la escena.

#### Scenario: Sin cambios en el generador

- **WHEN** se revisa el diff del cambio
- **THEN** solo aparecen archivos nuevos bajo `game/content/map/lunar/` y los artefactos de OpenSpec

#### Scenario: Checker estricto

- **WHEN** se ejecuta el checker GDScript en modo estricto
- **THEN** no hay errores ni warnings de tipado

#### Scenario: Arranque headless

- **WHEN** se arranca el proyecto en headless
- **THEN** el proyecto carga sin errores de recursos ni de autoloads
