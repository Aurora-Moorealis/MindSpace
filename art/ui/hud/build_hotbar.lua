-- Generates the in-game hotbar: dark navy panel with five empty 24x24 slots.
-- Art is 144x40 (1x grid); the runtime PNG is exported at 2x (288x80).
--   Aseprite.exe -b --script build_hotbar.lua
--
-- Contract: art/ui/hud/HUD-BRIEF.md and openspec/specs/art-style/spec.md.
-- Shared construction helpers live in hud_common.lua (read-only).

local ROOT = "C:/Users/ramer/Documents/Proyects/MindSpace/art/ui/hud"
local RUNTIME_DIR = "C:/Users/ramer/Documents/Proyects/MindSpace/game/assets/images/ui/hud"
local H = dofile(ROOT .. "/hud_common.lua")

local W, HEIGHT = 144, 40
local SLOT_COUNT = 5
local SLOT_SIZE = 24
local SLOT_X0 = 8
local SLOT_STEP = 26
local SLOT_Y = 8

local function rgb_key(color)
  return string.format(
    "%02x%02x%02x",
    app.pixelColor.rgbaR(color),
    app.pixelColor.rgbaG(color),
    app.pixelColor.rgbaB(color)
  )
end

local function rgb_of(hex)
  return app.pixelColor.rgba(
    tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16),
    255
  )
end

local function is_same_rgb(a, b)
  return rgb_key(a) == rgb_key(b)
end

local function verify(img)
  local palette = {}
  for _, color in pairs(H.C) do
    palette[rgb_key(color)] = true
  end

  local counts = {}
  local off_palette = {}
  local alpha_min, alpha_max = 255, 0
  local partial_alpha = 0
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local color = img:getPixel(x, y)
      local alpha = app.pixelColor.rgbaA(color)
      if alpha < alpha_min then alpha_min = alpha end
      if alpha > alpha_max then alpha_max = alpha end
      if alpha ~= 0 and alpha ~= 255 then
        partial_alpha = partial_alpha + 1
      end
      if alpha ~= 0 then
        local key = rgb_key(color)
        counts[key] = (counts[key] or 0) + 1
        if not palette[key] then
          off_palette[key] = (off_palette[key] or 0) + 1
        end
      end
    end
  end

  -- The outer rectangle is the whole silhouette: every border cell must be
  -- the 1 px outline.
  local outline = H.C.outline
  local broken_border = 0
  for x = 0, W - 1 do
    if not is_same_rgb(img:getPixel(x, 0), outline) then broken_border = broken_border + 1 end
    if not is_same_rgb(img:getPixel(x, HEIGHT - 1), outline) then broken_border = broken_border + 1 end
  end
  for y = 0, HEIGHT - 1 do
    if not is_same_rgb(img:getPixel(0, y), outline) then broken_border = broken_border + 1 end
    if not is_same_rgb(img:getPixel(W - 1, y), outline) then broken_border = broken_border + 1 end
  end

  -- Slot wells must be exactly where the brief places them, with all four
  -- border cells in outline (the well is fully enclosed, never floating).
  local slot_errors = 0
  for i = 0, SLOT_COUNT - 1 do
    local x = SLOT_X0 + SLOT_STEP * i
    for sx = x, x + SLOT_SIZE - 1 do
      if not is_same_rgb(img:getPixel(sx, SLOT_Y), outline) then slot_errors = slot_errors + 1 end
      if not is_same_rgb(img:getPixel(sx, SLOT_Y + SLOT_SIZE - 1), outline) then slot_errors = slot_errors + 1 end
    end
    for sy = SLOT_Y, SLOT_Y + SLOT_SIZE - 1 do
      if not is_same_rgb(img:getPixel(x, sy), outline) then slot_errors = slot_errors + 1 end
      if not is_same_rgb(img:getPixel(x + SLOT_SIZE - 1, sy), outline) then slot_errors = slot_errors + 1 end
    end
    if not is_same_rgb(img:getPixel(x + 1, SLOT_Y + 1), H.C.well_shadow) then slot_errors = slot_errors + 1 end
    if not is_same_rgb(img:getPixel(x + SLOT_SIZE - 2, SLOT_Y + SLOT_SIZE - 2), H.C.well_rim) then slot_errors = slot_errors + 1 end
    if not is_same_rgb(img:getPixel(x + SLOT_SIZE / 2, SLOT_Y + SLOT_SIZE / 2), H.C.well_floor) then slot_errors = slot_errors + 1 end
  end

  local keys = {}
  for key in pairs(counts) do table.insert(keys, key) end
  table.sort(keys)
  print(string.format("hotbar size=%dx%d", img.width, img.height))
  print(string.format("hotbar alpha_min=%d alpha_max=%d partial_alpha=%d", alpha_min, alpha_max, partial_alpha))
  print(string.format("hotbar border_violations=%d slot_violations=%d", broken_border, slot_errors))
  for _, key in ipairs(keys) do
    print(string.format("  color #%s count=%d", key:upper(), counts[key]))
  end
  local off_keys = {}
  for key in pairs(off_palette) do table.insert(off_keys, key) end
  if #off_keys == 0 then
    print("hotbar off_palette=0")
  else
    for _, key in ipairs(off_keys) do
      print(string.format("hotbar OFF_PALETTE #%s count=%d", key:upper(), off_palette[key]))
    end
  end
end

local spr = H.sprite("hotbar", W, HEIGHT)
local img = spr.cels[1].image

H.panel(img, W, HEIGHT)
H.screw(img, 3, 3)
H.screw(img, W - 8, 3)
H.screw(img, 3, HEIGHT - 8)
H.screw(img, W - 8, HEIGHT - 8)

for i = 0, SLOT_COUNT - 1 do
  H.well(img, SLOT_X0 + SLOT_STEP * i, SLOT_Y, SLOT_SIZE, SLOT_SIZE)
end

verify(img)

spr:saveAs(ROOT .. "/hud_hotbar.aseprite")
spr:saveCopyAs(ROOT .. "/hud_hotbar_1x.png")
print("saved " .. spr.filename)
print("runtime_png=" .. RUNTIME_DIR .. "/hud_hotbar.png")
