# Zoom-Out Brainstorm Report — Junior Astronaut Mission Trainer

Lens: skeptical architect / YAGNI. Mode: BRAINSTORM. Concept file `.egm/brainstorm-input.md`.
Nota: los revisores no tuvieron herramienta de escritura; este archivo conserva el reporte tal como se recibió.

## BLOCKERS

### B1. Open-world exploration is an unscoped second game bolted onto a life-support sim
The brief asks for a game about balancing resources, *not* exploration. The concept admits the mission is undefined yet lists it as mandatory: outdoor lunar map, scanner/sample tool, rock/mineral props, report flow — 8–10 hours for the part of the game a judge is least likely to see (behind tutorial + 5-room onboarding).
Alternative: delete the field map. The "mission" becomes: survive N sols and send M science reports **from the comms room** via a single interactable console. The report send doubles as the DONKI/provenance display surface (real data cards), serving two rubric items at once.

### B2. Five resources + six visible stats vs. the brief's advice of 2–3 core resources
The official brief says pick 2–3 core resources. The concept ships O₂, water, food, energy, radiation **plus** health, suit type, hunger %, thirst %, radiation. A 5-way coupled balance cannot stabilize in the last 36h — and balance is precisely the thing being judged.
Alternative: three resources: **power**, **O₂**, **radiation**. Delete food/water, hunger, thirst. Food was the shakiest anyway because the brief admits no NASA life-support dataset exists.

### B3. No planning anchor: the 8-category rubric is not in the document, and no time budget exists for ~50–60 person-hours of features
The whole scope (intro animation, mascot tutorial, endless mode) implicitly bets that polish/story categories matter. The rubric is public; the team must read it before locking scope.
Alternative: spend the first hour extracting the rubric + challenge criteria into this document. Write the scope as "rubric line → feature → hours". Do not pre-buy polish on speculation.

## MAJOR

### M1. Intro mini-story animation + landing animation
Two cinematics by a team whose animation strength is ~zero. Highest cost-per-rubric-point item in a jam. Judges skip intros; children skip intros.
Alternative: one static title screen + 2–3 lines of text. Zero frames to draw.

### M2. Guided tutorial by walking mascot "Aurora"
Requires mascot sprites (walking animation), pathing through 5 rooms, per-machine dialogue, gating of events/missions during the tour — 4–6 hours and it delays the moment a judge sees the actual game.
Alternative: Aurora as a **portrait on modal hint pop-ups** (3 hints max: "watch O₂", "shelter when radiation spikes", "repair at the panel"). All animation cost deleted.

### M3. Funding economy + 4 optional sub-missions
Funding is a **second economy** stacked on a 3–5 resource simulation. "No perder partida por no hacerlas" means they're skippable content a judge may never trigger. The 5 proposed ideas are actually scripted incidents, not economy-protected content.
Alternative: cut funding entirely. Reframe the ideas as the fixed campaign's 4–6 scripted incidents that fire on schedule. The economy layer, its UI, and its balance risk are deleted.

### M4. Hidden stats + random astronaut stats
Features built now for an explicitly out-of-scope future (multiple astronauts). Hidden stats need modifying anyway; there are no upgrades yet to modify them.
Alternative: delete. v1 exposed stats: O₂, power, radiation, health (derived).

### M5. Five separate rooms incl. a "mayormente decorativo" dormitory and a dedicated construction room
Five rooms means five interiors drawn by an artist who is simultaneously the UI person. "Mayormente decorativo" is the author flagging scope that earns nothing.
Alternative: four rooms max: **greenhouse** (O₂), **energy shed + outdoor solar panel** (power), **comms** (reports, data cards), **hab** (bed, storage chest, machines). Repair/upgrade via the machine's own panel — one interaction model everywhere.

### M6. Planet selector + 3 random mission options (only Moon, only one implemented)
A selector whose options don't exist is dead UI in the demo. Random mission options mean designing what varies — pure extra scope.
Alternative: "New Game" → one fixed 3-sol campaign. No selector screen.

### M7. Team/process risk: strict typed GDScript + beginner UI code + PR-only merges
Strict untyped/inferred warnings are enabled; Ramerlin (no Godot) will write UI scripts → failing checker, blocked merges, DevGreem fixing other people's types. PR-gated branches add merge latency.
Alternative: beginner authors scenes/resources through the editor + Godot MCP (already available); DevGreem owns every `.gd` until hour ~20; nightly merge cadence.

## NIT

- N1. Endless mode after victory: near-zero build cost only if the sim is event-driven; otherwise an empty husk in the demo. Silent cut; if it survives to hour 32, ship a boring continuation, not new content.
- N2. Suit type and "O₂ machine" as separate visible stats duplicate what shield level and O₂ capacity already express. One number per resource.
- N3. Temperature and dust events: temperature has no natural counterplay a child understands; dust's only natural home is panel-cover → power down. Keep two real event classes: DONKI spikes (shelter + shield) and panel-cover (clean/repair). Temperature: display-only with NTRS citation.
- N4. Placeholder numbers first, swap "al final" — inverted. The JSON schema must carry `source`, `source_url`, `date_archived`, `archived: true` fields **from hour 1**; provenance UI is a day-2 deliverable; real values are pasted in as 20 minutes of work the moment they're downloaded.
- N5. Viewport numerology: 850×480 with 32×32 tiles → 26.56 tiles wide. Decide day 1: 864×480 (27×15 exact) or accept 850 with camera smoothing. Free now, expensive later.

## Reuse opportunities (codebase verified)

- **The repo is empty.** No components, scripts, scenes or databases to reuse. Do not invent shared abstractions; write the simplest single-campaign scripts directly under `content/` + `scenes/`.
- **Do not install LimboAI** (mentioned in AGENTS.md but not present). A 3-state enum machine suffices.
- **Godot MCP Toolkit is installed** — use it to descend the artist's learning curve (TileMap/TileSet painting, scene wiring) instead of hand-editing `.tscn`.
- **DONKI/RAD data:** DONKI returns JSON. Download 2–3 real solar events **now** and embed as archived JSON files with source + date fields. **No HTTP, no API client, no polling code** — labeled archived data is a static-file problem.
- **check-gdscript.sh --strict** is the validation gate so the beginner's UI code doesn't break the merge.

## Smallest version that still hits the rubric

**"Moon Shift" — a fixed 3-sol campaign.** 4-room base (greenhouse = O₂; energy shed + solar panel = power; comms = reports + data cards; hab = storage). **Three resources: power, O₂, radiation.** Interact = walk up, press E, panel with status + repair/upgrade buttons. 4–6 **scripted incidents** on schedule, each backed by a real archived DONKI/RAD event with a visible source card. Victory = base alive + M reports sent after 3 sols. Time scale ×1/×8 so a judge sees 2–3 sols in minutes. Evaluation screen with counters. Onboarding = 3 modal hints with Aurora portrait.

## Cuts, in priority order

1. Exploration main mission → reports from comms console (~8–10h).
2. Intro + landing animation → static title screen + 2 text lines (~5–7h).
3. Aurora walking tutorial → 3 modal pop-ups + portrait (~4–6h).
4. Funding + 4 optional sub-missions → scripted incidents (~4h).
5. Food/water/hunger/thirst → 3 resources only (~3h).
6. Hidden + random stats → delete (~2h).
7. Planet/mission selector → single campaign (~2h).
8. Dormitory + construction room → hab + per-machine repair panels (~2h).
9. Endless mode → silent cut.

Total recovered ≈ 30–35 person-hours; without this, the concept as written is roughly double the remaining budget.

## Bottom line

The concept follows the challenge's simplification advice then violates it everywhere: five resources against "2–3", an extra exploration game on top of the simulation, a second funding economy, three cinematic/animation features by a team with no animator, speculative hidden stats for an out-of-scope future. The evaluable core — visible trade-offs between a small resource set, driven by real DONKI/RAD data with visible provenance — survives after cutting ~60% of the listed scope. Compress to: 4 rooms, 3 resources, 1 interaction model (E → panel), 4–6 scripted incidents as archived sourced JSON from hour one, 3 text hints with mascot portrait, one fixed 3-sol campaign, adjustable time speed for demo. Read the 8-category rubric before noon and map every remaining feature to a rubric line; anything that doesn't map gets cut.
