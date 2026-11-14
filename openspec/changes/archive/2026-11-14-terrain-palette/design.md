# Design

## Context

`art-style` describe el arte de sprites y de la UI, pero no tenía rampa para el
terreno. El juego necesita suelo, rocas, minerales y la base, y sin una paleta
de terreno cada agente inventaría grises distintos.

Los cuatro materiales tampoco estaban decididos: el brief del juego pide
minerales reales y la primera lista mezclaba la firma visual de Marte con la
Luna.

## Goals / Non-Goals

**Goals:**

- Cerrar la paleta de terreno antes de dibujar.
- Saber cuántos materiales hay, cuáles son y para qué sirve cada uno.
- Fijar la rejilla del mundo para que los tilesets de suelo y de base encajen.

**Non-Goals:**

- Dibujar los tilesets (va en el arte, no en la spec).
- Definir la economía: qué produce cada máquina es diseño de juego.
- Tocar la paleta de identidad: los 16 colores nuevos se añaden, no se sustituyen.

## Decisions

### 1. Cuatro materiales, elegidos por función y no por vistosidad

Cada mineral tiene que justificar una cadena de construcción de la base:

| Material | Cadena que habilita |
| --- | --- |
| Hielo de agua (H₂O) | Extractor → agua, O₂ por electrólisis, combustible |
| Ilmenita (FeTiO₃) | Reactor de reducción → hierro, titanio, O₂ |
| Material silícico (SiO₂) | Horno → vidrio de invernadero y obleas de panel solar |
| Regolito basáltico | Sinterizador → ladrillos de blindaje, plataformas |

Se descartó la hematita (Fe₂O₃) porque el hierro ya lo aporta la ilmenita, que
además da titanio y oxígeno: dos minerales para lo mismo no se distinguen al
miralos a 32 px.

### 2. Ilmenita en vez de hematita como mineral metálico

La hematita es la firma visual de Marte y en la Luna aparece como una costra
apagada en latitudes altas. La ilmenita es el mineral opaco dominante de los
mare basaltos y el que la NASA estudia para producir oxígeno y metal in situ.
Científicamente es más lunar y lúdicamente más útil.

### 3. El hielo es hielo sucio

En los cráteres polares el agua está mezclada con regolito en sombra permanente.
Un cristal azul brillante sería bonito y falso. La rampa va desaturada y los
tiles se dibujan sobre fondo oscuro, con vetas claras en vez de cristales.

### 4. Cinco rampas de tres o cuatro pasos

Regolito (4), basalto (3), ilmenita (3), silíceo (3), hielo (3). Son 16 colores
nuevos: la paleta pasa de 22 a 38. Es mucho, pero el terreno ocupa la mayor parte
de la pantalla y sin profundidad de rampa se ve plano.

Se separan por **tono además de por brillo** (ilmenita azulada, basalto neutro,
regolito cálido) porque el requisito de materiales exige distinguirlos sin
etiquetas.

### 5. Losetas de 16 px de arte

El diseño formal fija tilesets de 32 px. Como el arte se dibuja a 425×240 y se
muestra al doble, la loseta se dibuja a 16×16 y se exporta a 32×32. Así encaja
con la rejilla del resto del arte y el juego no necesita ninguna escala extra.

## Risks / Trade-offs

- **38 colores** es más de lo que recomienda la guía para un sprite suelto; se
  acepta porque el terreno es un sistema, no un objeto.
- **Cuatro materiales pueden quedarse cortos** si el diseño pide aluminio
  (anortosita) o vidrio de impacto. Ambas ampliaciones están previstas en el
  escenario "Material nuevo".
- **La ilmenita y el basalto comparten oscuridad**: si a 32 px no se separan, hay
  que subir el lustre metálico de la ilmenita, no cambiar la paleta.
