-- Shared palette and construction helpers for the in-game HUD.
-- Contract: openspec/specs/art-style/spec.md
-- Reference panel recipe: art/ui/build-buttons.lua (same bevel + screws language).
--
-- Everything is drawn at 1x art resolution (425x240 grid). The runtime PNG is
-- exported at 2x (850x480 canvas) with nearest neighbour, so one art pixel is a
-- 2x2 block on screen.

local H = {}

local function rgba(hex)
  return app.pixelColor.rgba(
    tonumber(hex:sub(1, 2), 16),
    tonumber(hex:sub(3, 4), 16),
    tonumber(hex:sub(5, 6), 16),
    255
  )
end

H.C = {
  -- Outline (art-style spec)
  outline = rgba("0f171f"),
  -- HUD panel: dark navy body with a metal rim, same construction as the buttons
  body = rgba("26334f"),
  bevel_light = rgba("3d5175"),
  bevel_dark = rgba("1b2540"),
  rim_light = rgba("92a1b2"),
  rim_dark = rgba("6a7684"),
  -- Recessed well (hotbar slot, health track)
  well_floor = rgba("14192b"),
  well_shadow = rgba("081542"),
  well_rim = rgba("1f3152"),
  -- Corner screws
  screw_ring = rgba("5f6b78"),
  screw_head = rgba("a9b6c4"),
  screw_glint = rgba("dfe8f0"),
  screw_shadow = rgba("6a7684"),
  -- Teal ramp: interactive / selected
  teal_light = rgba("57c8cc"),
  teal = rgba("4aa8b4"),
  teal_dark = rgba("2a7f8b"),
  -- Fire + amber ramps: health / danger
  fire_light = rgba("ffc93c"),
  fire = rgba("e2551b"),
  fire_dark = rgba("9c5f0c"),
  amber_light = rgba("ffe27a"),
  amber = rgba("f0a72a"),
  amber_dark = rgba("9c5f0c"),
  -- Separator between health segments
  gap = rgba("1b2540"),
}

function H.rect(img, x0, y0, x1, y1, color)
  for y = y0, y1 do
    for x = x0, x1 do
      if x >= 0 and x < img.width and y >= 0 and y < img.height then
        img:putPixel(x, y, color)
      end
    end
  end
end

-- Flat panel: 1 px outline, 1 px metal rim, navy body with a 1 px inner bevel.
-- Light comes from the top-left.
function H.panel(img, w, h)
  H.rect(img, 0, 0, w - 1, h - 1, H.C.outline)
  H.rect(img, 1, 1, w - 2, h - 2, H.C.body)
  H.rect(img, 1, 1, w - 2, 1, H.C.rim_light)
  H.rect(img, 1, 1, 1, h - 2, H.C.rim_light)
  H.rect(img, 1, h - 2, w - 2, h - 2, H.C.rim_dark)
  H.rect(img, w - 2, 1, w - 2, h - 2, H.C.rim_dark)
  H.rect(img, 2, 2, w - 3, 2, H.C.bevel_light)
  H.rect(img, 2, 2, 2, h - 3, H.C.bevel_light)
  H.rect(img, 2, h - 3, w - 3, h - 3, H.C.bevel_dark)
  H.rect(img, w - 3, 2, w - 3, h - 3, H.C.bevel_dark)
end

-- Recessed well: dark floor, shadow on the top-left, rim light on the bottom-right.
function H.well(img, x, y, w, h)
  H.rect(img, x, y, x + w - 1, y + h - 1, H.C.outline)
  H.rect(img, x + 1, y + 1, x + w - 2, y + h - 2, H.C.well_floor)
  H.rect(img, x + 1, y + 1, x + w - 2, y + 1, H.C.well_shadow)
  H.rect(img, x + 1, y + 1, x + 1, y + h - 2, H.C.well_shadow)
  H.rect(img, x + 1, y + h - 2, x + w - 2, y + h - 2, H.C.well_rim)
  H.rect(img, x + w - 2, y + 1, x + w - 2, y + h - 2, H.C.well_rim)
end

-- 5x5 corner screw: dark ring, metal head, glint top-left, shadow bottom-right.
function H.screw(img, ox, oy)
  local pattern = {
    { 0, 1, 1, 1, 0 },
    { 1, 2, 2, 2, 1 },
    { 1, 2, 3, 2, 1 },
    { 1, 2, 2, 4, 1 },
    { 0, 1, 1, 4, 0 },
  }
  local colors = {
    [0] = nil,
    [1] = H.C.screw_ring,
    [2] = H.C.screw_head,
    [3] = H.C.screw_glint,
    [4] = H.C.screw_shadow,
  }
  for y = 0, 4 do
    for x = 0, 4 do
      local code = pattern[y + 1][x + 1]
      if code ~= 0 then
        img:putPixel(ox + x, oy + y, colors[code])
      end
    end
  end
end

-- Empty RGB sprite with one opaque-capable layer holding `img`.
function H.sprite(name, w, h)
  local spr = Sprite(w, h, ColorMode.RGB)
  local img = Image(w, h, ColorMode.RGB)
  local layer = spr:newLayer()
  layer.name = name
  spr:newCel(layer, 1, img, Point(0, 0))
  spr:deleteLayer(spr.layers[1])
  return spr, img
end

return H
