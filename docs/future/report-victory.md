# Futuro: victoria por informes

- **Estado:** Aplazado
- **Prioridad:** P1
- **Esfuerzo:** M
- **Depende de:** consola de comunicaciones, POIs exteriores, escaneo, entrega de muestras
- **Documentos relacionados:** `docs/designs/junior-astronauta-outpost-lunar.md`,
  `docs/future/minerales-mapa.md`, cambio `add-mission-victory`

## 1. Qué es

La victoria original del diseño: escanear los 3 POIs del exterior, entregar sus
muestras y enviar **3 informes desde la consola de comunicaciones**. La partida
termina en victoria al enviarse el tercer informe; los informes parciales
cuentan en la evaluación final.

## 2. Por qué está aplazado

El cambio `add-mission-victory` entrega el primer objetivo funcional sin depender
de sistemas que aún no existen: **sobrevivir los 300 ticks de misión**. Es un
corte deliberado para que la partida ya se pueda ganar y para no bloquear la
demo en la consola, el escaneo o el arte exterior.

El diseño formal ya contempla la consola sin exterior como corte de emergencia
(Alternativa 2). Este aplazamiento recorta un paso más: primero una regla de
supervivencia simple, después la cadena científica completa.

## 3. Qué falta

- Consola de comunicaciones interactiva con panel de misión e informes.
- POIs exteriores (≤2 pantallas) y una herramienta de escaneo con barra
  in-world que se cancela al moverse.
- Entrega de muestras y envío de informes en la consola.
- Contador de informes en el HUD y en la evaluación.
- Sustituir la condición de victoria por reloj: la victoria pasa a ser
  «3 informes enviados», y el reloj de misión queda como límite de tiempo con
  informes parciales.

## 4. Cómo sabremos que está terminado

- Una partida puede ganarse escaneando 3 POIs y enviando 3 informes desde la
  consola.
- La evaluación muestra 3 informes enviados y la causa de victoria científica.
- La spec `simulation-core` deja de declarar la victoria por supervivencia y la
  recibe la nueva condición, con sus escenarios WHEN/THEN.
