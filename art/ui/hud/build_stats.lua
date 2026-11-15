-- Minimal resource strip for the in-game HUD: four icon + track rows with no
-- panel background. The Sol text is drawn by Godot, not here.
-- Art is 88x36 (1x grid); the runtime PNGs are produced at 2x with ImageMagick.
--   Aseprite.exe -b --script build_stats.lua
--
-- Contract: art/ui/hud/HUD-BRIEF.md and openspec/specs/art-style/spec.md.
-- Shared construction helpers live in hud_common.lua (read-only).

local H = dofile("C:/Users/ramer/Documents/Proyects/MindSpace/art/ui/hud/hud_common.lua")
local ROOT = "C:/Users/ramer/Documents/Proyects/MindSpace/art/ui/hud"
local RUNTIME_DIR = "C:/Users/ramer/Documents/Proyects/MindSpace/game/assets/images/ui/hud"

local STRIP_W = 88
local STRIP_H = 36
local ROWS = { 0, 9, 18, 27 }
local ICON_X = 0
local TRACK_X = 10
local TRACK_W = 60
local TRACK_H = 6
local FILL_W = 58
local FILL_H = 4

-- Terrain ramps used by the HUD (both are in the art-style spec).
local ICE_L = app.pixelColor.rgba(196, 216, 223, 255)
local ICE = app.pixelColor.rgba(143, 170, 180, 255)
local ICE_D = app.pixelColor.rgba(92, 118, 128, 255)
local SILICA_L = app.pixelColor.rgba(221, 213, 190, 255)
local SILICA = app.pixelColor.rgba(184, 174, 146, 255)
local SILICA_D = app.pixelColor.rgba(140, 132, 108, 255)

local ICON_O2 = {
  "..OOO...",
  "..OMO...",
  ".OOOMOO.",
  ".OLTTTO.",
  ".OLTTTO.",
  ".OLTTTO.",
  ".ODDDDO.",
  ".OOOOOO.",
}

local ICON_WATER = {
  "...O....",
  "..OLO...",
  "..OLO...",
  ".OLLLO..",
  ".OLLDO..",
  ".OLLDO..",
  "..ODO...",
  "...O....",
}

local ICON_FOOD = {
  "..OOOO..",
  ".OLLLLO.",
  ".OAAAAO.",
  ".OAWWAO.",
  ".OAWWAO.",
  ".OAAAAO.",
  ".ODDDDO.",
  "..OOOO..",
}

local ICON_ENERGY = {
  "....OO..",
  "...OLBO.",
  "..OLBO..",
  ".OBBBBO.",
  "..OLBO..",
  ".OLBO...",
  ".OO.....",
  "........",
}

local function key_of(color)
  return string.format(
    "%02x%02x%02x",
    app.pixelColor.rgbaR(color),
    app.pixelColor.rgbaG(color),
    app.pixelColor.rgbaB(color)
  )
end

local function verify(name, img)
  local palette = {}
  for _, color in pairs(H.C) do
    palette[key_of(color)] = true
  end
  palette[key_of(ICE_L)] = true
  palette[key_of(ICE)] = true
  palette[key_of(ICE_D)] = true
  palette[key_of(SILICA_L)] = true
  palette[key_of(SILICA)] = true
  palette[key_of(SILICA_D)] = true
  local off_palette = 0
  local partial_alpha = 0
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local color = img:getPixel(x, y)
      local alpha = app.pixelColor.rgbaA(color)
      if alpha ~= 0 and alpha ~= 255 then
        partial_alpha = partial_alpha + 1
      end
      if alpha ~= 0 and not palette[key_of(color)] then
        off_palette = off_palette + 1
      end
    end
  end
  print(string.format("%s %dx%d off_palette=%d partial_alpha=%d", name, img.width, img.height, off_palette, partial_alpha))
  assert(off_palette == 0, name .. " uses colors outside the palette")
  assert(partial_alpha == 0, name .. " has semi-transparent pixels")
end

local function draw_map(img, x, y, rows, legend)
  for row = 1, #rows do
    assert(#rows[row] == 8, "icon row " .. row .. " must be 8 columns")
    for col = 1, #rows[row] do
      local code = rows[row]:sub(col, col)
      if code ~= "." then
        local color = legend[code]
        assert(color ~= nil, "missing legend for " .. code)
        img:putPixel(x + col - 1, y + row - 1, color)
      end
    end
  end
end

local function draw_track(img, y)
  H.rect(img, TRACK_X, y, TRACK_X + TRACK_W - 1, y + TRACK_H - 1, H.C.outline)
  H.rect(img, TRACK_X + 1, y + 1, TRACK_X + TRACK_W - 2, y + TRACK_H - 2, H.C.well_floor)
end

local function icon_legend(light, body, dark)
  return {
    O = H.C.outline,
    M = H.C.screw_head,
    L = light,
    T = body,
    A = body,
    B = body,
    D = dark,
    W = H.C.screw_glint,
  }
end

local function save_sprite(name, spr, img)
  verify(name, img)
  spr:saveAs(ROOT .. "/" .. name .. ".aseprite")
  spr:saveCopyAs(ROOT .. "/" .. name .. "_1x.png")
  print("saved " .. name .. " -> " .. RUNTIME_DIR .. "/" .. name .. ".png")
end

local function fill(name, light, body, dark)
  local spr = H.sprite("fill", FILL_W, FILL_H)
  local img = spr.cels[1].image
  H.rect(img, 0, 0, FILL_W - 1, 0, light)
  H.rect(img, 0, 1, FILL_W - 1, FILL_H - 2, body)
  H.rect(img, 0, FILL_H - 1, FILL_W - 1, FILL_H - 1, dark)
  save_sprite(name, spr, img)
end

-- Transparent strip: icons and recessed tracks only, no panel or screws.
local strip_spr = H.sprite("resources", STRIP_W, STRIP_H)
local strip_img = strip_spr.cels[1].image
draw_map(strip_img, ICON_X, ROWS[1], ICON_O2, icon_legend(H.C.teal_light, H.C.teal, H.C.teal_dark))
draw_map(strip_img, ICON_X, ROWS[2], ICON_WATER, icon_legend(ICE_L, ICE, ICE_D))
draw_map(strip_img, ICON_X, ROWS[3], ICON_FOOD, icon_legend(H.C.amber_light, H.C.amber, H.C.amber_dark))
draw_map(strip_img, ICON_X, ROWS[4], ICON_ENERGY, icon_legend(SILICA_L, SILICA, SILICA_D))
for _, row in ipairs(ROWS) do
  draw_track(strip_img, row + 1)
end
save_sprite("hud_resources_strip", strip_spr, strip_img)

-- Fills: one light row, two body rows and one dark row.
fill("hud_stat_fill_oxygen", H.C.teal_light, H.C.teal, H.C.teal_dark)
fill("hud_stat_fill_water", ICE_L, ICE, ICE_D)
fill("hud_stat_fill_food", H.C.amber_light, H.C.amber, H.C.amber_dark)
fill("hud_stat_fill_energy", SILICA_L, SILICA, SILICA_D)
