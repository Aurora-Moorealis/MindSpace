# Codebase Details Brainstorm Report — Junior Astronaut Mission Trainer

Mode: BRAINSTORM. Concept file `.egm/brainstorm-input.md`. Repo verificado (`game/`): solo `project.godot` (850×480, avisos estrictos), `icon.svg` por defecto y `addons/godot_mcp_toolkit/`. Sin assets, content, scenes, scripts ni databases. Dos datos que el concepto no conocía: `[autoload] MCPRuntimeServer` (escucha TCP localhost, se exporta con el juego) y `[editor_plugins] res://.godot/scenetime/plugin.cfg` (plugin local en `.godot/`, ignorado por git e invisible para los compañeros).
Nota: los revisores no tuvieron herramienta de escritura; este archivo conserva el reporte tal como se recibió.

## Blocker

### B1. The validation feature has no spec
"Investigar la estructura del planeta" requires an outdoor lunar map beyond the 5-room base, plus scanning tools and a report loop — a second content world with zero objectives, zero tools, zero step counts. Two games; cut now to a 3-item checklist (measure N rocks, collect M samples, send K reports) with one tool and one interactable type.

### B2. Repo git rules vs. 36h 3-person jam
`main`/`features` untouchable, module branches off `features`, integration only by PR, one module per worktree, no touching other modules' scenes. But this game is essentially **one shared scene** (base map, HUD, main flow). Three people + PR-only + `.tscn`/`.uid` merge conflicts + a beginner = the opposite of jam throughput. Requires a decision: jam exception (single shared branch, direct pushes) or strict file-ownership + one integrator. Unresolved, burns the first day.

### B3. "Test numbers first, NASA later" is a false assumption
Substitution is cheap **only if the trial schema already matches the real one**: units, event keys, timestamps, provenance fields (`source` label, dataset/product ID, `archived` flag). If the day-one JSON omits provenance columns, every consumer (event UI, source label, evaluation screen) is rewritten late — exactly when time is gone. The brief also demands **NTRS citations** for life-support numbers: a second provenance type that must live in the same schema. Related: `AGENTS.md` defines **no folder for raw datasets** (`databases/` is for `.tres` registries); decide where dataset JSON lives before files land.

## Major

### M1. New autoloads require permission
The concept implies at least four singletons (time/clock, resource simulation, event scheduler, mission state), all classic autoloads. `AGENTS.md`: "No añadas autoloads nuevos sin pedirlo." Ask once up front, or bypass with scene-root singletons.

### M2. Evaluation screen has no data source
"Evaluación final de qué se hizo bien o mal" requires a retrospective — an action/event ledger recorded from day one (death causes, repairs, upgrades, samples sent, radiation peaks, resource troughs). Retrofitting is a rewrite of every system. Specify now: one autoload `EventLog`, mandatory `log(type, payload)` in machines/events/mission. Doubles as the debug/trace surface.

### M3. Nobody can watch a 5-hour mission
Decide now: time-warp presets (×1/×8/×60 via a single clock tick, **not** `Engine.time_scale`) plus a scripted demo-jump that fast-forwards state to a near-end scenario. Also unstated: with a 24 h clock and a solar panel, **does energy output follow day/night?** If yes, every event must be phase-aware and a demo jump must set a sane phase.

### M4. Machine/upgrade content is undefined and has no architecture
Fine **only** if the architecture is generic now: one `content/machines/machine.gd` base (interaction, slots, upgrade tables), per-machine folders, all variations described by a `Resource` + `databases/` registry. Otherwise each machine becomes bespoke code the beginner can't touch.

### M5. Editor-local plugin trap
`res://.godot/scenetime/plugin.cfg` (SceneTime) is enabled on this machine's local `.godot/`, gitignored. Intro/landing/tutorial animations are exactly what would tempt using it — any scene saved with SceneTime nodes **breaks for the other teammates and in exports**. Either distribute the plugin properly or forbid its use. Also disable `MCPRuntimeServer` (Autoload) in the release build so the demo doesn't ship a localhost TCP listener.

### M6. Staffing vs. hard repo typing rules
Two of three contributors have zero programming or Godot experience, and the repo mandates typed GDScript without inference, zero typing shortcuts, plus English code comments. "Usarán IA" hand-waves this. Plan: **all `.gd` files are DevGreem's**, Ramerlin owns `.tscn` layout/themes (typed scaffolds provided), validation via checker on every commit.

### M7. No art plan
Content demand: 32×32 tileset for 5 rooms **plus** outdoor lunar map, astronaut sprite frames, Aurora, UI. Exactly one contributor exists for it (Mijael, 2.5/5), and the concept has zero art sourcing (OpenGameArt/Kenney cc0 packs, AssetLib, or outsourcing the base tileset). Art is the long pole of any jam.

### M8. Rubric unknown governs prioritization
The 8 judging categories are the objective function but are listed only as an open point. Fetch the official rubric now; the NASA-data categories make B3 and the provenance UI mandatory regardless of any other choice.

## Nit

- N1 — 850×480 vs 32 px tiles: 850/32 ≈ 26.56. Decide camera snap/zoom policy when the map lands.
- N2 — `icon.svg` is the Godot default; zero-cost fix, irrelevant to judging.
- N3 — "dosis RAD": pin actual dataset products in the schema (DONKI CME/FLR/SEP product IDs; lunar surface dose via LRO **CRaTER**, not MSL/RAD which is Mars).
- N4 — Random astronaut stats: dead code with one fixed astronaut; cut for v1.
- N5 — "Traje (tipo)" listed as visible stat but suit types never defined; define 2 suits or drop the stat.
- N6 — No persistence: "perder = empezar de 0" makes saves unnecessary — correct; but a mid-demo crash loses everything. Skip save files; consider only a debug state-dump.
- N7 — README "Controls" table TODO: trivial, outside the build.

**Engine mapping sanity:** data-driven events as JSON→`Resource` (clean); `CharacterBody2D` + `Area2D` (clean); intro/landing/Aurora via `AnimationPlayer` (clean); time speed via one custom clock (clean, avoids physics drift); TileMapLayer/TileSet 32 px (clean); typed-strict GDScript under two beginners and PR-only `.tscn` merging (fights the engine/team). No addon offers gameplay reuse; the only reusable dev asset is the MCP Toolkit (plus unused editor-local SceneTime — a trap, not an asset).

## Bottom line

The singleplayer-survival premise is a good Godot fit and the repo is truly greenfield, but the concept sends 3 people into 36 hours with the only judge-validating feature (the lunar exploration mission) unspecified, a PR-based multi-module git workflow that fits modules but not one shared jam project, and a "fake now, real later" plan that only works if the data schema and provenance UI are designed today. Before any build: the mission as a 3-step checklist, a source-labeled data schema with an agreed dataset folder, a jam exception to branch/PR rules (or explicit file ownership), permission for the needed autoloads, a generic data-driven machine architecture, a day-one event ledger feeding both debugging and the final evaluation, and a judge-facing demo jump/time-warp — with art assignment as the silent schedule killer behind all of it.
