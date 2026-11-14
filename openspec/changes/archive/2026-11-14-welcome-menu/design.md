# Design

## Context

Proyecto Godot 4.7 con el proyecto del motor en `game/`. El lienzo es de
850×480 con `stretch/mode = canvas_items`, y el arte base está dibujado a 425×240
y mostrado al doble (cada píxel artístico son 2×2 en pantalla).

No había ninguna escena: `run/main_scene` estaba vacío y no existía carpeta
`assets/`. El arte del fondo y de los cohetes ya estaba hecho y solo el fondo del
menú está integrado.

Las reglas del repositorio viven en `AGENTS.md`: pantallas en `scenes/`, tema
compartido en `themes/`, GDScript con tipado explícito y sin `:=`.

## Goals / Non-Goals

**Goals:**

- Una pantalla de entrada presentable, operable con ratón y con teclado.
- Mantener la nitidez del pixel art en cualquier tamaño de ventana.
- Dejar un tema de UI reutilizable por las pantallas siguientes.
- Que las acciones sin destino avisen en vez de parecer rotas.

**Non-Goals:**

- Selector de misión, pantalla de configuración y paneles de intro.
- Localización de textos: el menú usa literales provisionales.
- Sonido o música en el menú.

## Decisions

### 1. La escena vive en `scenes/welcome/`

Coincide con el punto 20 del diseño formal (`scenes/welcome/welcome.tscn`) y con
la regla de `AGENTS.md` de que solo las pantallas y el flujo del juego van en
`scenes/`. El fondo se queda en la misma carpeta porque solo lo usa esta escena.

### 2. `aspect = keep` y `scale_mode = integer`

El proyecto venía con `aspect = expand`, que hace crecer el viewport con la
ventana: el fondo de 850×480 se estiraría a una escala fraccionaria.

Alternativas descartadas:

- **Mantener `expand`**: el arte se estira y los píxeles dejan de ser cuadrados;
  además el fondo no cubriría el viewport ampliado.
- **Escalado fraccionario**: 1920×1080 da ×2,25, así que un píxel artístico mide
  4,5 px de pantalla; se ven bloques de 4 y de 5 mezclados.

El precio es tener bandas negras en ventanas que no son múltiplo exacto. Se
acepta: para pixel art es la opción correcta y se revierte cambiando una línea.

### 3. Filtro de textura Nearest global

`rendering/textures/canvas_textures/default_texture_filter = 0`. Con filtro
lineal, cualquier escalado interpola y convierte el arte en una mancha. Pasa de
forma global para no depender de recordar el ajuste en cada import.

### 4. Botones como nine-patch, no como `StyleBoxFlat`

El panel pedido tiene bisel y tornillos en las esquinas, que un `StyleBoxFlat`
no puede dibujar. Se generan tres PNG de 72×56 con Aseprite (normal, hover con
bisel teal, pulsado con bisel invertido) y se montan como `StyleBoxTexture` con
margen de textura de 20 px: las esquinas y los tornillos quedan fijos y solo se
estira el centro, que es color plano. Un mismo PNG sirve para un botón de 120 px
o de 320 px.

Alternativa descartada: tres PNG por tamaño de botón. Multiplica el arte y
desincroniza los estilos.

### 5. Silkscreen en múltiplos de 8

Silkscreen está diseñada sobre una rejilla de 8 px. Se usa a 40 para el título y
16 para el cuerpo, que son múltiplos exactos. A tamaños intermedios los trazos
salen de distinto grosor y se rompe la sensación de píxel. Godot detecta que es
una fuente de píxel y desactiva hinting y posicionamiento subpíxel al importarla.

### 6. Aviso temporal en lugar de botones deshabilitados

Un botón deshabilitado no explica por qué lo está. El aviso aparece al pulsar,
dura dos segundos y se desvanece con un `Tween`; no deja UI muerta y desaparece
solo cuando los destinos existan.

El mismo código sirve para las dos acciones y lee `ResourceLoader.exists()` en
cada pulsación, así que en cuanto se cree la escena destino la navegación
funciona sin tocar el menú.

### 7. Reparto de la pantalla

Título arriba en el cielo, acciones abajo sobre el regolito. La Tierra y la base
quedan enteras a la vista. La primera versión apilaba título y botones en la
mitad superior y el hueco entre botones cortaba la Tierra en una franja, que se
lee como un error de dibujo; por eso el bloque de acciones baja y el espaciador
del `VBoxContainer` absorbe la diferencia.

### 8. Tema compartido en `themes/pixel_theme.tres`

Los estilos y la fuente se configuran una vez. La pantalla de configuración y el
resto de la UI los heredan sin repetir overrides por nodo.

## Risks / Trade-offs

- **Bandas negras** si la ventana no es múltiplo exacto. Se puede volver a
  `expand` cambiando `scale_mode`, a costa de perder la rejilla.
- **El aviso queda como código muerto** en cuanto existan las dos escenas
  destino: hay que borrarlo entonces, no dejarlo por si acaso.
- **Textos literales**: cuando exista la tabla de strings hay que mover los tres
  textos del menú, como ya marca la regla de specs.
- **La fuente no tiene negrita**: el énfasis tiene que venir del color o del
  tamaño, nunca de un `bold` sintético que Godot renderiza emborronado.
