# Spec Delta

## MODIFIED Requirements

### Requirement: Paleta de terreno

Los assets de terreno SHALL usar, además de la rampa de casco, estas rampas:
regolito `#C6C4C6` `#A9A7AB` `#8A888E` `#6B6970`; basalto `#44444E` `#2E2E36`
`#1E1E25`; ilmenita `#55607A` `#343A4C` `#1F2331`; silíceo `#DDD5BE` `#B8AE92`
`#8C846C`; hielo `#C4D8DF` `#8FAAB4` `#5C7680`.

#### Scenario: Auditoría de un tile de terreno

- **WHEN** se audita una loseta de terreno
- **THEN** sus colores pertenecen a la rampa del material que representa
