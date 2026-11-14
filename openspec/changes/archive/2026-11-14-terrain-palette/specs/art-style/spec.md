# Spec Delta

## MODIFIED Requirements

### Requirement: Paleta cerrada

Todo asset SHALL usar solo la paleta del juego: la paleta de identidad más la de
terreno. Identidad: cielo `#081542` `#0D1635` `#1F3152` `#14192B`; casco
`#DFE8F0` `#BCC9D6` `#92A1B2` `#7B8794` `#64707E` `#5F6B78`; metal `#A9B6C4`
`#6A7684`; teal `#57C8CC` `#4AA8B4` `#2F9FA6` `#2A7F8B` `#186269`; ámbar
`#FFE27A` `#F0A72A` `#9C5F0C`; navy `#3D5175` `#26334F` `#1B2540`; fuego
`#FFC93C` `#E2551B`; contorno `#0F171F`.

#### Scenario: Auditoría de colores

- **WHEN** se revisan los colores de un asset
- **THEN** todos pertenecen a la paleta y no hay tonos fuera de ella

#### Scenario: Hace falta un color nuevo

- **WHEN** un asset necesita un color que no está en la paleta
- **THEN** el color se añade a esta spec antes de usarse en cualquier asset

## ADDED Requirements

### Requirement: Paleta de terreno

Los assets de terreno SHALL usar, además de la rampa de casco, estas rampas:
regolito `#CFCCC7` `#AAA7A2` `#85827E` `#67645F`; basalto `#44444E` `#2E2E36`
`#1E1E25`; ilmenita `#55607A` `#343A4C` `#1F2331`; silíceo `#DDD5BE` `#B8AE92`
`#8C846C`; hielo `#C4D8DF` `#8FAAB4` `#5C7680`.

#### Scenario: Auditoría de un tile de terreno

- **WHEN** se audita una loseta de terreno
- **THEN** sus colores pertenecen a la rampa del material que representa

### Requirement: Rejilla de mundo

El mundo SHALL construirse con losetas de 32×32 píxeles de pantalla, dibujadas a
16×16 píxeles de arte y exportadas al doble.

#### Scenario: Colocación de losetas

- **WHEN** se colocan dos losetas de suelo iguales en celdas contiguas
- **THEN** no aparece costura visible entre ellas

#### Scenario: Tileset nuevo

- **WHEN** se añade un tileset al mundo
- **THEN** su rejilla es de 16 px de arte y su exportación es múltiplo entero de esa rejilla

### Requirement: Materiales del terreno

El terreno SHALL representar solo estos cuatro materiales lunares: hielo de agua
(H₂O), ilmenita (FeTiO₃), material silícico (SiO₂) y regolito basáltico. Cada uno
SHALL distinguirse del resto por color y textura, no solo por brillo.

#### Scenario: Lectura a tamaño de juego

- **WHEN** se mira el atlas de terreno a tamaño de juego
- **THEN** los cuatro materiales se distinguen entre sí sin ayuda de etiquetas

#### Scenario: Material nuevo

- **WHEN** se quiere añadir un material al terreno
- **THEN** se justifica que existe en la Luna y se documenta en este requisito antes de dibujarlo
