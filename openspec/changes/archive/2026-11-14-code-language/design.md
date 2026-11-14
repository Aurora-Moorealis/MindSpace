# Design

## Context

`AGENTS.md` (commit 51314ff, por DevGreem) exige inglés en código y comentarios, y
deja la documentación en el idioma del usuario. La capability `ui-language` nació
antes de esa regla y repartía los idiomas al revés.

## Goals / Non-Goals

**Goals:**

- Que la spec y `AGENTS.md` digan lo mismo.
- Que el código de este trabajo cumpla la regla.

**Non-Goals:**

- Revisar el código de otros módulos.
- Introducir un sistema de traducciones para la interfaz.

## Decisions

### 1. Corregir la spec, no la regla del repositorio

La regla nueva la escribió otro miembro del equipo y es más estricta (incluye
comentarios). Mi spec era la desactualizada, así que se ajusta ella.

### 2. Documentación en español, código en inglés

Es exactamente el reparto de `AGENTS.md`: quien lee el juego ve inglés; quien lee
la documentación del proyecto, español. Separar ambos casos evita discusiones.

## Risks / Trade-offs

- **Código antiguo en español**: otros módulos pueden tener comentarios en
  español. Este cambio solo cubre lo que hice yo; el resto se corrige cuando se
  toque ese código.
- **Los mensajes de log cambian de idioma**: quien lea trazas viejas verá los dos.
  Se acepta, son textos de desarrollo.
