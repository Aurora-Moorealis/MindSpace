-- Health bar frame for the in-game HUD (art 164x24, runtime 328x48 at 2x).
-- Contract: art/ui/hud/HUD-BRIEF.md and openspec/specs/art-style/spec.md.
-- Build: Aseprite.exe -b --script build_health_bar.lua
-- Output: hud_health_bar.aseprite (master) + hud_health_bar_1x.png (art 1x).
-- The runtime PNG at 2x is produced with ImageMagick (nearest neighbour).

local OUT_DIR = "C:/Users/ramer/Documents/Proyects/MindSpace/art/ui/hud"
local H = dofile(OUT_DIR .. "/hud_common.lua")

local W = 164
local HGT = 24

-- Recessed track: 1 px outline + flat floor, no inner bevel (the fill covers it).
local TRACK_X = 32
local TRACK_Y = 6
local TRACK_W = 122
local TRACK_H = 12

-- Heart tile: 12x12 at (10, 6).
local HEART_X = 10
local HEART_Y = 6

-- Heart map, 12 rows of 12 columns.
-- '.' transparent, 'O' outline, 'F' fire body, 'L' highlight, 'D' shadow.
local HEART_MAP = {
  "..OOO..OOO..",
  ".OLLO..OLLO.",
  ".OLLFOOFFFO.",
  "OLLFFFFFFFDO",
  "OLFFFFFFFFDO",
  "OFFFFFFFFDDO",
  ".OFFFFFFDDO.",
  "..OFFFFDDO..",
  "...OFFDDO...",
  "...OFFDDO...",
  "....OFDO....",
  ".....OO.....",
}

for row = 1, #HEART_MAP do
  assert(#HEART_MAP[row] == 12, "heart row " .. row .. " must be 12 columns")
end
assert(#HEART_MAP == 12, "heart map must be 12 rows")

local HEART_COLORS = {
  O = H.C.outline,
  F = H.C.fire,
  L = H.C.fire_light,
  D = H.C.fire_dark,
}

local function draw_heart(img, ox, oy)
  for row = 1, #HEART_MAP do
    local line = HEART_MAP[row]
    for col = 1, #line do
      local code = line:sub(col, col)
      if code ~= "." then
        img:putPixel(ox + col - 1, oy + row - 1, HEART_COLORS[code])
      end
    end
  end
end

-- Panel layer: flat panel, recessed track, no text.
local panel = Image(W, HGT, ColorMode.RGB)
H.panel(panel, W, HGT)

-- Track outline: 1 px, continuous.
H.rect(panel, TRACK_X, TRACK_Y, TRACK_X + TRACK_W - 1, TRACK_Y + TRACK_H - 1, H.C.outline)
-- Track floor: 120x10, flat.
H.rect(panel, TRACK_X + 1, TRACK_Y + 1, TRACK_X + TRACK_W - 2, TRACK_Y + TRACK_H - 2, H.C.well_floor)

-- Four corner screws, 3 px from the border.
H.screw(panel, 3, 3)
H.screw(panel, W - 8, 3)
H.screw(panel, 3, HGT - 8)
H.screw(panel, W - 8, HGT - 8)

-- Heart layer.
local heart = Image(W, HGT, ColorMode.RGB)
draw_heart(heart, HEART_X, HEART_Y)

local spr = Sprite(W, HGT, ColorMode.RGB)
local panel_layer = spr:newLayer()
panel_layer.name = "panel"
spr:newCel(panel_layer, 1, panel, Point(0, 0))
local heart_layer = spr:newLayer()
heart_layer.name = "heart"
spr:newCel(heart_layer, 1, heart, Point(0, 0))
spr:deleteLayer(spr.layers[1])

spr:saveAs(OUT_DIR .. "/hud_health_bar.aseprite")
spr:saveCopyAs(OUT_DIR .. "/hud_health_bar_1x.png")

-- Verification: heart geometry and its 1 px ring.
local total = 0
local fill_bad = 0
local outline_bad = 0
local min_x, min_y = 99, 99
local max_x, max_y = -1, -1
for y = 0, HGT - 1 do
  for x = 0, W - 1 do
    local v = heart:getPixel(x, y)
    if app.pixelColor.rgbaA(v) > 0 then
      total = total + 1
      if x < min_x then min_x = x end
      if y < min_y then min_y = y end
      if x > max_x then max_x = x end
      if y > max_y then max_y = y end
      local is_outline = v == H.C.outline
      local open = 0
      local neighbours = { { x, y - 1 }, { x, y + 1 }, { x - 1, y }, { x + 1, y } }
      for i = 1, 4 do
        local nx = neighbours[i][1]
        local ny = neighbours[i][2]
        local nv = 0
        if nx >= 0 and nx < W and ny >= 0 and ny < HGT then nv = heart:getPixel(nx, ny) end
        if app.pixelColor.rgbaA(nv) == 0 then open = open + 1 end
      end
      if is_outline then
        if open == 0 then outline_bad = outline_bad + 1 end
      elseif open > 0 then
        fill_bad = fill_bad + 1
      end
    end
  end
end
print(string.format("heart pixels=%d bounds=(%d,%d)-(%d,%d)", total, min_x, min_y, max_x, max_y))
print(string.format("heart fill touching transparency=%d outline without transparency=%d", fill_bad, outline_bad))

-- Verification: track interior is flat #14192B, 120x10, with a 1 px outline around it.
local track_floor = 0
local track_bad = 0
for y = TRACK_Y + 1, TRACK_Y + TRACK_H - 2 do
  for x = TRACK_X + 1, TRACK_X + TRACK_W - 2 do
    if panel:getPixel(x, y) == H.C.well_floor then
      track_floor = track_floor + 1
    else
      track_bad = track_bad + 1
    end
  end
end
local ring = 0
local ring_bad = 0
for x = TRACK_X, TRACK_X + TRACK_W - 1 do
  for _, y in ipairs({ TRACK_Y, TRACK_Y + TRACK_H - 1 }) do
    ring = ring + 1
    if panel:getPixel(x, y) ~= H.C.outline then ring_bad = ring_bad + 1 end
  end
end
for y = TRACK_Y + 1, TRACK_Y + TRACK_H - 2 do
  for _, x in ipairs({ TRACK_X, TRACK_X + TRACK_W - 1 }) do
    ring = ring + 1
    if panel:getPixel(x, y) ~= H.C.outline then ring_bad = ring_bad + 1 end
  end
end
print(string.format("track floor pixels=%d bad=%d ring pixels=%d ring bad=%d", track_floor, track_bad, ring, ring_bad))
print(string.format("OK hud_health_bar %dx%d", W, HGT))
