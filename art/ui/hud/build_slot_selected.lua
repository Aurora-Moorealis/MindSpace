-- Generates the selected-slot frame: a 24x24 tile that replaces a slot well
-- and sits behind the item. 1 px outline, 2 px teal bevel lit from the
-- top-left, and an opaque 18x18 floor (16x16 item + 1 px margin per side).
-- Art is 24x24 (1x grid); the runtime PNG is exported at 2x (48x48).
--   Aseprite.exe -b --script build_slot_selected.lua
--
-- Contract: art/ui/hud/HUD-BRIEF.md and openspec/specs/art-style/spec.md.

local ROOT = "C:/Users/ramer/Documents/Proyects/MindSpace/art/ui/hud"
local RUNTIME_DIR = "C:/Users/ramer/Documents/Proyects/MindSpace/game/assets/images/ui/hud"
local H = dofile(ROOT .. "/hud_common.lua")

local SIZE = 24
local RING = 3
local CENTER = SIZE - RING * 2

local function rgb_key(color)
  return string.format(
    "%02x%02x%02x",
    app.pixelColor.rgbaR(color),
    app.pixelColor.rgbaG(color),
    app.pixelColor.rgbaB(color)
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
  local opaque = 0
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
        opaque = opaque + 1
        local key = rgb_key(color)
        counts[key] = (counts[key] or 0) + 1
        if not palette[key] then
          off_palette[key] = (off_palette[key] or 0) + 1
        end
      end
    end
  end

  -- Outer silhouette: every border cell is the 1 px outline.
  local broken_border = 0
  for i = 0, SIZE - 1 do
    if not is_same_rgb(img:getPixel(i, 0), H.C.outline) then broken_border = broken_border + 1 end
    if not is_same_rgb(img:getPixel(i, SIZE - 1), H.C.outline) then broken_border = broken_border + 1 end
    if not is_same_rgb(img:getPixel(0, i), H.C.outline) then broken_border = broken_border + 1 end
    if not is_same_rgb(img:getPixel(SIZE - 1, i), H.C.outline) then broken_border = broken_border + 1 end
  end

  -- Frame is 3 px on every side: outline + 2 px teal.
  local frame_errors = 0
  local mid = SIZE / 2
  local left = { img:getPixel(0, mid), img:getPixel(1, mid), img:getPixel(2, mid) }
  local right = { img:getPixel(SIZE - 3, mid), img:getPixel(SIZE - 2, mid), img:getPixel(SIZE - 1, mid) }
  local top = { img:getPixel(mid, 0), img:getPixel(mid, 1), img:getPixel(mid, 2) }
  local bottom = { img:getPixel(mid, SIZE - 3), img:getPixel(mid, SIZE - 2), img:getPixel(mid, SIZE - 1) }
  if not is_same_rgb(left[1], H.C.outline) or not is_same_rgb(left[2], H.C.teal_light) or not is_same_rgb(left[3], H.C.teal_light) then frame_errors = frame_errors + 1 end
  if not is_same_rgb(right[1], H.C.teal_dark) or not is_same_rgb(right[2], H.C.teal_dark) or not is_same_rgb(right[3], H.C.outline) then frame_errors = frame_errors + 1 end
  if not is_same_rgb(top[1], H.C.outline) or not is_same_rgb(top[2], H.C.teal_light) or not is_same_rgb(top[3], H.C.teal_light) then frame_errors = frame_errors + 1 end
  if not is_same_rgb(bottom[1], H.C.teal_dark) or not is_same_rgb(bottom[2], H.C.teal_dark) or not is_same_rgb(bottom[3], H.C.outline) then frame_errors = frame_errors + 1 end

  -- Interior: exactly 18x18 opaque well floor.
  local interior_errors = 0
  local interior_pixels = 0
  for y = RING, SIZE - RING - 1 do
    for x = RING, SIZE - RING - 1 do
      interior_pixels = interior_pixels + 1
      if not is_same_rgb(img:getPixel(x, y), H.C.well_floor) then interior_errors = interior_errors + 1 end
    end
  end

  local keys = {}
  for key in pairs(counts) do table.insert(keys, key) end
  table.sort(keys)
  print(string.format("slot_selected size=%dx%d frame=%dpx interior=%dx%d", img.width, img.height, RING, CENTER, CENTER))
  print(string.format("slot_selected opaque=%d alpha_min=%d alpha_max=%d partial_alpha=%d", opaque, alpha_min, alpha_max, partial_alpha))
  print(string.format("slot_selected border_violations=%d frame_errors=%d interior=%d errors=%d", broken_border, frame_errors, interior_pixels, interior_errors))
  for _, key in ipairs(keys) do
    print(string.format("  color #%s count=%d", key:upper(), counts[key]))
  end
  local off_keys = {}
  for key in pairs(off_palette) do table.insert(off_keys, key) end
  if #off_keys == 0 then
    print("slot_selected off_palette=0")
  else
    for _, key in ipairs(off_keys) do
      print(string.format("slot_selected OFF_PALETTE #%s count=%d", key:upper(), off_palette[key]))
    end
  end
end

local spr = H.sprite("selected", SIZE, SIZE)
local img = spr.cels[1].image

-- 1 px outer outline, then the 2 px teal bevel lit from the top-left.
H.rect(img, 0, 0, SIZE - 1, SIZE - 1, H.C.outline)
H.rect(img, 1, 1, SIZE - 2, SIZE - 2, H.C.teal_light)
H.rect(img, SIZE - 3, 1, SIZE - 2, SIZE - 2, H.C.teal_dark)
H.rect(img, 1, SIZE - 3, SIZE - 2, SIZE - 2, H.C.teal_dark)
-- Opaque 18x18 floor so the item reads with a 1 px margin on every side.
H.rect(img, RING, RING, SIZE - RING - 1, SIZE - RING - 1, H.C.well_floor)

verify(img)

spr:saveAs(ROOT .. "/hud_slot_selected.aseprite")
spr:saveCopyAs(ROOT .. "/hud_slot_selected_1x.png")
print("saved " .. spr.filename)
print("runtime_png=" .. RUNTIME_DIR .. "/hud_slot_selected.png")
