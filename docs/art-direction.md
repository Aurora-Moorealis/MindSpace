# MindSpace — art direction (v1)

Scope: the art direction applied to the astronaut and the rules the rest of the
game must follow. References are **principles**, not assets: nothing here copies
Pokémon Emerald or The Binding of Isaac.

## 1. What the project actually is

- **Engine:** Godot 4.7.2.
- **Canvas:** 850×480, stretch `canvas_items`.
- **Camera:** 2D top-down 3/4 (fixed, no perspective tricks).
- **Map:** lunar outpost, 5 rooms, **32 px tiles**.
- **Player:** `CharacterBody2D`, 4-direction movement, proximity interaction.
- **Mechanics that need art:** idle, walking, interacting/scanning, damage and
  death. There is **no jump and no zero gravity** in this game, so those sets
  do not exist.

## 2. Visual identity

A hand-made pixel-art indie game: clean 1 px outlines, limited palette, large
readable shapes, small warm accents on a cold environment.

From Pokémon Emerald we take: balanced palette, tile-scale discipline, clear
separation between characters and background, modular props.
From The Binding of Isaac we take: big-head/small-body proportions, expressive
silhouette, confident outlines, personality over realism.

## 3. Palette (17 colors)

| Use | Hex |
| --- | --- |
| Outline | `#111827` |
| Suit highlight / light | `#ffffff` / `#f6fafe` |
| Suit mid | `#d8e2f0` |
| Suit shade / deep | `#aebdd2` / `#7c8ca6` |
| Visor rim / dark / mid | `#081120` / `#0a1728` / `#16324f` |
| Glass highlight / specular | `#5fb6da` / `#d6f4ff` |
| Tech dark | `#232d42` |
| Metal dark / light | `#3d495e` / `#7d8ca3` |
| Accent red / orange | `#c6432f` / `#e8763a` |
| Warning light | `#f4c25a` |

Rules: no pure black, no saturated primaries. Orange/red never exceed ~5 % of a
sprite. Backgrounds stay in a narrower, darker range so the white suit pops.

## 4. Character rules

- 64×64 frame, ~48 px tall, anchor at `(32, 49)` (feet).
- Helmet is the largest mass; body is short; boots are chunky.
- Visor is always the focal point: one strong cyan crescent, one small glint.
- 1 px closed outline; interior separation only with 1 px shadow, not with black.
- Four directions must share silhouette mass and anchor.
- Never redraw the helmet, visor or proportions per animation: reuse the master.

## 5. Environment rules (for the next assets)

- 32 px grid, modular tiles: floor, wall, wall top, door/airlock, window.
- Two-tone floors + a darker wall band; props with 1 px outlines and 3 values.
- Keep the floor value range between `#1d2536` and `#33405a`; characters are
  light, so floors must be dark or mid.
- Space windows are the only place for saturated blue/cyan.
- Prop scale: consoles 2×1 tiles, crates 1×1, plants 1×1, doors 2×2.

## 6. Pipeline and QA

1. Draw in Aseprite at 1× in the 64×64 grid (see the `.aseprite` sources).
2. Export PNG with real alpha; check the anchor and the frame bounds.
3. Import into Godot with nearest filtering, no mipmaps.
4. Review at real size (1×) on the 850×480 canvas, not only zoomed in.
5. Checklist: readable silhouette at 1×, closed outline, no stray pixels,
   consistent palette, feet on the same ground line, no jitter between frames.

## 7. Delivered in this pass

- Master reference: front / right / back / left, 64×64.
- Idle: 4 frames × 4 directions, 180 ms, loop, sheets + individual PNGs.
- Palette (.gpl + swatches), JSON metadata, README with Godot instructions.
- Preview scene (`game/tests/art_preview/`) rendered in Godot for visual QA.

Pending: walk, interact, hurt, death, environment tileset and props.

## 8. Item icons and inventory UI (v1)

Delivered: 12 item icons for the suit toolkit and a Minecraft-style suit
inventory panel (`game/content/items/toolkit/` and
`game/scenes/ui/inventory/`).

- **Item icons:** 16×16 px, RGBA, 1 px `#111827` outline, 14×14 usable area,
  1 px transparent margin. Three to four value steps per material; orange, red
  and cyan only as caps, handles, labels and glints.
- **Palette:** the 17 colors above, no new colors. Cyan is reserved for screens,
  liquid and energy; warning yellow for radiation; orange for handles, caps and
  tags.
- **Rarity colors:** common `#d8e2f0`, uncommon `#f4c25a`, rare `#5fb6da`, epic
  `#e8763a`. Rarity never adds an extra frame; it only tints the title, chip and
  top rule of the item card.
- **Display:** 16×16 at 3× (48 px) inside 52 px slots, nearest filtering, no
  mipmaps. Icons are centered; no per-icon anchor.
- **Inventory chrome:** 2 px `#111827` outer border, 1 px `#3d495e` top/left
  bevel, 1 px `#0a0f1a` bottom/right inset, no rounded corners. Slots use a 2 px
  inset bevel; hover is cyan, selection is warning yellow.
- **UI type:** Press Start 2P at 8 px (body) and 16 px (titles), antialiasing
  off, hinting off, subpixel positioning off. No system font fallback.
- **Item card:** `#080d17` panel with a rarity-colored top rule and title,
  category/rarity line, wrapped description, effect in warning yellow, and a
  mass/stack line.
- **QA:** readable at 1× on the 850×480 canvas; icon readable at 3×; item card
  never covers the quick bar; no text overlap at 8 px. The real capture is
  `game/content/items/toolkit/art/previews/inventory_850x480.png`.
