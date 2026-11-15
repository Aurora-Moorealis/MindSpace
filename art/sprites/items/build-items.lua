-- Sample item icons for the 5-slot hotbar: water canister, ration pack and O2
-- cartridge. Art is 16x16 (1x grid); the runtime PNG is produced at 2x (32x32)
-- with ImageMagick nearest-neighbour after this script.
--   Aseprite.exe -b --script build-items.lua
--
-- Contract: openspec/specs/art-style/spec.md and art/ui/hud/HUD-BRIEF.md.
-- Shared palette lives in hud_common.lua (read only, never edited here).

local H = dofile("C:/Users/ramer/Documents/Proyects/MindSpace/art/ui/hud/hud_common.lua")
local ROOT = "C:/Users/ramer/Documents/Proyects/MindSpace/art/sprites/items"
local RUNTIME_DIR = "C:/Users/ramer/Documents/Proyects/MindSpace/game/assets/images/items"

local SIZE = 16

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
  local off_palette = 0
  local partial_alpha = 0
  local opaque = 0
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local color = img:getPixel(x, y)
      local alpha = app.pixelColor.rgbaA(color)
      if alpha ~= 0 and alpha ~= 255 then
        partial_alpha = partial_alpha + 1
      end
      if alpha ~= 0 then
        opaque = opaque + 1
        if not palette[key_of(color)] then
          off_palette = off_palette + 1
        end
      end
    end
  end
  print(string.format("%s opaque=%d off_palette=%d partial_alpha=%d", name, opaque, off_palette, partial_alpha))
  assert(off_palette == 0, name .. " uses colors outside the palette")
  assert(partial_alpha == 0, name .. " has semi-transparent pixels")
end

-- Filled box with the mandatory 1 px outline, light top-left and dark
-- bottom-right, matching the HUD icon language.
local function box(img, x, y, w, h, fill, light, dark)
  H.rect(img, x, y, x + w - 1, y + h - 1, H.C.outline)
  H.rect(img, x + 1, y + 1, x + w - 2, y + h - 2, fill)
  H.rect(img, x + 1, y + 1, x + w - 2, y + 1, light)
  H.rect(img, x + 1, y + 1, x + 1, y + h - 2, light)
  H.rect(img, x + 1, y + h - 2, x + w - 2, y + h - 2, dark)
  H.rect(img, x + w - 2, y + 1, x + w - 2, y + h - 2, dark)
end

local function save(name, draw)
  local spr = H.sprite(name, SIZE, SIZE)
  local img = spr.cels[1].image
  draw(img)
  verify(name, img)
  spr:saveAs(ROOT .. "/" .. name .. ".aseprite")
  spr:saveCopyAs(ROOT .. "/" .. name .. "_1x.png")
  print("saved " .. name .. " (" .. RUNTIME_DIR .. "/" .. name .. ".png)")
end

save("water_canister", function(img)
  -- Body: teal canister with a light left edge and a dark right edge.
  box(img, 4, 4, 8, 11, H.C.teal, H.C.teal_light, H.C.teal_dark)
  -- Label band, one light row and one dark row.
  H.rect(img, 5, 8, 10, 8, H.C.teal_light)
  H.rect(img, 5, 9, 10, 9, H.C.teal_dark)
  -- Metal cap with a bright glint.
  box(img, 5, 0, 6, 5, H.C.screw_head, H.C.screw_glint, H.C.rim_dark)
  H.rect(img, 6, 2, 7, 2, H.C.screw_glint)
end)

save("ration_pack", function(img)
  -- Amber pouch with a folded top and a white label.
  box(img, 3, 3, 10, 11, H.C.amber, H.C.amber_light, H.C.amber_dark)
  H.rect(img, 4, 5, 11, 5, H.C.amber_light)
  H.rect(img, 4, 6, 11, 6, H.C.amber_dark)
  H.rect(img, 6, 8, 9, 9, H.C.screw_glint)
  H.rect(img, 6, 10, 9, 10, H.C.amber_dark)
  -- Folded tab on top, connected to the body.
  box(img, 6, 1, 4, 3, H.C.amber, H.C.amber_light, H.C.amber_dark)
end)

save("oxygen_cartridge", function(img)
  -- Grey cylinder with a teal band and a narrow valve.
  box(img, 4, 4, 8, 11, H.C.screw_head, H.C.screw_glint, H.C.rim_dark)
  H.rect(img, 5, 7, 10, 8, H.C.teal)
  H.rect(img, 5, 7, 5, 8, H.C.teal_light)
  H.rect(img, 10, 7, 10, 8, H.C.teal_dark)
  -- Valve on top.
  box(img, 6, 0, 4, 5, H.C.screw_head, H.C.screw_glint, H.C.rim_dark)
  H.rect(img, 7, 2, 7, 2, H.C.screw_glint)
end)
