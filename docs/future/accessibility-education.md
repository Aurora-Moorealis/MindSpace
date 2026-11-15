# Futuro: accesibilidad y educación

- **Estado:** Propuesta
- **Prioridad:** P1
- **Esfuerzo:** S/M
- **Depende de:** strings, UI, font
- **Documentos relacionados:** `docs/designs/junior-astronauta-outpost-lunar.md`, `docs/art-direction.md`

## 1. Qué es

Hacer que el juego sea realmente usable por **niños de 7–12 años**, en casa y en el aula, sin depender de leer párrafos ni de distinguir colores.

No es “modo fácil”: es **claridad**. Un juego que un niño de 7 años entiende en 60 segundos es un juego que un juez entiende en 20.

## 2. Por qué

- La audiencia del desafío es 7–12; el brief pide lenguaje claro y explicar la jerga en contexto.
- *Validity* incluye “usable and user-friendly”; *Presentation* incluye claridad.
- Un aula es un caso de uso real: sesiones de 10–15 min, sin cuenta, sin save.

## 3. Directrices

### 3.1 Lenguaje

- Frases cortas; una idea por línea.
- Términos nuevos con glosario contextual: **radiation dose (mSv)**, **microgravity**, **lunar day**, **regolith**, **SPE**, **GCR**.
- Números con unidad y comparación: “250 mSv — el límite de una misión; no es una dosis letal”.
- No usar “sol” para la Luna; “mission day” o “lunar day”.

### 3.2 Color y forma

- No usar solo color para estado: icono + texto + forma.
- Paleta segura para daltonismo: el rojo/verde no puede ser la única diferencia.
- Contraste mínimo 4.5:1 para texto; el pixel-art puede ser oscuro, pero el texto del HUD no.
- Ticks de umbral en las barras (no solo el color).

### 3.3 Input y tiempo

- Teclado solo; mando opcional.
- Sin *timed reading*: los diálogos esperan.
- Pausa real; el reloj de la simulación se detiene.
- Subtítulos para SFX importantes (“radiation alarm”).
- Sin *quick time events*.

### 3.4 Aula

- **Classroom mode:** partida de 10–15 min, sin save, con un objetivo claro.
- **Teacher guide:** 1 página con el vocabulario y 3 preguntas para después.
- Sin cuentas, sin datos personales, sin multijugador online.
- Un proyector 16:9; texto legible a 3 m.

### 3.5 Localización

- v1 en inglés (requisito del desafío).
- Strings en `strings.tres`; claves estables.
- Español como primera localización post-evento; no hardcodear texto.
- Fechas y números con formato local; unidades siempre.

## 4. Diseño técnico

- `StringTable` ya existe; usar `tr()` solo en UI, no en lógica.
- Fuente Press Start 2P a 8 px: **no bajar de 8 px**; para texto largo, una fuente de lectura secundaria o un panel con más interlineado.
- Escalado de UI: 850×480 base; probar a 1280×720 y 1920×1080.
- Glosario: un `Dictionary[StringName, String]` en `strings.tres`; tooltip al pasar el ratón o al pulsar “?”.
- Opciones: tamaño de texto (1×/1.5×), alto contraste, subtítulos, velocidad de texto.

## 5. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| 8 px es demasiado pequeño para lectura larga | Texto corto + glosario; no párrafos |
| El pixel-art pierde legibilidad al escalar | Escalado entero; probar en 1080p |
| El rojo/verde es el único canal | Iconos + texto + patrones |
| El aula no tiene 15 min | Classroom mode de 10 min; demo-jump |
| La localización duplica el trabajo | v1 solo inglés; claves estables para después |
| El glosario se convierte en un muro | Tooltip contextual, no una enciclopedia |

## 6. Criterios de aceptación

- [ ] Un niño de 7 años explica el objetivo del juego tras 60 s.
- [ ] Ninguna información depende solo del color.
- [ ] El texto se puede leer a 1080p y en proyector.
- [ ] El juego se puede jugar solo con teclado.
- [ ] Hay glosario para 5 términos clave.
- [ ] Classroom mode dura 10–15 min y no requiere cuenta.
