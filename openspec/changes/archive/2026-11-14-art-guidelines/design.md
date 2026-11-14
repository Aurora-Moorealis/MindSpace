# Design

## Context

El arte del proyecto se produjo antes de tener una spec: un fondo de menú, dos
vistas de un cohete y un juego de paneles de botón. Las reglas que se siguieron
estaban descritas en `docs/guia-estetica.md` junto al procedimiento, y esa mezcla
hace que ninguna de las dos partes se pueda citar ni auditar por separado.

Los assets ya cumplen las reglas: esta spec no introduce estilo nuevo, lo
congela.

## Goals / Non-Goals

**Goals:**

- Que las reglas del arte sean un contrato citable desde cualquier cambio.
- Que se puedan comprobar sobre un PNG sin preguntar a quien lo dibujó.
- Dejar el manual de procedimiento en un documento que no se confunda con reglas.

**Non-Goals:**

- Reescribir los assets existentes.
- Automatizar la auditoría (la spec deja los criterios listos, pero no hay script).
- Cubrir el estilo de la música o el sonido.

## Decisions

### 1. Las reglas van a una spec, el procedimiento se queda en docs

Una spec de OpenSpec contiene requisitos observables con escenarios; encaja con
"el alfa es 0 o 255" y no con "convierte el PNG con este comando".

Se probó a meterlo todo en la spec y el resultado era un documento con requisitos
que describían recetas, imposible de validar. Se probó lo contrario, dejar todo
en la guía, y es de donde venimos: nada se puede auditar.

Reparto final:

| Contenido | Dónde |
| --- | --- |
| Reglas normativas y paleta | `openspec/specs/art-style/spec.md` |
| Procesos, herramientas y errores frecuentes | `docs/guia-estetica.md` |
| Decisiones de esta migración | este documento |

### 2. La paleta va en la spec, no en la guía

Los hex son la parte más auditable del estilo: un script puede comparar los
colores de un PNG con la lista. Si vivieran en la guía, cambiar un tono no
obligaría a actualizar ningún contrato y se desincronizaría sin avisar.

El coste es que el requisito "Paleta cerrada" es largo; con 330 caracteres cabe
en el límite de 500 y agrupa la paleta entera en un solo sitio.

### 3. Un requisito por regla, no uno por color

Agrupar por materiales (casco, teal, ámbar, navy, fuego) daría siete requisitos
de paleta y todos se comprobarían con la misma consulta. Se prefiere un requisito
único con la lista completa y escenarios separados para "auditar" y "añadir un
color".

### 4. El cambio se archiva en el acto

No hay código que implementar: el entregable es la propia spec. Dejarlo abierto
haría que `openspec/specs/` siguiera vacío y que la regla no fuese canónica. Se
archiva y la spec pasa a ser la de referencia del proyecto.

### 5. `docs/guia-estetica.md` conserva el mapa de archivos

El manual mantiene la tabla de dónde vive cada tipo de arte (maestros, fondos de
escena, texturas de UI) porque es información de navegación del repositorio, no
una regla de dibujo. `AGENTS.md` ya define las carpetas; la guía solo concreta el
arte.

## Risks / Trade-offs

- **Duplicación**: si alguien vuelve a escribir la paleta en la guía, se
  desincroniza. Mitigación: la guía enlaza a la spec y no repite hex.
- **La spec puede quedarse corta** para un estilo que evolucione: añadir un tono
  exige editar la spec (a propósito, es el punto del ejercicio).
- **El límite de 500 caracteres** por requisito obliga a mantener la paleta
  compacta; un cambio de formato futuro (una tabla adjunta) requeriría revisar
  cómo se cita.
- **Verificación manual**: hasta que exista un script, el criterio de terminado
  depende de que alguien ejecute las comprobaciones.
