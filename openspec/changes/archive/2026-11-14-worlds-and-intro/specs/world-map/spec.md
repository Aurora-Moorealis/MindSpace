# Spec Delta

## Purpose

Construcción del mundo con losetas: qué declara cada loseta y cómo se orientan
los muros para que el mapa se lea continuo.

## ADDED Requirements

### Requirement: Tres TileSets

El mundo SHALL construirse con tres TileSets separados —suelo, base y props— y
todas sus losetas SHALL medir 32×32 píxeles de pantalla.

#### Scenario: Pintar una celda

- **WHEN** se pinta una celda del mapa
- **THEN** se usa el TileSet de la capa correspondiente y la loseta ocupa 32×32 píxeles

### Requirement: Datos por loseta

Cada loseta SHALL declarar su material, su variante y si bloquea el paso, de modo
que el código consulte la loseta en lugar de recordar coordenadas del atlas.

#### Scenario: Consultar una loseta

- **WHEN** el código pregunta por una loseta pintada
- **THEN** obtiene material, variante y si bloquea el paso

### Requirement: Orientaciones del muro

La loseta de muro SHALL ofrecer cuatro orientaciones —recta, girada 90 grados,
girada 270 grados e invertida— para poder formar anillos de muro continuos.

#### Scenario: Muro vertical

- **WHEN** se pinta un tramo de muro vertical
- **THEN** se usa una orientación girada y el canto del muro queda continuo, sin rayas por loseta
