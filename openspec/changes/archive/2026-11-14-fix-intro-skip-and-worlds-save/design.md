# Design

## Salto de la intro

La secuencia es una corrutina (`_play_intro`) que espera varios tweens. El salto
no puede limitarse a mostrar la historia: la corrutina sigue suspendida y, al
terminar el tween, vuelve a escribir el estado de la historia.

Decisión:

- `_animation_tween` guarda el tween activo (fundido, salida o travesía).
- `_on_skip_pressed()` lo mata, lo olvida y muestra la historia una sola vez.
- Cada `await` de `_play_intro` comprueba `_skipped` y **sale sin volver a
  mostrar** la historia; `_on_skip_pressed` ya lo hizo.

Así el jugador puede saltar en cualquier punto (incluido un fundido a negro) y
seguir en la parte en la que esté, sin que la animación pendiente la pise.

## Guardado atómico

`FileAccess.WRITE` trunca el archivo destino al abrirlo: no hay forma de escribir
«casi entero» sin destruir el anterior. Alternativas descartadas:

- Escribir directamente y rezar: es el bug actual.
- Borrar el destino y renombrar: deja una ventana en la que no existe ningún
  archivo.

Decisión: escribir `worlds.json.tmp` completo, cerrar y renombrar con
`DirAccess.rename_absolute` sobre `worlds.json`. En esta plataforma el rename
reemplaza el destino en una sola operación (comprobado con un script local), así
que el archivo anterior sigue íntegro hasta el último instante.

## Archivo dañado

Antes de renombrar se comprueba que el JSON es un objeto con una lista
`worlds`. Si no lo es:

1. El archivo se mueve a `worlds.json.bak` (si ya había un `.bak`, se
   reemplaza: es la copia más reciente del daño).
2. `WorldStore.last_load_error` queda con un mensaje legible.
3. La pantalla de mundos muestra ese mensaje como toast.

No se crea un `worlds.json` vacío hasta que el jugador guarde algo, de modo que
un arranque en solo lectura no destruye la evidencia.

## Riesgos

- El rename puede fallar (permisos, disco lleno). En ese caso `_write` devuelve
  `false`, borra el temporal y el archivo anterior queda intacto; la UI ya
  muestra «no se pudo guardar».
- El toast de archivo dañado se pierde si el jugador cambia de escena de
  inmediato; es informativo, no bloqueante.
