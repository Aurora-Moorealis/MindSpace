# Spec Delta

## MODIFIED Requirements

### Requirement: Idioma de la documentación

La documentación SHALL seguir en español. El código SHALL estar en inglés:
comentarios, identificadores y mensajes de log.

#### Scenario: Documentación

- **WHEN** se lee un documento de `docs/` o `openspec/`
- **THEN** está en español

#### Scenario: Código

- **WHEN** se lee un script
- **THEN** sus comentarios, identificadores y mensajes de log están en inglés
