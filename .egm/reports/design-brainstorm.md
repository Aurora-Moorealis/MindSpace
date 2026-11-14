# Design Critic Brainstorm Report — Junior Astronaut Mission Trainer

Mode: BRAINSTORM. Concept file `.egm/brainstorm-input.md`. Frame: NASA Space Apps, ~36 h, 1 capable Godot dev + 1 beginner UI programmer + 1 unskilled helper, offline singleplayer Godot 4.7, 850×480. Anything unbuildable-and-playable in 36 h kills the submission.
Nota: los revisores no tuvieron herramienta de escritura; este archivo conserva el reporte tal como se recibió.

## BLOCKER

### B1. Three incompatible timescales, none reconciled
The challenge's entire point — feeling the trade-offs of balancing life support — is a multi-day simulation experience. The proposed mission clock (~5 real hours) makes victory impossible to ever test, and defeat-by-deadline unobservable. The judge gets 2–5 minutes. The offhand "speed multiplier or demo skip" collides with the astronaut's real-time movement: accelerate time 10× and one walk across the base costs half a sol of O₂/water/food — resource drain outpaces any physically-executed repair.
Mitigation: pick one demonstrable timescale and build for it. Recommended: mission clock ≈ 10–15 real minutes (≈ 10–15 game hours), first radiation event scripted at minute 3–4, victory reachable in every judge session. Compress the walk cost (small base, fast astronaut). Keep a debug "jump to final evaluation" button. Refuse any time-scale switch in code — one clock only.

### B2. The NASA data plan is inverted and the challenge's own numbers have no sourcing plan at all
"Invent placeholder numbers first, substitute real NASA data at the end" is a plan to ship fiction. Worse: the resource constants at the heart of the challenge (O₂/water/food consumption rates, radiation thresholds, panel yield, plant production) have no NTRS sourcing plan at all — the open points list consumption rates as an economy task, not a data-sourcing task. No team member is assigned to fetch, read, and encode any NASA data.
Mitigation: hour 1 someone (Mijael, on a browser) fetches exactly one small real dataset: one archived DONKI solar event + its corresponding RAD dose, plus one NTRS report for life-support constants. All core numbers typed with a per-field provenance tag (`source_id`, `archived`, `url`/`report`) in the config schema, rendered by the provenance UI from the start. Two real events over 10 minutes of gameplay is defensible science use; twenty fake ones is not.

### B3. The "validate-the-game" mission is the least-defined system and implies a whole second environment nobody sized
"Investigate the planet's structure": explore lunar surroundings, check temperature, rocks, minerals, collect, send reports to Earth. That is an outdoor map — terrain, obstacles, spawn points, tools, sample items, traversal, and the hardest event interactions (storm while outside = forced shelter or death; EVA radiation dose vs suit O₂) — none of which appears anywhere in the base or machine spec. The exploration half has zero objectives while being the declared award axis. 850×480 at 32 px tiles is 26.5×15 tiles — roughly two screens; anything bigger and the outdoor map alone eats a day.
Mitigation: define the main mission as N scan/report loops over a deliberately tiny crater field (≤4 screens) with one tool (scanner) and one pickup item (sample), hard-capped numbers in config. The outdoor map is *small and dangerous*, not big: its job is radiation/storm exposure against the clock, not exploration content.

## MAJOR

### M1. Tutorial, 4 sub-missions, and main mission are three overlapping content structures
Six content chunks (tutorial + 4 sub-missions) plus the main mission, each needing scripting, art, UI and event hooks, in 36 hours. Content duplication is the #1 jam killer.
Mitigation: make the tutorial literally sub-mission 1 (storm warning → shield your shelter → done). Then only 3 sub-missions remain and no content is written twice.

### M2. Event map is empty
A solar storm must specify: warning lead time, radiation accumulation rate (outdoor vs indoors), whether power flickers, whether the communicator is jammed. Dust must specify panel-efficiency decay — and the full chain dust → panel yield → greenhouse light → O₂ → food closes the loop the challenge asks for. Temperature event → which system? None of these linkages exist.
Mitigation: one config-driven table: `event → affected system → parameter delta → duration → provenance tag`. Every event type must touch exactly one subsystem with a visible number. If an event has no effect, cut it.

### M3. Workshop contradiction and dead-weight systems
(a) Room 4 is "mesas de trabajo para **crear** cosas" while crafting is declared out of scope — what is the room for beyond repair? (b) Hidden random stats exist to be modified by upgrades, but the upgrade list has no costs and randomization is justified by future multi-astronaut, which is out of scope — cut both now, keep visible stats only. (c) Hidden stats include "research speed" but no research system exists anywhere in scope.
Mitigation: rename room 4 "repair bay", remove crafting, remove hidden stats, kill "research". Every remaining system must map to a judge-visible number.

### M4. The machine list is the scope multiplier and it is not fixed
Each machine costs: art frame, scene, script, repair state, failure events, upgrade path, UI screen, and an event hook. Ten machines vs five machines is the difference between finishing and not — this number *is* the project plan, and it is undefined the weekend starts.
Mitigation: freeze a machine budget before art starts: hard cap ~7 interactive machines (O₂ scrubbing plant, water recycler, greenhouse hydroponic unit ×1 shared, solar panel, generator/distributor, comms console, one repair bay). One machine per room, no exceptions.

### M5. Power chain and radiation shielding are half-specified
The walk distance to the solar panel *is* the radiation dose per cleaning; that number must exist. Does power gate machines individually or as one pool? Does the greenhouse use natural light (storm-vulnerable) or lamps (power-vulnerable)? And where is **radiation shielding** — the challenge lists it among the resources to balance; there is no shelter upgrade, no "indoors = safe" baseline rule with numbers.
Mitigation: define the chain panel→storage→distribution→per-room consumers (greenhouse lamps = largest draw, creating dust/storm double pressure). Define one shielding rule: indoors caps radiation, EVA dose rate × distance, one upgrade slot (e.g., dormitory storm shelter) — one number to balance, not a subsystem.

### M6. Repo and tooling rules are a time tax on the two non-expert members, unaccounted
AGENTS.md mandates `main → features → <módulo>`, PR-only integration, worktrees outside the repo, strict explicit typing. Against 36 h: (a) branch/PR-per-module with a beginner guarantees merge churn on `.tscn` and rebase dead time; (b) the beginner doing UI will burn hours fighting the strict GDScript checker; (c) one editor per worktree conflicts with jam realities. All logic touches DevGreem anyway, so parallel branches buy almost nothing.
Mitigation: hour 1, declare a jam exception: single shared branch (check with repo owner), merge-free lanes (UI in `scenes/`, logic in `scripts/`, content folders pre-assigned). Pre-define data contracts so the beginner's HUD reads stat names from one autoload and never writes logic. Budget that AI-generated GDScript will violate the typing rule and needs cleanup passes.

### M7. No balance harness, no metric definition, no feedback loop to the evaluation screen
Balancing 5 interacting resources is iterative playtesting; without a debug harness, the first real playtest is the demo, and the core promise ("feel the trade-offs") is unvalidated. The final evaluation screen has no metrics defined, so it cannot be built until the last hours.
Mitigation: cheat/debug panel from hour 1 (hidden behind F1, zero extra art). Define 5 evaluation metrics in the config schema now (e.g., mission reports sent, plant deaths, total EVA dose, event count survived, resource lows). Metrics derive from signals the systems already emit.

### M8. Funding economy has no rates; comms delivery is an async system with no schedule
Funding → resources conversion rates are undefined. Comms room has two functions (get future event info; request resources with delivery time) — a mail/timer system plus a prediction UI, combined with the event scheduler.
Mitigation: sub-missions pay directly in *one* resource (choose: water or power), no intermediate currency, or the funding conversion rate is a single constant in config. Either drop delivery requests or make them one fixed order option with one fixed delay; prediction UI = "next event in N hours" text from the event queue.

## NIT

- N1. Mission selector with 33% content. Show *one* mission, or three cosmetic variants differing only in target counts from the same config. Do not build selector chrome.
- N2. Aurora the space cow implies walk/idle animations nobody animates quickly; a static portrait with text bubbles teaches the tutorial just as well for 5% of the art cost.
- N3. Intro + landing animations: two cutscene sequences before any gameplay; convert to 2–3 still panels with text. Cutscene art is the highest-hours-per-second-of-screen-time in the project.
- N4. Sound 1/5 by tools: acceptable; freeze a short, consistent SFX set early; wrong-volume AI loops sound worse than silence in a judging room.
- N5. Keyboard-only control: a judging table may prefer demo-friendly controls (mouse click-to-move + space interact as fallback); if keyboard-only, get the demo on a laptop the team controls.
- N6. "Temperatura" events vs. body temperature stat absent: if temperature is an event, it must act on something (suit battery, plant growth); otherwise cut from the event list.

## Cost / Quota economics (summary)

Runtime economics are zero: offline singleplayer, archived NASA data, no server, no database, no API calls at runtime, no external quota. Peak QPS: 1 local session. The *real* quota is human-hours: every interactive machine, event type, animation sequence, and sub-mission is a fixed multi-hour unit cost against ~36 total. The project is spec'd at roughly 25–30 such units (3×+ over budget). Freeze: machine cap (7), event table (3 types max), content chunks (tutorial+3), animation set (stills-only cutscenes), map sizes (base 5 rooms, outdoor ≤4 screens) before art and code start.

## Bottom line

This concept is a full simulation-management game plus an exploration game plus a narrative wrapper, spec'd for a 36-hour window in which the three-timescale problem (5-hour mission vs 2-minute judge vs multi-day simulation fantasy) is unresolved, the award-axis (real NASA data) is planned backwards (fakes first, truth "at the end"), and the declared validation system (science mission) has no design at all. It collapses on content volume unless the synthesizer cuts first and builds the proof second: one 10–15-minute clock, one config-driven event table with real archived DONKI/RAD numbers plus NTRS-sourced life-support constants baked in from hour one, one small outdoor loop, one machine per room capped at ~7, tutorial-as-submission-1, stills instead of cutscenes, and a debug harness so balance is at least *felt* once before the demo.
