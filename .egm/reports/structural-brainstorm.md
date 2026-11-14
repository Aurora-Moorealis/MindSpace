# Structural Brainstorm Report — Junior Astronaut Mission Trainer

Mode: BRAINSTORM. Concept file `.egm/brainstorm-input.md`.
Nota: los revisores no tuvieron herramienta de escritura; este archivo conserva el reporte tal como se recibió.

## Blocker

### B1 — No module/scene ownership plan under the repo's own rules
AGENTS.md enforces `main → features → <módulo>` worktrees plus a ban on touching another module's scenes or shared scenes directly. The concept assigns roles (DevGreem=logic, Ramerlin=UI, Mijael=unassigned) but maps nothing to modules, branches, or scene ownership. This game is essentially one shared scene: the base map, HUD and main flow everyone touches. Starting without an ownership map means the first shared scene either dev touches (HUD, main menu) is a rule violation in waiting.
Requirement: a module decomposition table (e.g., core, base/machines, ui, events) with an owner per module, plus an explicit shortlist of shared scenes and who may edit them; worktrees created from this table before any code. Also state where Mijael may touch files.

### B2 — "Puntos abiertos" is a list of topics, not decisions
Six bullets, each unbounded, no default values, no owners, no freeze deadlines, no milestone budget. "Tratarlos como supuestos" is not executable without writing the assumptions. No milestone table (what must exist at hour 6/12/24). Worst: the known risk in "Tiempo" (a judge won't see the ~5h full game) has an implied mitigation ("velocidad alta o salto de demostración") that is not defined anywhere — the one mechanism that rescues the demo does not exist as a spec item.
Requirement: convert each open point to `{decision, default value, owner, freeze hour, code location}`; include a milestone table with hour budget; define the time-control/demo-skip mechanism as a first-class feature.

### B3 — The main mission's arena is absent from the described content structure
Only the 5 interior rooms are structurally described. There is no exterior map: size, boundaries, room-to-exterior transition, placement of scan targets. "EVAs" appear exactly once as a radiation coupling and are never defined (is being outside always an EVA? dose rates?). The victory trigger is not a number anywhere.
Requirement: define the exterior as an explicit sixth content area (size, POI count, transitions, EVA radiation rule) and fix a provisional concrete victory trigger (N samples/informes) so code can be typed against it.

## Major

### M1 — Scope statements are duplicated and free to drift
"Objetivos vs. no-objetivos" vs "Astronauta" ("fuera del alcance actual"), "Base" (stretch goals), "Fuera del alcance v1" ("decidir después"). Two sources of truth for scope; one edit silently contradicts the other.
Requirement: every scope sentence migrates to a single scope table; detail sections may reference it but not restate it.

### M2 — Resolution/tile grid mismatch: 850×480 with 32×32 tiles
850/32 = 26.5625. Non-integer tile width (480/32 = 15 exact). Camera clamping, room layouts, and pixel-perfect art inherit a half-tile problem from minute one.
Requirement: decide and write the real window size (832×480 = 26×15, or another multiple) before any asset exists.

### M3 — Oxygen and energy are split across three entities with no model
The hypothesis calls O₂ an astronaut stat, "Astronauta" calls it a machine stat ("máquina de O₂"), "Recursos" has base-stored oxygen. One word, three entities, no transformation rules. Same for energy: generator "no genera, distribuye" + exterior solar panel + storage, and the "1 min = 1 hora / 1 sol" clock implies a 24-minute day/night cycle nowhere connected to solar generation or event timing.
Requirement: one resource-flow table (source → storage → consumer, units, base rates) plus a written day/night rule.

### M4 — No screen/UI-layer inventory anywhere
HUD layout, selector, intro, landing, tutorial, submisión dialog, evaluation screen exist only as narrative steps. "Almacenar objetos" in the Dormitorio implies an inventory with no UI. The dedicated UI person has no screen list to work from.
Requirement: a screen/state list (name, candidate scene path, owner, transitions) — the UI contract.

### M5 — The event system is scattered across three sections and structurally hollow
No event list, no per-event effects, no frequency. The DONKI-storm idea lives inside the submisiones bullet. "Polvo" and "temperaturas" are named as event sources with no NASA source stated at all, breaking the brief's own sourcing requirement.
Requirement: one data-driven event schema (`id, source (NTRS/DONKI/RAD), archived flag, trigger, effect, provenance UI string`), every declared event type mapped to a named source.

### M6 — Submisiones are unanchored
The mechanic gates the post-tutorial flow and pays a (undefined) funding currency. A beginner cannot implement a submisión trigger from this doc.
Requirement: freeze one submisión as the template (content, trigger, reward); define the financing → resources exchange.

### M7 — The single-author summary paragraph promises more than the details define
The run-on 5-line sentence reads like a finished pitch while details say mission objectives are "no definidos", economy undefined, submisiones undefined, "3 opciones aleatorias" with only one implemented. Anyone reading the summary as spec plans against features that don't exist.
Requirement: rewrite the summary to state exactly what exists at v1, with explicit TBD markers, in short bullets.

## Nit

- N1 — "Recursos" H3 is a one-line duplicate of the hypothesis resource list; fold into the resource model (M3).
- N2 — "Eventos lunares" H3 is an empty stub with three other homes; merge into M5's event section.
- N3 — Flow steps 2–3 (intro and landing cinematics) have no length or asset budget; give each a time cap in the brief.
- N4 — Greenhouse has per-plant machines plus shared upgrades with no plant-count bound; fix a v1 count or the room's scope is unbounded.
- N5 — No feature maps to a repo folder; pre-write paths (`content/entities/astronaut/`, `scenes/welcome/`, `databases/events.tres`…) so the beginner never interprets AGENTS.md folder rules mid-jam.
- N6 — Mijael has no assigned area; one line in the roles table fixes it.
- N7 — Recorded decision: document language is Spanish, matches the team; code comments stay English.

## Bottom line

The concept file is accurate as minutes but unusable as a working spec. The brief must be a structural derivative, not a copy: a single scope table (source of truth), a module/scene-ownership table reconciled with the worktree and shared-scene rules (blocks day-one setup), a resource-flow model resolving the O₂/energy ambiguity and the day/night coupling, a screen/state list as the UI contract, a data-driven event schema with a named NASA source per event type, and an open-points table where every open point carries a default value, an owner, and a freeze hour. Every item the details cannot back — victory trigger, submisión content, exterior map, time-control mechanism — must gain at least a provisional concrete number, and the summary paragraph must shrink to match reality.
