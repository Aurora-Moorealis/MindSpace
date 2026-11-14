# Tasks

## 1. Spec de arte

- [x] 1.1 Crear `openspec/changes/art-guidelines/specs/art-style/spec.md` con la rejilla, la paleta cerrada y las reglas de dibujo como requisitos normativos
- [x] 1.2 Añadir los escenarios de auditoría (colores, alfa, contorno, piezas) con WHEN/THEN
- [x] 1.3 Documentar en `design.md` por qué las reglas van a la spec y el procedimiento al manual

## 2. Manual

- [x] 2.1 Quitar de `docs/guia-estetica.md` las secciones normativas (rejilla, paleta, siete reglas) y enlazar a la spec
- [x] 2.2 Conservar los procesos, las herramientas, los comandos de comprobación y la tabla de errores
- [x] 2.3 Añadir la tabla nueva de errores: el bloque de UI que corta un elemento del fondo

## 3. Coherencia

- [x] 3.1 Actualizar el `context` de `openspec/config.yaml` para que apunte a la spec y no a la guía
- [x] 3.2 Revisar que `docs/future/` no quede con referencias a secciones movidas

## 4. Verificación

- [x] 4.1 Ejecutar `openspec validate "art-guidelines" --strict` sin avisos
- [x] 4.2 Archivar el cambio y comprobar que `openspec/specs/art-style/spec.md` existe
- [x] 4.3 Comprobar que la guía no repite los hex de la paleta
