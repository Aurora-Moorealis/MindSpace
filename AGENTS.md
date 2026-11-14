# AGENTS.md

Guía para agentes que trabajen en **MindSpace** (proyecto Godot 4.x). Todo lo que
haya aquí es específico de este repositorio y complementa las convenciones
globales. Si algo choca con una instrucción directa del usuario, manda el usuario.

## Idioma del código y las interfaces

**Todo el código y todos los comentarios van en inglés**, sin excepciones:

- Comentarios de cualquier tipo (`#`, docstrings de `##`, comentarios de bloque).
- Identificadores: nombres de variables, funciones, señales, clases (`class_name`),
  constantes, enums, archivos, escenas, nodos y recursos.
- Mensajes de log, `push_error`/`push_warning`, asserts y textos de depuración.
- Nombres de commits y de ramas, según lo que pida el repositorio.

**Las interfaces (UI) también van en inglés**: todo texto visible para el jugador
(botones, etiquetas, títulos, tooltips, diálogos, menús, mensajes de error en
pantalla y texto de placeholders). No se traduce a español ni se deja en el idioma
del usuario; si hace falta localización, se hace con el sistema de traducciones del
proyecto, no hardcodeando español.

```gdscript
# Good
signal health_changed(current: int, maximum: int)
var remaining_lives: int = 3
label.text = "Continue"
push_warning("Save file not found, starting a new game.")

# Wrong
signal vida_cambiada(actual: int, maxima: int)
var vidas_restantes: int = 3
label.text = "Continuar"
push_warning("No se encontró la partida, empezando una nueva.")
```

La **documentación** (README, `docs/`, `AGENTS.md`, comentarios de ficheros de
configuración que no son código) sí puede ir en el idioma del usuario. La regla
aplica a lo que ejecuta el juego o lo lee otro desarrollador en el código.

## EGM (Elephant-Goldfish Model)

Los artefactos de EGM (briefs, borradores y reports de revisión) se escriben en
la carpeta `.egm/` de la raíz del repositorio. Si no existe, EGM la crea.

EGM artifact directory: .egm

### Documentos generados y OpenSpec

EGM produce, además de sus artefactos de trabajo en `.egm/`, el **documento de
diseño formal** de cada feature en `docs/designs/<feature>.md` (lo crea la skill
`egm-draft` al finalizar la redacción). Ese es el documento que se comparte y se
revisa; `.egm/` guarda el material de trabajo: brief de concepto, borradores y
reportes de las lentes Goldfish por etapa.

El proyecto también usa **OpenSpec**: la carpeta `openspec/` (specs y changes),
los comandos `/opsx-*` en `.opencode/commands/` y las skills `openspec-*` en
`.opencode/skills/`. EGM y OpenSpec se complementan; no se sustituyen:

| Necesidad | Dónde va |
| --- | --- |
| Explorar y conceptualizar una idea, brief y revisión adversarial | EGM (`.egm/`, y el diseño final en `docs/designs/`) |
| Especificar un cambio concreto (proposal, delta specs, tasks) y aplicarlo | OpenSpec (`openspec/changes/<change>/`) |

Si un cambio de OpenSpec nace de un documento de `docs/designs/`, su
`proposal.md` lo referencia por ruta en lugar de copiarlo. No dupliques el mismo
contenido en los dos sistemas: cada decisión vive en un único sitio y el otro la
enlaza.

## Organización de archivos

El proyecto Godot vive en **`game/`**: ahí está `project.godot` y todas las rutas
`res://` son relativas a esa carpeta. La raíz del repositorio solo contiene
documentación y configuración de Git. Todo archivo nuevo del juego va dentro de
`game/` siguiendo esta estructura.

| Carpeta (bajo `game/`) | Qué va | Ejemplo |
| --- | --- | --- |
| `addons/` | Addons de Godot y de terceros. **No editar** salvo que el encargo sea el addon. | `addons/limboai/` |
| `assets/` | Assets **compartidos** que no pertenecen a un contenido concreto (`audio/`, `fonts/`, `images/`, `particles/`, `tilesets/`). | `assets/images/health_bar/` |
| `components/` | Librerías reutilizables entre proyectos, gestionadas con **LibraryManager**. | `components/move_system/` |
| `content/` | Contenido del juego: cada cosa con **todo lo suyo** en `content/<tipo>/<nombre>/`. | `content/entities/player/` |
| `databases/` | (Opcional) Resources `.tres` que hacen de base de datos o registro. | `databases/effect_connections.tres` |
| `resources/` | Scripts que definen clases `Resource` y resources compartidos que **no** son contenido. | `resources/potions/potion_data.gd` |
| `scenes/` | Escenas «de verdad»: pantallas, menús y flujo del juego. No personajes ni entidades. | `scenes/pause_menu/` |
| `scripts/` | Código **solo de este proyecto**: autoloads, managers, glue. | `scripts/autoloads/event_bus.gd` |
| `script_templates/` | Plantillas del editor para humanos. **No tocar.** | `script_templates/Object/named_class.gd` |
| `shaders/` | (Opcional) Shaders compartidos por varias partes del proyecto. | `shaders/effects_shader.tres` |
| `tests/` | (Opcional) Zona local de pruebas, **ignorada por git**. | `tests/player_theme_test.tscn` |
| `themes/` | (Opcional) Temas compartidos del proyecto. | `themes/default_theme.tres` |

Carpetas extra (`ai/` de LimboAI, `registries/`…) se respetan tal cual. Si no
sabes si una carpeta es del motor, del proyecto o de un addon, no la muevas.

### Dónde va cada cosa

1. **¿Personaje, entidad, máquina, objeto, poción, efecto o similar?**
   → `content/<tipo>/<nombre>/` con su escena, script, `.tres`, arte, audio y
   subcarpetas.
2. **¿Pantalla, menú, nivel o escena de flujo?** → `scenes/<escena>/`.
3. **¿Código que podría usarse en otro proyecto tal cual?**
   → `components/<libreria>/` + `dependencies.txt`.
4. **¿Código que solo tiene sentido en este proyecto?**
   → `scripts/<sistema>/` (autoloads, managers, glue, helpers).
5. **¿Script que define una clase `Resource`?** → `resources/<dominio>/<clase>.gd`.
   La **instancia** `.tres` va donde se use.
6. **¿`.tres` que hace de base de datos/registro?** → `databases/`.
7. **¿Asset compartido?** → `assets/<audio|fonts|images|particles|tilesets>/`.
   Si solo lo usa un contenido, va dentro de ese contenido.
8. **¿Shader compartido?** → `shaders/`; si es de un contenido o escena, con
   ellos.
9. **¿Prueba o experimento?** → `tests/` (nunca se sube).
10. **¿Duda entre `components/` y `scripts/`?** Si se puede llevar a otro proyecto
    sin arrastrar nada de este, `components/`; si depende de autoloads, clases o
    contenido de este proyecto, `scripts/`.

### Reglas de `content/`

- Estructura obligatoria: `content/<tipo>/<nombre>/`. El **tipo** en plural y
  snake_case (`entities`, `machines`, `objects`, `potions`, `potion_effects`);
  el **nombre** en snake_case y descriptivo (`player`, `slime`,
  `potions_mixer`).
- Todo lo del contenido vive en su carpeta, aunque sea de distinto tipo:
  escena, script, `.aseprite`, PNG, sonidos, estados y subcarpetas por función
  (`ui/`, `explosion/`, `states/`, `sounds/`).
- No dejes archivos sueltos en `content/<tipo>/` ni carpetas de contenido vacías.
  La única excepción es una clase base compartida por todo el tipo
  (`content/entities/entity.gd`).
- Si dudas entre crear un tipo nuevo y reutilizar uno, reutiliza el tipo
  existente. Crear un tipo nuevo es una decisión de estructura: pregunta.

### Reglas de `scenes/`

- Estructura: `scenes/<escena>/<contenido-de-la-escena>`.
- Solo pantallas, menús, carga, pausa y flujo del juego. Un personaje, enemigo,
  máquina u objeto **no** va aquí: va en `content/`.
- Lo que solo usa esa escena se queda en su carpeta. Si un botón o widget se usa
  en varias, súbelo a `components/` (reutilizable entre proyectos) o a `themes/`
  (tema compartido).

### `components/` y LibraryManager

- Cada librería es `components/<libreria>/` con su código, escenas, resources y
  un `dependencies.txt` (una dependencia local o URL de GitHub por línea).
- La IA puede escribir aquí solo si el código es realmente genérico: sin
  referencias a `content/`, a autoloads ni a clases del juego.
- No escribas en `~/Documents/GodotLibraries`: se publica con «Push to storage»
  desde el editor. Al terminar, avisa al usuario de que debe hacerlo.
- «Update from storage» **sobrescribe** `components/`: haz push de los cambios
  locales antes. No borres carpetas a mano; usa LibraryManager.

### Resources, databases, assets, shaders y themes

- **Resource (clase):** `resources/<dominio>/<clase>.gd`, con `class_name`,
  `extends Resource` y exports tipados.
- **Resource (instancia):** donde se use. Si es de un contenido, dentro de su
  carpeta; si lo comparten varios, en `resources/` o en el ancestro común.
- **Database:** `.tres` en `databases/`. No añadas autoloads nuevos sin pedirlo.
- **Assets:** compartidos en `assets/`; los de un solo contenido, dentro del
  contenido. Un PNG de un enemigo no va en `assets/images/`.
- **Shaders:** compartidos en `shaders/`; los de un contenido, con él.
- **Themes:** compartidos en `themes/`; el de una sola escena puede vivir en su
  carpeta.

### Nombres

| Elemento | Convención | Ejemplo |
| --- | --- | --- |
| Carpeta de contenido | snake_case | `potion_effects` |
| Script | snake_case | `potion_data.gd` |
| `class_name` | PascalCase | `PotionData` |
| Función / variable | snake_case | `_update_data` |
| Constante | SCREAMING_SNAKE_CASE | `MAX_SPEED` |
| Señal | snake_case, preferible en pasado | `died` |
| Enum | PascalCase; valores UPPER_SNAKE_CASE | `State.IDLE` |
| Escena | snake_case y repetir el nombre de la carpeta | `welcome/welcome.tscn` |

### Qué no hacer con la estructura

- Meter assets de un contenido en `assets/`.
- Meter scripts de un contenido en `scripts/` si son exclusivos de ese contenido.
- Meter personajes en `scenes/`.
- Meter instancias `.tres` de contenido en `resources/` por costumbre.
- Editar `addons/` o `script_templates/`.
- Commitear `tests/`, `.godot/`, builds ni credenciales.
- Reestructurar un proyecto existente sin pedirlo.

## Worktrees de Git

Los worktrees permiten tener varias ramas del repositorio abiertas a la vez, cada
una en su propia carpeta, compartiendo el mismo `.git`. Úsalos cuando haya que
trabajar en **módulos distintos en paralelo** sin mezclar cambios ni bloquearse.

### Cuándo usarlos

- Varios agentes (o varias sesiones) trabajando a la vez en módulos diferentes.
- Una tarea larga en un módulo mientras en `main` se siguen haciendo cambios.
- Probar una refactorización o un experimento sin ensuciar el árbol principal.
- Comparar dos implementaciones de la misma funcionalidad.

**No** hace falta worktree para un cambio pequeño, un fix puntual, documentación
o cualquier cosa que se termine en una sola sesión y no toque otros módulos.

### Convención de carpetas y ramas

La convención de ramas del repositorio es **`main` → `features` → `<modulo>`**:

```
main                  # estable; solo recibe integraciones validadas
└── features          # rama de integración del trabajo en curso
    ├── player        # rama de módulo
    ├── inventory     # rama de módulo
    └── ...
```

- Las ramas de módulo **salen siempre de `features`**, nunca directamente de
  `main`.
- El trabajo de cada módulo se integra primero en `features`. Cuando el conjunto
  está validado, `features` se fusiona en `main`.
- **`main` y `features` no se tocan directamente.** Nadie commitea ni hace push
  sobre ellas: todo cambio entra exclusivamente mediante **Pull Request**.
- Los worktrees van **fuera del repositorio**, como hermanos de la raíz, para que
  Godot no los importe como parte del proyecto:
  `../MindSpace-worktrees/<modulo>`.
- Una rama de módulo por worktree, con el mismo nombre que el módulo
  (`player`, `inventory`, `combat`…).
- Un worktree = un módulo. No metas dos módulos independientes en el mismo.

```bash
# Desde la raíz del repositorio
git fetch
git switch features
git pull

mkdir -p ../MindSpace-worktrees
git worktree add ../MindSpace-worktrees/player -b player
```

Si `features` todavía no existe, créala desde `main` actualizado antes de sacar
ninguna rama de módulo:

```bash
git switch main && git pull
git switch -c features
git push -u origin features
```

El worktree aparece como una carpeta normal. El proyecto Godot se abre desde
`<worktree>/game`, que es donde está `project.godot`.

### Reglas dentro del worktree

1. Antes de empezar, asegúrate de que la rama de módulo sale de `features` al
   día (`git fetch && git switch features && git pull`).
2. Abre el proyecto **desde la ruta del worktree**. Cada worktree genera su
   propio `.godot/`; no compartas ni enlaces esa carpeta entre worktrees.
3. Sincroniza a menudo con `features` (`git rebase features`) para evitar
   conflictos grandes, sobre todo si el cambio toca escenas, `.uid` o recursos
   compartidos.
4. Valida el módulo **en su worktree** antes de integrarlo: que el proyecto
   arranque sin `ERROR`/`SCRIPT ERROR` y que las escenas y scripts del módulo
   carguen.
5. Al terminar, haz commit en la rama de módulo y súbela
   (`git push -u origin <modulo>`). La rama de módulo se integra en `features`;
   `features` se integra en `main` cuando el trabajo está validado. No dejes el
   worktree abierto indefinidamente ni fusiones un módulo directamente en `main`.
6. No compartas un worktree entre dos agentes ni trabajes dos ramas en la misma
   carpeta.
7. No toques escenas ni archivos de otro módulo. Si una prueba necesita una
   escena compartida, trabaja sobre una copia (ver más abajo).

### Escenas: no tocar las de otros módulos

Cada módulo es dueño de sus propias escenas. Las escenas compartidas (menús,
pantallas de flujo, `scenes/` común, o cualquier `.tscn` que use más de un
módulo) no se editan directamente: un cambio en una escena compartida afecta a
todo el mundo y genera conflictos difíciles de resolver.

- **No modifiques escenas de otro módulo.** Si una IA trabaja en `player`, no
  puede editar escenas de `inventory`, `combat` u otro módulo.
- **No edites directamente una escena compartida.** Si necesitas probar algo que
  implica cambiarla, haz una **copia aparte** y trabaja sobre la copia.
- Las copias de prueba van en `tests/` (ignorada por Git) o en la carpeta del
  módulo con un sufijo claro (`mi_escena_test.tscn`). No las commitees ni las
  referencies desde producción.
- Al copiar una escena, elimina su `uid` o genera uno nuevo: dos recursos con el
  mismo `uid` rompen el proyecto.
- Si el cambio en la escena compartida es realmente necesario, **no lo hagas por
  tu cuenta**: párate y pídelo al usuario. Ese cambio va en su propia rama y su
  propio Pull Request, separado del trabajo del módulo.

### Flujo de integración

1. `features` se actualiza desde `main`.
2. Cada módulo sale de `features` y se trabaja en su worktree, tocando solo sus
   propias escenas y archivos.
3. Al terminar, la rama del módulo se integra en `features` **mediante Pull
   Request**, tras validar que el proyecto arranca.
4. Cuando el conjunto de módulos de `features` está estable, se integra en
   `main` **mediante Pull Request**.
5. Se eliminan las ramas de módulo y sus worktrees ya integrados.

### Con OpenCode

Si el entorno ofrece las herramientas de worktree de OpenCode, úsalas en lugar
de crear carpetas a mano:

- `tools.opencode.worktree_create` — crea el worktree y devuelve su ruta.
- `tools.opencode.worktree_list` — lista los worktrees existentes.
- `tools.opencode.worktree_remove` — elimina uno cuando ya no se necesita.

Tras crear uno, mueve la sesión a esa carpeta con `tools.opencode.session_move`
para que todos los comandos se ejecuten allí. Si esas herramientas no están
disponibles, usa `git worktree` directamente.

### Listar y limpiar

```bash
git worktree list                 # worktrees activos
git worktree remove <ruta>        # eliminar uno (cerrar Godot antes)
git worktree prune                # limpiar referencias huérfanas
```

- Cierra Godot antes de borrar un worktree.
- No borres a mano la carpeta ni el contenido de `.git/worktrees/`; usa los
  comandos de Git.
- Si un worktree tiene cambios sin commitear, Git se negará a eliminarlo. Decide
  con el usuario si se conservan, se commitean o se descartan; no fuerces la
  eliminación sin permiso.

### Qué no hacer

- Sacar ramas de módulo de `main` o fusionarlas directamente en `main`: el paso
  intermedio es siempre `features`.
- Commitear, hacer push o fusionar directamente en `main` o en `features`: solo
  se entra mediante Pull Request.
- Modificar escenas de otro módulo o editar directamente una escena compartida.
  Para probar, usa una copia en `tests/` o con sufijo `_test`.
- Copiar o mover la carpeta de un worktree **dentro** del repositorio principal.
- Versionar `.godot/`, builds o la carpeta de worktrees.
- Duplicar `.uid` al copiar escenas entre worktrees: cada recurso necesita su
  propio `uid`.
- Dejar worktrees y ramas temporales acumulándose sin integrar ni limpiar.

## Godot MCP Toolkit (opcional)

El proyecto incluye el addon **Godot MCP Toolkit** en
`game/addons/godot_mcp_toolkit/`. Su servidor MCP está configurado **solo para
este proyecto** en `.opencode/opencode.jsonc`, no en la configuración global de
OpenCode.

El MCP conecta al **editor de Godot en marcha** y expone herramientas para
escenas, nodos, scripts, resources, playtests y depuración. **No es obligatorio**:
la IA puede trabajar con los ficheros del repositorio, `git`, el checker de
GDScript y Godot en headless. Úsalo cuando la alternativa por archivos sea
frágil, lenta o directamente imposible, no por defecto.

### Requisitos

- Godot 4.2+ (el proyecto usa 4.7) y **Node.js 22+**.
- El addon activado en **Project Settings → Plugins → Godot MCP Toolkit**.
- El editor abierto en el proyecto (`game/` o `<worktree>/game`).
- La configuración del cliente ya está escrita en `.opencode/opencode.jsonc`.
  El propio addon también genera `game/.mcp.json` para otros clientes.

Comprueba la conexión:

```bash
opencode mcp list
```

En el editor debe aparecer `[MCPServer] listening on 127.0.0.1:6550` (el puerto
puede variar entre 6550 y 6560).

### Cuándo usarlo

Úsalo principalmente para lo que no se puede hacer bien sin él:

- **Playtests reales:** arrancar y parar el juego, leer el estado de nodos en
  vivo, simular input, leer logs y sacar capturas del editor o del juego.
- **Depuración:** breakpoints, stepping, estado de depuración y diagnóstico de
  crashes desde el buffer de errores del editor.
- **Autoría que no es texto plano:** TileMap/TileSet, animaciones con
  `AnimationPlayer`/`AnimationTree`, `SpriteFrames`, temas, curvas `Path2D`,
  primitivas 3D, luces, cámaras, partículas y navegación.
- **Escenas y nodos:** crear, abrir, reparentar nodos, leer/escribir propiedades y
  obtener un mapa espacial, en lugar de editar `.tscn` a mano.
- **Servicios de lenguaje GDScript:** diagnósticos del LSP, símbolos, ir a
  definición, referencias, hover y escaneo de errores del proyecto.
- **Assets y project settings:** importar binarios, trazar dependencias, editar
  el input map, autoloads y ajustes del proyecto.
- **ClassDB:** consultar clases y propiedades reales del motor.

### Cuándo NO usarlo

- Para leer o editar `.gd`, documentación, `git` o la estructura de carpetas: usa
  las herramientas de archivos normales.
- Para cambios pequeños y deterministas en texto.
- Si el editor no está abierto o el plugin no está activo: no bloquees la tarea,
  cae al flujo por archivos y headless.
- Para saltarte las reglas del repositorio (tipado, PRs, propiedad de escenas).

### Reglas de uso

1. **Necesita el editor abierto.** Si no hay conexión, no insistas: trabaja con
   ficheros y valida con Godot headless.
2. **Un editor por worktree.** Cada worktree tiene su propia instancia; conecta
   la que corresponda al módulo. No mezcles editores de módulos distintos.
3. **No cambia las reglas de escenas.** No edites escenas de otro módulo ni
   escenas compartidas por MCP. Si hay que probar, copia la escena a `tests/` o
   con sufijo `_test`. El MCP no es una excepción.
4. **Tampoco salta el tipado.** Las herramientas de escritura de código deben
   producir GDScript con todos los tipos explícitos, igual que a mano.
5. **Revisa lo que muta.** Tras una llamada que modifica el proyecto, mira
   `git status` y `git diff`. No commitees `.godot/`.
6. **Prefiere leer antes que escribir.** Usa las herramientas de inspección y
   validación del MCP para comprobar el estado antes de mutar.
7. **Modo solo lectura si solo inspeccionas:** añade `GODOT_MCP_READ_ONLY=1` al
   `environment` de `.opencode/opencode.jsonc` para ocultar todas las
   herramientas que mutan.
8. **No uses `execute_code` para rodear estas reglas.** Si una operación no cabe
   en el flujo permitido, para y pregunta.

### Si el MCP no conecta

1. Comprueba que el editor está abierto con el proyecto y el plugin activo.
2. `node --version` debe ser 22 o superior.
3. Ejecuta `opencode mcp list` y revisa el estado del servidor.
4. Si el bridge no encuentra el editor, abre OpenCode desde `game/` (la carpeta
   del `project.godot`) o ajusta el `cwd` del servidor en
   `.opencode/opencode.jsonc`.
5. Si nada funciona, sigue sin él: los ficheros, el checker y Godot headless
   siguen siendo la vía principal.

## GDScript: tipado obligatorio

**Todas las variables se tipan de forma explícita, absolutamente todas, aunque el
valor parezca obvio.** No se confía en la inferencia del compilador ni en que
«se vea claro» por el literal.

Esto incluye:

- Variables locales, variables de clase y variables de bucle (`for item: ItemData in items:`).
- Constantes (`const MAX: int = 3`).
- Parámetros y valores de retorno (`func f(a: int, b: float) -> bool:`), incluido
  `-> void` cuando no devuelve nada.
- Señales (`signal died(who: Node2D)`).
- Variables `@export` y `@onready`.
- Arrays y diccionarios, con genéricos (`Array[ItemData]`,
  `Dictionary[StringName, int]`).
- Lambdas y `Callable`.

Reglas concretas:

- **Prohibido `:=`.** También `var x = ...` y `const X = ...` sin tipo explícito.
- `@export var speed: float = 1.0`, nunca `@export var speed = 1`.
- `@onready var sprite: Sprite2D = $Sprite2D`; mejor todavía `@export` cableado
  en la escena.
- `Variant` solo en la frontera (`JSON`, `Expression`, `await`, `get_meta`,
  APIs dinámicas). Se valida y se castea de inmediato; no se propaga por el
  código.
- GDScript 4.7 no soporta colecciones tipadas anidadas:
  `Dictionary[StringName, Array[int]]` no compila.

| Mal | Bien |
| --- | --- |
| `var speed = 10.0` / `var speed := 10.0` | `var speed: float = 10.0` |
| `const MAX = 3` / `const MAX := 3` | `const MAX: int = 3` |
| `func f(a, b):` | `func f(a: int, b: float) -> bool:` |
| `func _ready():` | `func _ready() -> void:` |
| `signal died(who)` | `signal died(who: Node2D)` |
| `var items: Array = []` | `var items: Array[ItemData] = []` |
| `for item in items:` | `for item: ItemData in items:` |

El proyecto debe tener activados los avisos de modo estricto en `project.godot`:

```ini
gdscript/warnings/untyped_declaration=2
gdscript/warnings/inferred_declaration=2
```

Si faltan, avisa al usuario antes de añadirlos. El código nuevo y el que se
modifique debe cumplir esta regla; no reescribas archivos ajenos al cambio solo
para tiparlos.

Valida siempre con el checker, en modo estricto:

```bash
bash ~/.config/opencode/skills/godot/scripts/check-gdscript.sh -p game --strict
```

