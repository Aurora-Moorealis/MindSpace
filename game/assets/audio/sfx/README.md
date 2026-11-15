# SFX pack - MindSpace v1

Twelve short, mono, original sounds synthesized for the lunar outpost. They
follow the art direction: soft retro tones, no distorted or aggressive highs,
and a cold sci-fi palette with warm confirmation notes.

## Files and ownership

Shared sounds live here; the hydroponics-only sounds live with their machine.

| File | Owner | Action | Length |
| --- | --- | --- | --- |
| `assets/audio/sfx/ui_click.ogg` | shared UI | Select slot / open a cell popup | 0.08 s |
| `assets/audio/sfx/ui_open.ogg` | shared UI | Enter a machine, menu or panel | 0.30 s |
| `assets/audio/sfx/ui_close.ogg` | shared UI | Leave a machine or panel | 0.24 s |
| `assets/audio/sfx/ui_deny.ogg` | shared UI | Empty slot / rejected action | 0.20 s |
| `assets/audio/sfx/repair.ogg` | machines | Repair action accepted | 0.68 s |
| `assets/audio/sfx/report.ogg` | comms | Report sent fact | 0.90 s |
| `assets/audio/sfx/scan.ogg` | world | Scan / reading (not wired yet) | 0.78 s |
| `assets/audio/sfx/radiation_alarm.ogg` | HUD | Radiation warning threshold | 1.30 s |
| `assets/audio/sfx/event.ogg` | events | Event started fact | 0.68 s |
| `content/machines/hydroponics/sounds/plant.ogg` | hydroponics | Sow a seed | 0.36 s |
| `content/machines/hydroponics/sounds/harvest.ogg` | hydroponics | Collect a mature crop | 0.46 s |
| `content/machines/hydroponics/sounds/remove.ogg` | hydroponics | Pull out a growing plant | 0.34 s |

## Integration

`AudioManager` is an autoload (`game/scripts/autoloads/audio_manager.gd`) and
plays through the `SFX` bus in `game/default_bus_layout.tres`:

```gdscript
AudioManager.play(AudioManager.Sfx.HARVEST)
```

- The pool has 10 voices, so overlapping UI and world sounds do not cut each
  other off.
- `plant`, `harvest`, `remove`, `scan` and `repair` get a small pitch jitter to
  avoid machine-gun repetition. UI sounds keep a fixed pitch.
- `AudioManager.set_muted(true/false)` / `toggle_muted()` stop everything on the
  SFX bus. The `M` key toggles the same mute at any time. Critical sounds still
  need a subtitle or icon in the HUD (`docs/future/art-and-audio.md`).

Wired actions:

| Area | Sounds |
| --- | --- |
| Welcome, worlds, intro, evaluation, run UI | click, open, close, deny |
| Machine panel | open, close, repair, upgrade, deny |
| Hydroponics panel | plant, harvest, remove, deny |
| Hotbar HUD | click, selection, drag/drop |
| HUD time controls | click |
| Radiation crossing | radiation_alarm |
| `EventLog` facts | report, event |

`scan` stays ready for the future POI scan; there is no fake action for it.

## Audition

The local QA scene lists all twelve sounds, with a play-all button and a mute
toggle (ignored by git, like the rest of `tests/`):

```bash
godot --path game --scene res://tests/audio/audition/audition.tscn
```

It can also capture itself for layout QA:

```bash
godot --path game --scene res://tests/audio/audition/audition.tscn -- --capture
```

## Format and levels

- Mono, 44.1 kHz, Ogg Vorbis quality 5, no loop metadata (one-shots).
- Authored by RMS with a peak ceiling: UI at -18/-19 dBFS RMS, actions at
  -16/-17 dBFS RMS, `ui_click` at -20 dBFS RMS, alarm at -15 dBFS RMS.
- True peaks stay at or below -2.4 dBFS; the `SFX` bus trims -4 dB for headroom.
- No music in v1, so the bus is the only mix control for now.

## How they were made

They are original synthesis, not samples: no third-party audio and no
attribution required. The generator is a local dev tool ( `tests/` is ignored by
git) and writes the WAV intermediates before encoding the OGGs.

Keep the source recipe in sync with the pack if a sound changes.
