# Cohetes — archivos de trabajo en Aseprite

Generadores reproducibles: si cambias un color o una coordenada, vuelve a ejecutar y se
regenera el `.aseprite` entero.

## Estructura

| Archivo | Qué es |
|---|---|
| `source-landing.png` | PNG original del cohete de aterrizaje (no tocar: es la entrada) |
| `source-ascent.png` | PNG original del cohete en vuelo (no tocar) |
| `build-stencil.lua` | Genera `rocket-landing.aseprite` desde `source-landing.png` |
| `build-ascent.lua` | Genera `rocket-ascent.aseprite` desde `source-ascent.png` |
| `run-landing.lua` / `run-ascent.lua` | Envoltorios de una línea (`dofile`) para lanzarlos |
| `rocket-landing.aseprite` | Maestro editable del aterrizaje (98×127) |
| `rocket-ascent.aseprite` | Maestro editable del vuelo (118×132) |
| `landing-final.png` / `ascent-final.png` | Export PNG con transparencia |

## Regenerar

```powershell
& "C:\Program Files\Aseprite\Aseprite.exe" -b --script "...\ase\run-landing.lua"
& "C:\Program Files\Aseprite\Aseprite.exe" -b --script "...\ase\run-ascent.lua"
```

Desde el agente, con el MCP de Aseprite:
`tools.aseprite.run_lua_script({ script: 'dofile("<ruta>/run-landing.lua")' })`

## Qué hace cada generador

**Aterrizaje** (`build-stencil.lua`) — conserva el dibujo del original y corrige solo los defectos:
1. Alfa binario (el PNG venía con bordes semitransparentes).
2. Remapeo de los 14 colores sucios a la paleta de identidad (quita grises embarrados y el oliva).
3. Patas redibujadas: las tres apoyan en la misma línea `y=120`.
4. Contorno continuo de 1 px.

**Vuelo** (`build-ascent.lua`):
1. Alfa binario.
2. Remapeo de paleta; el beige de las "rayas" pasa a tono de casco (eran arañazos).
3. Los tonos de casco que caían dentro de la llama o de las aletas se corrigen.
4. Contorno continuo de 1 px.

## Salida al juego

`..\rocket-landing.png` (98×127) y `..\rocket-ascent.png` (118×132), más sus `@2x`
(196×254 y 236×264) escalados con vecino más cercano desde el maestro.
