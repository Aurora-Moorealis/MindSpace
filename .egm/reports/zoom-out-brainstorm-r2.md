# Zoom-Out Brainstorm Report R2 — verificación tras decisiones del autor

Modo: BRAINSTORM (2ª pasada). Fuentes: input v2, brief, reporte 1ª pasada. Repo verificado: `game/` sigue sin bases, resources, content o scripts — nada que reutilizar.
(El revisor no tuvo herramienta de escritura; este archivo conserva el reporte tal como se recibió.)

## BLOCKER
Ninguno. El plan v2 es realizable tal como está escrito.

## MAJOR

### M1 — El exterior está programado ANTES de su propio gate — "earned scope" invertido
H0–12 incluye "exteriores con 3 POI + escaneo" *antes* del gate H12 que podría cortarlo. El gate decide entre descartar horas hundidas o no — y los cortes pre-acordados que descartan trabajo invertido son los que nadie ejecuta a hora 12 de un jam. El fallback ("informes solo desde consola") es más barato y subconjunto estricto: construir la consola + tarjetas de informe **primero** en H0–12 y tratar el exterior como extensión ganada. Esto además da contenido real al fallback y arregla N3.

### M2 — Contradicción input-vs-brief sobre swap NASA vs golden build
input §7: "corte duro pre-golden-build (H28)" vs brief "Plan en bloques": golden H28, swap H28–32, vídeo desde golden. Si el swap corre H28–32, el build taggeado contiene datos pre-swap y el vídeo muestra números simulados en el criterio que juzga datos reales. Fix de una frase: swaps verificados terminan H27, golden H28, vídeo H28–32, filas no verificadas salen con badge "simulado". Coste cero; tal como está, los dos documentos discrepan sobre qué verá el juez.

### M3 — "Estado serializable" invita a un serializador genérico — save system disfrazado
La lista de prohibiciones dice "save system" fuera, pero `GameSim` exige "estado serializable". Lo necesario: (a) presets de demo que construyen un estado conocido desde campos explícitos; (b) telemetría EventLog. Ninguno exige una capa round-trip genérica (3–4 h del único dev fuerte). Constreñir ahora: "presets como constructores explícitos; sin serialización genérica".

## NITS

- **N1 — `.tres` sin ventana de propiedad ni validación automática.** `check-gdscript.sh` valida `.gd`, no `.tres`; una fila rota asoma en playtest, no en commit. Fix barato: un dueño por ventana de reloj (Mijael contenido, DevGreem durante balanceado); el smoke de la hora 1 añade un chequeo headless "cargar todos los `databases/*.tres` + referencias de `resources/*.gd`".
- **N2 — Hidden stats huérfanas sobreviven invisibles.** Nada de las 8 máquinas mejoraría *velocidad de movimiento* (no existe máquina de botas/traje-ligero). Al congelar la lista 8×2, verificar que cada hidden stat tiene ≥1 mejora; las huérfanas (movimiento es la sospechosa principal) se eliminan.
- **N3 — El fallback del exterior está indefinido.** "Informes solo desde consola" no dice qué genera esos informes. Predefinir: la consola transmite tarjetas de archivo/telemetría (la misma UI de tarjeta del escaneo). Si no, el corte de emergencia exige diseño a hora 12.
- **N4 — El merge "provisiones" no tiene spec.** Escribir un párrafo en papel a hora 1 (etiqueta, máquinas que consumen, qué números se dividen), para que H12 sea edición de datos, no diseño.
- **N5 — Submisiones sin superficie de presentación.** La respuesta mínima: lista pequeña dentro de la escena de la consola de comunicaciones (reusa escena y modelo de interacción existentes), reclamable automáticamente al disparar la condición. No un quest journal.
- **N6 — La ventana de sueño de DevGreem (H18–22) adelanta el freeze de schema.** Declarar "schema de datos congelado al cierre de H12" — una línea que cabalga sobre el gate existente.

## Reutilización
Verificado: no existe nada que reutilizar. Sin addons nuevos, sin cliente HTTP — correcto.

## Veredicto y los dos cortes H12
Sí — el plan v2 es **defendible**. Los compromisos son cortes reales más que aplazamientos disfrazados, y la apuesta de 4 recursos es honesta porque su coste de construcción es casi plano (filas en un loop genérico) mientras su riesgo —tiempo de balanceo— es justo lo que mide el gate H12. El margen de seguridad son los gates pre-acordados; hay que ejecutarlos.
Si el gate H12 falla, los dos primeros cortes, en este orden: (1) **exterior → informes solo-consola** (~6–8 h recuperadas, y con la inversión de orden de M1 cuesta cero horas hundidas); (2) **comida+agua → "provisiones"** (~2 h + elimina el riesgo de balance juzgado, con la spec de N4 escrita en hora 1).

## Bottom line
El plan v2 es defendible y los gates son su margen honesto. No dejar que tres residuos lleguen al draft sin resolver: la contradicción golden/swap (M2), el exterior front-loaded (M1) y el "estado serializable" (M3) — cada uno cuesta un artefacto equivocado, horas hundidas o un save system oculto, y cada uno se arregla en una frase. Resources-sobre-JSON es aceptable en su premisa declarada, con: ventanas de dueño + chequeo headless de carga (N1), poda de hidden stats contra la lista de mejoras en hora 1 (N2), y los dos cortes H12 respetados en orden.
