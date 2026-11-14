# Spec Delta

## Purpose

Idioma del texto visible: qué se escribe en inglés para el jugador y qué se
mantiene en español fuera de la interfaz.

## ADDED Requirements

### Requirement: Idioma de la interfaz

Todo texto visible para el jugador SHALL estar en inglés: títulos, botones,
marcadores de campo, mensajes de validación, avisos temporales y el texto de la
historia.

#### Scenario: Revisión de una pantalla

- **WHEN** se revisa cualquier pantalla del juego
- **THEN** todo el texto visible está en inglés y no queda ninguna cadena en otro idioma

#### Scenario: Mensaje de error

- **WHEN** el jugador provoca un error de validación
- **THEN** el mensaje que aparece está en inglés

### Requirement: Idioma de la documentación

La documentación, los comentarios del código y los nombres de archivo SHALL
seguir en español; solo el texto que ve el jugador pasa a inglés.

#### Scenario: Documentación

- **WHEN** se lee un documento de `docs/` o `openspec/`
- **THEN** está en español

#### Scenario: Código

- **WHEN** se lee un script
- **THEN** sus comentarios están en español y los identificadores en inglés
