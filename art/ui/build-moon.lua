-- Luna pequena para la intro. 56x56 con sombreado duro y crateres.
--   Aseprite -b --script build-moon.lua

local OUT_DIR = "C:/Users/ramer/Documents/Proyects/MindSpace/game/assets/images/intro"
local W, H = 56, 56
local CX, CY, R = 27.5, 27.5, 26.0

local function rgba(h)
  return app.pixelColor.rgba(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16), 255)
end

local LIGHT = rgba("cfccc7")
local BASE  = rgba("aaa7a2")
local SHADE = rgba("85827e")
local DEEP  = rgba("67645f")

local img = Image(W, H, ColorMode.RGB)

local function p(x, y, c)
  if x >= 0 and x < W and y >= 0 and y < H then img:putPixel(x, y, c) end
end

-- disco con luz arriba-izquierda
for y = 0, H - 1 do
  for x = 0, W - 1 do
    local dx, dy = x - CX, y - CY
    local d = math.sqrt(dx * dx + dy * dy)
    if d <= R then
      local c = BASE
      if dx + dy < -6 then c = LIGHT
      elseif dx + dy > 4 or d > R - 3.5 then c = SHADE end
      p(x, y, c)
    elseif d <= R + 1 then
      p(x, y, DEEP)
    end
  end
end

-- crateres: cuerpo hundido con borde iluminado arriba-izquierda
local craters = {
  { 19, 17, 4 },
  { 33, 22, 3 },
  { 24, 33, 5 },
  { 38, 36, 2 },
  { 14, 29, 2 },
  { 30, 12, 2 },
}
for _, c in ipairs(craters) do
  local cx, cy, r = c[1], c[2], c[3]
  for y = cy - r, cy + r do
    for x = cx - r, cx + r do
      local dx, dy = x - cx, y - cy
      local d = math.sqrt(dx * dx + dy * dy)
      if d <= r then
        p(x, y, SHADE)
        if d > r - 1.2 and (dx + dy) < 0 then p(x, y, LIGHT) end
        if d < r - 1.2 then p(x, y, DEEP) end
      end
    end
  end
end

local spr = Sprite(W, H, ColorMode.RGB)
local lay = spr:newLayer()
lay.name = "art"
spr:deleteLayer(spr.layers[1])
spr:newCel(lay, 1, img, Point(0, 0))
spr:saveAs(OUT_DIR .. "/moon.aseprite")
spr:saveCopyAs(OUT_DIR .. "/moon.png")
print("OK luna")
