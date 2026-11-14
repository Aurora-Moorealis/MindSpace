-- Suelo lunar: un unico regolito oscuro + minerales como prop.
--   art/tiles/ground/ground_atlas.aseprite   64x32 (4x2 de 16x16, 8 variantes)
--   game/content/map/tiles/ground_atlas.png  128x64 (x2)
--   art/tiles/ground/minerals.aseprite       64x16 (4 calcas de 16x16)
--   game/content/map/props/minerals.png      128x32 (x2)
--   art/tiles/ground/rocks.aseprite          96x48
--   game/content/map/props/rocks.png         192x96 (x2)
-- Aseprite -b --script build-ground.lua

local ROOT = "C:/Users/ramer/Documents/Proyects/MindSpace"
local DIR = ROOT .. "/art/tiles/ground"

local function rgba(h)
  return app.pixelColor.rgba(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16), 255)
end

-- regolito oscuro, gris calido y apagado (no beige, no azulado)
local R1, R2, R3, R4 = rgba("8b8884"), rgba("726f6b"), rgba("585551"), rgba("403e3b")
-- minerales
local M1, M2, M3     = rgba("55607a"), rgba("343a4c"), rgba("1f2331")
local S1, S2, S3     = rgba("ddd5be"), rgba("b8ae92"), rgba("8c846c")
local W1, W2, W3     = rgba("c4d8df"), rgba("8faab4"), rgba("5c7680")
local B1, B2, B3     = rgba("44444e"), rgba("2e2e36"), rgba("1e1e25")
local MET, METD      = rgba("a9b6c4"), rgba("6a7684")
local OUT            = rgba("0f171f")

local T = 16
local cur, ox, oy

local seed = 20261114
local function rnd()
  seed = (seed * 1103515245 + 12345) % 2147483648
  return seed / 2147483648
end
local function ri(a, b) return a + math.floor(rnd() * (b - a + 1)) end

local BAYER = { { 0, 8, 2, 10 }, { 12, 4, 14, 6 }, { 3, 11, 1, 9 }, { 15, 7, 13, 5 } }
local function bayer(x, y) return (BAYER[(y % 4) + 1][(x % 4) + 1] + 0.5) / 16 end

local function p(x, y, c)
  local ax, ay = ox + x, oy + y
  if ax >= 0 and ax < cur.width and ay >= 0 and ay < cur.height then
    cur:putPixel(ax, ay, c)
  end
end
local function box(x0, y0, x1, y1, c)
  for y = y0, y1 do for x = x0, x1 do p(x, y, c) end end
end
local function speckle(c, n, m)
  for _ = 1, n do p(ri(m, T - 1 - m), ri(m, T - 1 - m), c) end
end

-- ---------------------------------------------------------------- regolito
local G = {}

local function base_soil() box(0, 0, T - 1, T - 1, R2) end

function G.flat()
  base_soil()
  speckle(R1, 4, 1)
  speckle(R3, 3, 1)
end

function G.fine()
  base_soil()
  for _ = 1, 12 do p(ri(0, T - 1), ri(0, T - 1), R1) end
  for _ = 1, 5 do p(ri(0, T - 1), ri(0, T - 1), R3) end
end

function G.pebbles()
  base_soil()
  for _, q in ipairs({ {4, 5}, {10, 9}, {12, 3}, {6, 12} }) do
    local x, y = q[1], q[2]
    p(x, y, R3)
    p(x, y + 1, R4)
    p(x + 1, y, R1)
  end
end

function G.pebbles_sparse()
  base_soil()
  for _, q in ipairs({ {3, 11}, {13, 6} }) do
    p(q[1], q[2], R3)
    p(q[1], q[2] + 1, R4)
  end
end

function G.dust()
  base_soil()
  for y = 4, 11 do
    for x = 4, 11 do
      local dx, dy = (x - 7.5) / 4.0, (y - 7.5) / 3.6
      local d = dx * dx + dy * dy
      if d <= 1 and bayer(x, y) < (1.1 - d) then p(x, y, R1) end
    end
  end
end

function G.tracks()
  base_soil()
  local function foot(x, y)
    p(x, y, R3)
    p(x + 1, y + 1, R4)
    p(x, y + 2, R3)
  end
  foot(3, 3); foot(9, 7); foot(4, 11)
end

function G.compacted()
  base_soil()
  for y = 4, T - 4, 5 do
    for x = 1, T - 2 do
      if bayer(x, y) < 0.5 then p(x, y, R3) end
    end
  end
end

function G.removed()
  base_soil()
  speckle(R3, 6, 1)
  for _, q in ipairs({ {4, 5}, {9, 8} }) do
    p(q[1], q[2], R3)
    p(q[1] + 1, q[2], R4)
  end
end

local ORDER = {
  { G.flat, G.fine, G.pebbles, G.pebbles_sparse },
  { G.dust, G.tracks, G.compacted, G.removed },
}

-- ---------------------------------------------------------------- guardado
local function scale2(img)
  local big = Image(img.width * 2, img.height * 2, ColorMode.RGB)
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local c = img:getPixel(x, y)
      for dy = 0, 1 do for dx = 0, 1 do big:putPixel(x * 2 + dx, y * 2 + dy, c) end end
    end
  end
  return big
end

local function savePng(img, path)
  local big = scale2(img)
  local spr = Sprite(big.width, big.height, ColorMode.RGB)
  local lay = spr:newLayer(); lay.name = "art"
  spr:deleteLayer(spr.layers[1])
  spr:newCel(lay, 1, big, Point(0, 0))
  spr:saveCopyAs(path)
end

local function saveMaster(img, path)
  local spr = Sprite(img.width, img.height, ColorMode.RGB)
  local lay = spr:newLayer(); lay.name = "art"
  spr:deleteLayer(spr.layers[1])
  spr:newCel(lay, 1, img, Point(0, 0))
  spr:saveAs(path)
end

local atlas = Image(4 * T, 2 * T, ColorMode.RGB)
cur = atlas
for row = 1, 2 do
  for col = 1, 4 do
    ox, oy = (col - 1) * T, (row - 1) * T
    ORDER[row][col]()
  end
end
saveMaster(atlas, DIR .. "/ground_atlas.aseprite")
savePng(atlas, ROOT .. "/game/content/map/tiles/ground_atlas.png")

-- QA del campo: 8x6 losetas mezcladas
local qa = Image(8 * T, 6 * T, ColorMode.RGB)
for ry = 0, 5 do
  for rx = 0, 7 do
    local v = ri(0, 7)
    local sx, sy = (v % 4) * T, math.floor(v / 4) * T
    for y = 0, T - 1 do
      for x = 0, T - 1 do
        qa:putPixel(rx * T + x, ry * T + y, atlas:getPixel(sx + x, sy + y))
      end
    end
  end
end
savePng(qa, DIR .. "/_qa-campo.png")

-- ---------------------------------------------------------------- minerales (motas)
-- Puntos pequenos con un destello: resaltan sobre el regolito oscuro sin
-- taparlo con un bloque de color.
local minerals = Image(4 * T, T, ColorMode.RGB)
cur = minerals

local GLINT = rgba("dfe8f0")

local function free(x, y, r)
  for dy = -r, r do
    for dx = -r, r do
      local ax, ay = ox + x + dx, oy + y + dy
      if ax < 0 or ax >= cur.width or ay < 0 or ay >= cur.height then return false end
      if app.pixelColor.rgbaA(cur:getPixel(ax, ay)) ~= 0 then return false end
    end
  end
  return true
end

-- pepita de 2x2: brillo arriba-izquierda, cuerpo y sombra abajo-derecha
local function specks(cMain, cDark, cGlint, count)
  local placed = 0
  local guard = 0
  while placed < count and guard < count * 25 do
    guard = guard + 1
    local x = ri(1, T - 4)
    local y = ri(1, T - 4)
    if free(x, y, 1) then
      p(x, y, cGlint)
      p(x + 1, y, cMain)
      p(x, y + 1, cMain)
      p(x + 1, y + 1, cDark)
      placed = placed + 1
    end
  end
end

-- 0: ilmenita (metalica, brillo de metal)
ox, oy = 0, 0
specks(M1, M3, MET, 7)

-- 1: silicico (crema palida, brillo blanco)
ox, oy = T, 0
specks(S1, S3, GLINT, 6)

-- 2: hielo de agua (azul palido, brillo blanco)
ox, oy = 2 * T, 0
specks(W1, W3, GLINT, 6)

-- 3: basalto (grano oscuro con brillo apagado)
ox, oy = 3 * T, 0
specks(B1, B3, METD, 7)

saveMaster(minerals, DIR .. "/minerals.aseprite")
savePng(minerals, ROOT .. "/game/content/map/props/minerals.png")

-- ---------------------------------------------------------------- rocas
local rocks = Image(96, 48, ColorMode.RGB)

local function drawRock(img, cx, cy, r, ramp)
  local base, light, shade = ramp[1], ramp[2], ramp[3]
  local mask = {}
  local function inside(x, y)
    local dx, dy = x - cx, y - cy
    local d = math.sqrt(dx * dx + dy * dy) / r
    local a = math.atan(dy, dx)
    local n = 0.84 + 0.12 * math.sin(a * 3.1 + cx * 0.7) + 0.06 * math.sin(a * 5.7 + cy * 0.5)
    return d <= n
  end
  for y = math.floor(cy - r - 2), math.ceil(cy + r + 2) do
    for x = math.floor(cx - r - 2), math.ceil(cx + r + 2) do
      if inside(x, y) then
        local dx, dy = (x - cx) / r, (y - cy) / r
        local c = base
        if dx + dy < -0.55 then c = light elseif dx + dy > 0.45 then c = shade end
        img:putPixel(x, y, c)
        mask[x .. "," .. y] = true
      end
    end
  end
  for y = math.floor(cy - r - 2), math.ceil(cy + r + 2) do
    for x = math.floor(cx - r - 2), math.ceil(cx + r + 2) do
      if not mask[x .. "," .. y] then
        local n = mask[(x - 1) .. "," .. y] or mask[(x + 1) .. "," .. y]
          or mask[x .. "," .. (y - 1)] or mask[x .. "," .. (y + 1)]
        if n then img:putPixel(x, y, OUT) end
      end
    end
  end
end

drawRock(rocks, 12, 12, 6.2, { R2, R1, R3 })
drawRock(rocks, 32, 11, 7.0, { B2, B1, B3 })
drawRock(rocks, 52, 13, 5.2, { R2, R1, R3 })
drawRock(rocks, 70, 11, 6.4, { R1, R1, R2 })
drawRock(rocks, 88, 13, 5.4, { B2, B1, B3 })
drawRock(rocks, 14, 36, 7.2, { R2, R1, R3 })

for _, q in ipairs({ {44, 32}, {48, 34}, {60, 36}, {64, 33}, {78, 34}, {82, 38} }) do
  rocks:putPixel(q[1], q[2], R1)
  rocks:putPixel(q[1] + 1, q[2], R3)
  rocks:putPixel(q[1], q[2] + 1, R4)
end

saveMaster(rocks, DIR .. "/rocks.aseprite")
savePng(rocks, ROOT .. "/game/content/map/props/rocks.png")

print("OK suelo oscuro 4x2 + calcas + rocas")
