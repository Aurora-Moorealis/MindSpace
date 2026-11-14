# Stills de intro y aterrizaje

- **Estado:** pendiente
- **Prioridad:** media
- **Depende de:** menú

## Objetivo

Sustituir las cutscenes descartadas por **2–3 paneles estáticos skippeables**
(`scenes/intro_stills/`) entre el menú y la base.

## Alcance

Tres imágenes a 850×480, en el mismo estilo que el fondo del menú:

| # | Plano | Contenido |
| --- | --- | --- |
| 1 | Llegada | El cohete de aterrizaje descendiendo sobre la base vista desde arriba |
| 2 | Contacto | El cohete posado, polvo asentándose, astronauta saliendo |
| 3 | Interior | La base por dentro: invernadero y consola, puerta al exterior |

- Cada panel se mantiene en pantalla hasta que el jugador pulsa, con un aviso
  discreto ("clic / Enter para continuar").
- Se puede saltar todo con una tecla (Esc) y desde el primer panel.
- Son imágenes fijas: no hay animación ni transición complicada; como mucho un
  fundido a negro de 0,2 s.

## Criterios de aceptación

- Ningún panel tarda más de 1 s en leerse.
- El salto funciona desde el primer frame.
- Al terminar se entra en `scenes/base/base.tscn`.

## Notas

El arte se genera con el mismo proceso que el fondo del menú: concepto →
conversión a rejilla 425×240 con píxel gordo → limpieza de paleta y contorno
(ver la spec `art-style` y el manual `docs/guia-estetica.md`).
