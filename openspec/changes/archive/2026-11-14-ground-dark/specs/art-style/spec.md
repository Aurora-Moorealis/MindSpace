# Spec Delta

## MODIFIED Requirements

### Requirement: Paleta de terreno

Los assets de terreno SHALL usar, además de la rampa de casco, estas rampas:
regolito `#8B8884` `#726F6B` `#585551` `#403E3B`; basalto `#44444E` `#2E2E36`
`#1E1E25`; ilmenita `#55607A` `#343A4C` `#1F2331`; silíceo `#DDD5BE` `#B8AE92`
`#8C846C`; hielo `#C4D8DF` `#8FAAB4` `#5C7680`.

#### Scenario: Auditoría de un tile de terreno

- **WHEN** se audita una loseta de terreno
- **THEN** sus colores pertenecen a la rampa del material que representa

### Requirement: Materiales del terreno

El terreno SHALL ser un único suelo de regolito basáltico. Los otros tres
materiales lunares —hielo de agua (H₂O), ilmenita (FeTiO₃) y material silícico
(SiO₂)— SHALL aparecer como depósitos sueltos sobre ese suelo, nunca como
losetas de terreno.

#### Scenario: Lectura del suelo

- **WHEN** se recorre una zona de exterior
- **THEN** el suelo es siempre el mismo regolito, sin bloques de otro color

#### Scenario: Lectura de un depósito

- **WHEN** se coloca un depósito de mineral sobre el regolito
- **THEN** se distingue del suelo por color y textura, y su borde se funde sin formar un cuadrado

#### Scenario: Lectura a tamaño de juego

- **WHEN** se mira el terreno a tamaño de juego
- **THEN** cada depósito se distingue del regolito y de los demás sin ayuda de etiquetas

#### Scenario: Material nuevo

- **WHEN** se quiere añadir un material al terreno
- **THEN** se justifica que existe en la Luna y se documenta en este requisito antes de dibujarlo
