-- Segmented health fill for the in-game HUD (art 120x10, runtime 240x20 at 2x).
-- Contract: art/ui/hud/HUD-BRIEF.md and openspec/specs/art-style/spec.md.
-- 8 segments of 15 px: 14 px of fill + 1 px separator.
-- Build: Aseprite.exe -b --script build_health_fill.lua
-- Output: hud_health_fill.aseprite (master) + hud_health_fill_1x.png (art 1x).
-- The runtime PNG at 2x is produced with ImageMagick (nearest neighbour).

local OUT_DIR = "C:/Users/ramer/Documents/Proyects/MindSpace/art/ui/hud"
local H = dofile(OUT_DIR .. "/hud_common.lua")

local W = 120
local HGT = 10
local SEGMENTS = 8
local SEG_W = 15
local FILL_W = 14

local img = Image(W, HGT, ColorMode.RGB)

for segment = 0, SEGMENTS - 1 do
  local x0 = segment * SEG_W
  for x = x0, x0 + FILL_W - 1 do
    img:putPixel(x, 0, H.C.fire_light)
    for y = 1, HGT - 2 do
      img:putPixel(x, y, H.C.fire)
    end
    img:putPixel(x, HGT - 1, H.C.fire_dark)
  end
  -- 1 px separator, full height, between segments.
  H.rect(img, x0 + FILL_W, 0, x0 + FILL_W, HGT - 1, H.C.gap)
end

local spr = Sprite(W, HGT, ColorMode.RGB)
local layer = spr:newLayer()
layer.name = "fill"
spr:newCel(layer, 1, img, Point(0, 0))
spr:deleteLayer(spr.layers[1])

spr:saveAs(OUT_DIR .. "/hud_health_fill.aseprite")
spr:saveCopyAs(OUT_DIR .. "/hud_health_fill_1x.png")

-- Verification: separators sit at the end of every 15 px segment.
local gaps = 0
local gap_bad = 0
for segment = 0, SEGMENTS - 1 do
  local x = segment * SEG_W + FILL_W
  for y = 0, HGT - 1 do
    gaps = gaps + 1
    if img:getPixel(x, y) ~= H.C.gap then gap_bad = gap_bad + 1 end
  end
end
print(string.format("fill %dx%d segments=%d sep columns=%d bad=%d", W, HGT, SEGMENTS, gaps, gap_bad))
print(string.format("OK hud_health_fill %dx%d", W, HGT))
