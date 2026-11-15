# Futuro: tripulación y multijugador

- **Estado:** Diferida
- **Prioridad:** P3
- **Esfuerzo:** XL
- **Depende de:** sim determinista, netcode, UI de equipo
- **Documentos relacionados:** `docs/designs/junior-astronauta-outpost-lunar.md` (“Mejoras futuras”)

## 1. Qué es

Pasar de **un astronauta** a una **tripulación de 2–4**, primero en **co-op local** (misma pantalla) y solo después en online.

Los jugadores comparten recursos y base, pero tienen **roles** y **stats** distintos. La semilla de misión y las stats aleatorias vuelven aquí: con un solo astronauta no aportaban variedad; con varios, sí.

## 2. Por qué

- El diseño v1 lo deja explícitamente para después: “Multiplayer y varios astronautas (con las stats aleatorias que vuelven con ello)”.
- Los roles convierten las decisiones en **conversación**: quién repara, quién escanea, quién vigila la radiación.
- Es el mayor espacio de rejugabilidad a largo plazo.

## 3. Cómo funcionaría

### 3.1 Roles

| Rol | Ventaja | Coste |
| --- | --- | --- |
| **Engineer** | Repara 25 % más rápido | Escanea más lento |
| **Scientist** | Escanea 25 % más rápido; mejores informes | Repara más lento |
| **Medic** | La salud decae menos; cura mejor | Menos velocidad de movimiento |
| **Pilot** | EVA más seguro; menos dosis | Peor en el invernadero |

Los roles no son clases rígidas: son **modificadores** de stats existentes. Nada de árboles de habilidad.

### 3.2 Co-op local (primera fase)

- Dos jugadores en la misma pantalla, teclado + mando.
- Cámara compartida; si se separan, se divide la pantalla o se limita el área.
- Recursos compartidos; el HUD muestra “P1/P2” solo en las acciones.
- Sin red; sin cuentas; sin matchmaking.

### 3.3 Online (segunda fase, solo si hay demanda)

- Godot Multiplayer (ENet para escritorio, WebSocket para HTML5).
- **Host autoritario:** el anfitrión corre `GameSim`; los clientes envían intenciones, no estado.
- Sincronizar solo: tick, recursos, estados de máquinas, posición, eventos.
- Sin PvP; sin rankings globales.
- Si un cliente se cae, el host sigue; el jugador puede reconectar.

## 4. Datos reales que lo anclan

- No hay un “dataset de multijugador”; el anclaje es la **fisiología**: los roles deben reflejar diferencias humanas reales (experiencia, masa muscular, tolerancia a la radiación), no fantasía.
- Las stats aleatorias deben estar **acotadas** y explicadas (“este astronauta tiene menos masa muscular; se fatiga antes”), no ocultas.
- La dosis de radiación es individual; la carrera de 600 mSv es personal. Eso ya justifica stats por astronauta.

## 5. Diseño técnico

- **No tocar `GameSim` para el co-op local:** el segundo jugador es otra entidad de input, no otra simulación.
- **Online:** separar `GameSim` (autoridad) de `Presentation`; comandos con `tick` y `player_id`; interpolación de render.
- **UI:** un HUD compacto por jugador; no duplicar los 7 paneles.
- **Input:** mapa de acciones por dispositivo; no hardcodear WASD.
- **Tests:** un test de determinismo con 2 jugadores y 300 ticks.

## 6. Riesgos y decisiones abiertas

| Riesgo | Mitigación |
| --- | --- |
| El netcode se come el tiempo del contenido | Co-op local primero; online solo post-evento |
| Desincronización | Host autoritario + sim determinista + comandos, no estado |
| Dos jugadores en 850×480 | Cámara compartida; no split-screen completo |
| El rol “medic” no tiene nada que curar | La salud/rutina debe existir antes (`astronaut-health.md`) |
| Stats aleatorias injustas | Rangos acotados + explicación en la ficha |
| Multijugador en HTML5 | WebSocket; probar latencia; no prometerlo hasta que funcione |

## 7. Criterios de aceptación

- [ ] Co-op local de 2 jugadores con recursos compartidos.
- [ ] Los roles modifican stats existentes, no añaden sistemas.
- [ ] El host es autoritativo; un cliente no puede corromper el estado.
- [ ] Reconexión sin perder la partida (online).
- [ ] La partida sigue siendo jugable con un solo jugador.
