# MindSpace

<!-- TODO: One or two sentences describing the game and its core idea. -->

A game built with the [Godot Engine](https://godotengine.org/).

## Requirements

- **Godot Engine 4.7** (stable)
- [Aseprite](https://www.aseprite.org/) (optional, for pixel art)
- [Audacity](https://www.audacityteam.org/) (optional, for sound effects)

## Getting started

This repository keeps the Godot project in the `game/` folder. Open it with the
editor:

```bash
godot --editor --path game
```

The `.godot/` folder is generated automatically the first time the project is
opened and is intentionally ignored by Git.

## Project structure

Inside `game/`:

| Folder | Contents |
| --- | --- |
| `addons/` | Godot and third-party addons. Do not edit unless the task is the addon itself. |
| `assets/` | Shared assets (`audio/`, `fonts/`, `images/`, `particles/`, `tilesets/`). |
| `components/` | Reusable libraries managed with LibraryManager. |
| `content/` | Game content, grouped as `content/<type>/<name>/`. |
| `databases/` | Resource files that act as registries or databases. |
| `resources/` | Scripts that define `Resource` classes and shared resources. |
| `scenes/` | Real screens, menus and game flow. |
| `scripts/` | Project-only code (autoloads, managers, glue). |
| `shaders/` | Shared shaders. |
| `themes/` | Shared themes. |
| `tests/` | Local test area. Ignored by Git. |

## Controls

<!-- TODO: List the controls once they exist. -->

| Action | Input |
| --- | --- |
| — | — |

## License

<!-- TODO: Add a license if this project is going to be published. -->
