# AGENTS.md

Guía para agentes que trabajen en **MindSpace** (proyecto Godot 4.x). Todo lo que
haya aquí es específico de este repositorio y complementa las convenciones
globales. Si algo choca con una instrucción directa del usuario, manda el usuario.

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

El worktree aparece como una carpeta normal: se abre con Godot desde ahí y se
trabaja como en el repo principal.

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
