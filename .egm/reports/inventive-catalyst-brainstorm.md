# Inventive Catalyst Brainstorm Report — Junior Astronaut Mission Trainer

Mode: BRAINSTORM. Lens: TRIZ contradiction elimination. Concept file `.egm/brainstorm-input.md`, 2026-11-14.
Nota: los revisores no tuvieron herramienta de escritura; este archivo conserva el reporte tal como se recibió.

## Blocker 1 — Real-time sim capacity vs. requested 12-sol runtime

- **Concept sections**: "Tiempo", "Recursos", "Eventos lunares".
- **Contradiction**: Content depth (12 sols ≈ 288 game-hours of believable minute-level variation) versus build capacity (36 h, ~1.5 programmers).
- **Inventive Resolution Pattern**: Parameterized event archetypes + day-zero data tables (**Segmentation** + **Preliminary Action**). Freeze ~5 archetypes (machine fault, production dip, consumption spike, radiation window, comms outage), each fully driven by a table row: target machine, intensity, duration, onset, effect curve. Sol-to-sol variety = combinatorially varied rows, not code. DONKI/RAD feeds become more tables keyed by sol.
- **Secondary Trade-offs**: The archetype set is a day-1 design freeze and cannot express exotic bespoke events later; table columns can silently drift (needs one validator that rows reference existing machine IDs); balance passes become data edits rather than code edits.
- **IFR**: New content for all 12 sols = new rows in a JSON written by the non-programmers; the team never touches the sim core again.

## Blocker 2 — Hours-long live simulation vs. judges seeing the full loop in minutes

- **Contradiction**: Time-to-showcase (judge attention ~3 min) versus time-to-simulate (~5 real hours).
- **Inventive Resolution Pattern**: Event-sourced deterministic tick engine + replay-as-demo (**Dynamics** + **Beforehand Cushioning**, with **Extraction** of the sim from the scene tree). All resource logic is a pure function of discrete tick *n* (1 tick = 1 game-hour = 60 s at 1×). Speed = tick multiplier, never physics scaling. The judge demo = deterministic replay of one captured run rendered at 30–60× under a "sol report" overlay, plus checkpointed jumps to arbitrary sols.
- **Secondary Trade-offs**: Player interactions must be sub-tick (instant repairs, tick-injected orders) or they desync the sim; at >10× sprite animation reads as garbage — needs a fast-forward veil; determinism demands seeded RNG per tick and forbids wall-clock- or physics-based resource code anywhere; checkpointing means every state variable must be serializable.
- **IFR**: Any judge presses one key and watches the complete early/mid/late mission arc in under 3 minutes, rendered from real captured gameplay, with zero bespoke demo content.

## Major 3 — Optional side missions vs. needing them for resources

- **Contradiction**: Optionality (submisiones must never gate victory) versus economic leverage (they are the stated funding source precisely when resources run short).
- **Inventive Resolution Pattern**: **Inversion** + **Dynamics**: invert the economy flow — the main investigation (scan/collect/send reports) is the base revenue; a submisión = {main-loop template + alert condition + upgrade coupon} built from a table. **Blessing in Disguise**: resource shortage activates a designed low-resource mode (Earth emergency resupply with delivery delay, provisional harvest-only) instead of becoming a wall.
- **Secondary Trade-offs**: The main mission must itself be parameterizable from day 1 or submisiones cannot reuse it; "optional but useless" risk if reward tuning is weak; template sameness can leak into visible gameplay (needs per-row flavor text); rewards require a small upgrade-category system.
- **IFR**: 4–8 side missions authored in under an hour, individually worth doing, never required, never gating, and no bespoke mission code.

## Major 4 — Placeholder numbers now vs. judged NASA data criterion

- **Contradiction**: Build velocity now versus a rubric criterion (NASA data authenticity and visibility). The accepted compromise defers real-data integration to the final hours — the moment when the risk is highest — despite the data being shelf archival data that exists today.
- **Inventive Resolution Pattern**: **Preliminary Action** + **Intermediary**: the helper fetches archived DONKI CSV + 2–3 NTRS citations at hour 0 (a download task, not development), loaded into tables behind a day-0 data-access layer with schema `{key, value, unit, source_url, status: placeholder|archived}`. The provenance UI ("source" button) is emitted by the data layer from day 1, including for placeholder rows. Swapping = editing a row; no code change.
- **Secondary Trade-offs**: Every displayed number needs a citation row; real archived solar-event windows may be sparse or badly timed relative to difficulty (requires selecting a benign archive window); provenance UI is an extra screen/art piece; placeholder rows must carry a visible "mock" badge.
- **IFR**: Every number on screen has a one-click source, and replacing a placeholder with a documented NASA value is a table edit any team member can do at any hour.

## Nit 5 — Tutorial that requires finished content vs. limited art + pipeline

- **Contradiction**: Walkthrough completeness (mascot narrates all buildings and machines) versus art/content that is known-incomplete during the entire build.
- **Inventive Resolution Pattern**: **Inversion** + **Intermediary**: contextual trigger engine — the walkthrough is not a scripted scene. Each machine/content piece declares `hint_text` + trigger condition in its data; the mascot overlay subscribes to an event bus and attaches to whatever content actually exists tonight. Missing content is silently excluded from the tour. Build the playable loop first; attach the tutorial overlay after.
- **Secondary Trade-offs**: Hint quality becomes decentralized authoring; trigger conditions need per-piece testing; the mascot becomes a HUD overlay system instead of a scripted character scene (less cinematic, cheaper to keep alive).
- **IFR**: The tutorial always narrates a coherent tour of whatever exists at any point of the hackathon, never breaks when content changes, and costs near zero to extend.

## Bottom line

Two blockers share one root fix: freeze a deterministic, tick-pure simulation core on day 1 (1 tick = 1 game-hour, all tables, all events, all provenance driven by data rows), because it simultaneously solves the 12-sol variety problem and the judge-demo problem via replay/jump instead of a bespoke demo. Everything else — submisiones as main-loop templates, NASA data as hour-0 pre-fetched tables behind a citation schema, and a trigger-based tutorial overlay — should be table rows over that core. Reject any bespoke per-mission or per-event code, and reject deferred data integration.
