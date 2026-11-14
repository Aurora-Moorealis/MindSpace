# Spec Delta

## MODIFIED Requirements

### Requirement: Persistencia de mundos

Los mundos SHALL guardarse en el almacenamiento del usuario y SHALL leerse al
abrir la pantalla de selección, de modo que sobrevivan entre sesiones. Cada
guardado SHALL ser atómico: si la escritura se interrumpe a mitad, el archivo
anterior SHALL quedar intacto y legible. Si el archivo existente no se puede
interpretar, SHALL conservarse como copia de seguridad y la pantalla SHALL
avisar del problema en lugar de tratarlo como una lista vacía.

#### Scenario: Primera vez sin mundos

- **WHEN** se abre la pantalla y no hay ningún mundo guardado
- **THEN** no se muestra lista y se pide directamente un nombre

#### Scenario: Con mundos guardados

- **WHEN** se abre la pantalla y hay mundos guardados
- **THEN** se listan todos, cada uno con su nombre visible

#### Scenario: Escritura interrumpida

- **WHEN** la escritura de un mundo se interrumpe antes de terminar
- **THEN** el archivo anterior sigue siendo legible y conserva sus mundos

#### Scenario: Archivo dañado

- **WHEN** el archivo de mundos existe pero no se puede interpretar
- **THEN** se conserva como copia de seguridad, la pantalla avisa y no se
  sobrescribe con una lista vacía
