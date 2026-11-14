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

- Los worktrees van **fuera del repositorio**, como hermanos de la raíz, para que
  Godot no los importe como parte del proyecto:
  `../MindSpace-worktrees/<modulo>`.
- Una rama por worktree, creada desde `main` actualizado. Nombres:
  `feat/<modulo>`, `fix/<modulo>`, `refactor/<modulo>`.
- Un worktree = un módulo. No metas dos módulos independientes en el mismo.

```bash
# Desde la raíz del repositorio
mkdir -p ../MindSpace-worktrees
git worktree add ../MindSpace-worktrees/player -b feat/player
```

El worktree aparece como una carpeta normal: se abre con Godot desde ahí y se
trabaja como en el repo principal.

### Reglas dentro del worktree

1. Antes de empezar, asegúrate de que la rama sale de `main` al día
   (`git fetch && git switch main && git pull`).
2. Abre el proyecto **desde la ruta del worktree**. Cada worktree genera su
   propio `.godot/`; no compartas ni enlaces esa carpeta entre worktrees.
3. Sincroniza a menudo con `main` (`git rebase main`) para evitar conflictos
   grandes, sobre todo si el cambio toca escenas, `.uid` o recursos compartidos.
4. Valida el módulo **en su worktree** antes de integrarlo: que el proyecto
   arranque sin `ERROR`/`SCRIPT ERROR` y que las escenas y scripts del módulo
   carguen.
5. Al terminar, haz commit en la rama y súbela (`git push -u origin <rama>`).
   La integración en `main` se hace con merge o pull request, no dejando el
   worktree abierto indefinidamente.
6. No compartas un worktree entre dos agentes ni trabajes dos ramas en la misma
   carpeta.

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

- Copiar o mover la carpeta de un worktree **dentro** del repositorio principal.
- Versionar `.godot/`, builds o la carpeta de worktrees.
- Duplicar `.uid` al copiar escenas entre worktrees: cada recurso necesita su
  propio `uid`.
- Dejar worktrees y ramas temporales acumulándose sin integrar ni limpiar.
