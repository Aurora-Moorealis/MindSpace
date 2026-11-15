-- Lámina de diseño de la base (no es arte final del juego todavía).
--   art/tiles/base/base_plan.aseprite   425x240, 3 frames
--     1 = corte interior, 2 = cerrada, 3 = techo transparente
--   art/tiles/base/roof_atlas.aseprite  64x80 (5 filas de 4 losetas de 16x16)
--   game/content/map/tiles/roof_atlas.png  128x160 (x2)
--   art/tiles/base/_plan-1-corte.png    850x480 (x2)
--   art/tiles/base/_plan-2-techo.png    850x480 (x2)
--   art/tiles/base/_plan-3-transparente.png 850x480 (x2)
--
-- Según docs/designs/junior-astronauta-outpost-lunar.md:
--   5 salas: dormitorio-almacén, invernadero, energía, taller y comunicaciones.
--   8 máquinas + batería/cables (energy-grid): O2, reciclador, hidropónica,
--   consola, banco, refugio, luces y panel solar exterior.
--   "pasillos presurizados" + "un nodo airlock define el límite de reglas":
--   esclusa 2x2 con puerta interior y puerta exterior.
--   Exterior: el panel solar queda fuera, junto a la esclusa.
-- Según docs/art-direction.md: consolas 2x1, cajas/plantas 1x1, puertas 2x2
--   (aquí la esclusa 2x2; las puertas de sala usan el marco de 1 loseta ya
--   existente en el tileset).
--
-- Composición: 19x14 losetas (608x448 px de pantalla) en (8,8). Panel solar
-- fuera, al este de la sala de energía, con cable que entra por el muro hasta
-- la batería. Cabe entera en la cámara de 850x480 junto al panel.

local ROOT = "C:/Users/ramer/Documents/Proyects/MindSpace"
local WT = "C:/Users/ramer/Documents/Proyects/MindSpace-worktrees/connect-playable-loop"

local function rgba(h)
  return app.pixelColor.rgba(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16),
                             tonumber(h:sub(5, 6), 16), 255)
end

local OUT = rgba("0f171f")
local C1  = rgba("dfe8f0")
local C2  = rgba("bcc9d6")
local C3  = rgba("92a1b2")
local C4  = rgba("7b8794")
local C5  = rgba("64707e")
local C6  = rgba("5f6b78")
local M1  = rgba("a9b6c4")
local M2  = rgba("6a7684")
local E1  = rgba("57c8cc")
local E2  = rgba("4aa8b4")
local E3  = rgba("2f9fa6")
local E4  = rgba("2a7f8b")
local E5  = rgba("186269")
local A1  = rgba("ffe27a")
local A2  = rgba("f0a72a")
local A3  = rgba("9c5f0c")
local N1  = rgba("3d5175")
local N2  = rgba("26334f")
local N3  = rgba("1b2540")

local T = 16
local GROUND_MARE = rgba("585551")
local GROUND_DARK = rgba("403e3b")

-- =====================================================================
-- utilidades
-- =====================================================================
local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then
    img:putPixel(x, y, c)
  end
end

local function box(img, x0, y0, x1, y1, c)
  for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

local function stud(img, x, y, c1, c2, c3)
  put(img, x, y, c1); put(img, x + 1, y, c2)
  put(img, x, y + 1, c2); put(img, x + 1, y + 1, c3)
end

local function loadArt(path)
  local spr = app.open(path)
  if not spr then error("no se pudo abrir " .. path) end
  local cel = spr.cels[1]
  if not cel then error("sin cel: " .. path) end
  return {
    spr = spr,
    img = cel.image,
    indexed = spr.colorMode == ColorMode.INDEXED,
    pal = spr.palettes[1],
  }
end

local function pixelAt(art, x, y)
  local c = art.img:getPixel(x, y)
  if art.indexed then
    local col = art.pal:getColor(c)
    if col.alpha == 0 then return nil end
    return app.pixelColor.rgba(col.red, col.green, col.blue, 255)
  end
  if app.pixelColor.rgbaA(c) == 0 then return nil end
  return c
end

local function transformSrc(mode, x, y)
  if mode == nil or mode == "id" then return x, y end
  if mode == "r90" then return y, T - 1 - x end
  if mode == "r180" then return T - 1 - x, T - 1 - y end
  if mode == "r270" then return T - 1 - y, x end
  if mode == "h" then return T - 1 - x, y end
  if mode == "v" then return x, T - 1 - y end
  return x, y
end

local function blitTile(dst, dx, dy, art, sx, sy, mode)
  for y = 0, T - 1 do
    for x = 0, T - 1 do
      local tx, ty = transformSrc(mode, x, y)
      local c = pixelAt(art, sx + tx, sy + ty)
      if c then put(dst, dx + x, dy + y, c) end
    end
  end
end

local function blitTileHalf(dst, dx, dy, art, sx, sy, mode)
  for y = 0, T - 1 do
    for x = 0, T - 1 do
      local tx, ty = transformSrc(mode, x, y)
      local c = pixelAt(art, sx + tx * 2, sy + ty * 2)
      if c then put(dst, dx + x, dy + y, c) end
    end
  end
end

local function blitRegionHalf(dst, dx, dy, art, sx, sy, w, h)
  for y = 0, h / 2 - 1 do
    for x = 0, w / 2 - 1 do
      local c = pixelAt(art, sx + x * 2, sy + y * 2)
      if c then put(dst, dx + x, dy + y, c) end
    end
  end
end

local function saveSprite(img, path, scale)
  local w, h = img.width * scale, img.height * scale
  local out = img
  if scale > 1 then
    out = Image(w, h, ColorMode.RGB)
    for y = 0, img.height - 1 do
      for x = 0, img.width - 1 do
        local c = img:getPixel(x, y)
        for dy = 0, scale - 1 do
          for dx = 0, scale - 1 do
            out:putPixel(x * scale + dx, y * scale + dy, c)
          end
        end
      end
    end
  end
  local spr = Sprite(w, h, ColorMode.RGB)
  local lay = spr:newLayer(); lay.name = "art"
  spr:deleteLayer(spr.layers[1])
  spr:newCel(lay, 1, out, Point(0, 0))
  spr:saveCopyAs(path)
end

local function saveAseprite(img, path)
  local spr = Sprite(img.width, img.height, ColorMode.RGB)
  local lay = spr:newLayer(); lay.name = "art"
  spr:deleteLayer(spr.layers[1])
  spr:newCel(lay, 1, img, Point(0, 0))
  spr:saveAs(path)
end

-- =====================================================================
-- TEJADO: atlas de losetas 4x4 (16x16 de arte)
-- cuerpo de casco en C5, paneles alternos en C4, juntas en N2/C3
-- =====================================================================
local R = {}

local function hullBase(img, ox, oy, c)
  box(img, ox, oy, ox + T - 1, oy + T - 1, c or C5)
end

function R.plate(img, ox, oy)
  hullBase(img, ox, oy)
end

function R.plate_light(img, ox, oy)
  hullBase(img, ox, oy, C4)
end

function R.seam_h(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy + 13, ox + T - 1, oy + 13, C3)
  box(img, ox, oy + 14, ox + T - 1, oy + 14, C6)
  box(img, ox, oy + 15, ox + T - 1, oy + 15, N2)
end

function R.seam_v(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox + 13, oy, ox + 13, oy + T - 1, C3)
  box(img, ox + 14, oy, ox + 14, oy + T - 1, C6)
  box(img, ox + 15, oy, ox + 15, oy + T - 1, N2)
end

function R.rivets(img, ox, oy)
  hullBase(img, ox, oy)
  for _, p in ipairs({ { 2, 2 }, { 12, 2 }, { 2, 12 }, { 12, 12 } }) do
    stud(img, ox + p[1], oy + p[2], C2, C4, C6)
  end
end

function R.vent(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox + 1, oy + 1, ox + 14, oy + 14, C6)
  box(img, ox + 2, oy + 2, ox + 13, oy + 2, C3)
  box(img, ox + 2, oy + 3, ox + 2, oy + 13, C3)
  box(img, ox + 3, oy + 13, ox + 13, oy + 13, N2)
  box(img, ox + 13, oy + 3, ox + 13, oy + 12, N2)
  box(img, ox + 3, oy + 3, ox + 12, oy + 12, N3)
  for _, y in ipairs({ 4, 7, 10 }) do
    box(img, ox + 3, oy + y, ox + 12, oy + y, C5)
    box(img, ox + 3, oy + y + 1, ox + 12, oy + y + 1, C6)
  end
end

function R.hazard(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy + 2, ox + T - 1, oy + 2, OUT)
  for y = 3, 12 do
    for x = 0, T - 1 do
      put(img, ox + x, oy + y, ((x + y) % 8 < 4) and A2 or N3)
    end
  end
  box(img, ox, oy + 13, ox + T - 1, oy + 13, OUT)
end

function R.panel(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox + 2, oy + 2, ox + 13, oy + 13, C6)
  box(img, ox + 3, oy + 3, ox + 12, oy + 3, C3)
  box(img, ox + 3, oy + 4, ox + 3, oy + 12, C3)
  box(img, ox + 3, oy + 12, ox + 12, oy + 12, N2)
  box(img, ox + 12, oy + 4, ox + 12, oy + 12, N2)
  box(img, ox + 6, oy + 7, ox + 9, oy + 8, M2)
  put(img, ox + 4, oy + 4, M1)
end

function R.radiator(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox + 1, oy + 1, ox + 14, oy + 14, C6)
  for i = 0, 4 do
    local x = ox + 2 + i * 3
    box(img, x, oy + 2, x + 1, oy + 13, C2)
    box(img, x + 2, oy + 2, x + 2, oy + 13, N2)
  end
  box(img, ox + 1, oy + 1, ox + 14, oy + 1, C3)
  box(img, ox + 1, oy + 14, ox + 14, oy + 14, N2)
end

function R.rim_n(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy, ox + T - 1, oy, OUT)
  box(img, ox, oy + 1, ox + T - 1, oy + 2, C2)
  box(img, ox, oy + 3, ox + T - 1, oy + 3, C6)
  box(img, ox, oy + 4, ox + T - 1, oy + 4, N2)
end

function R.rim_s(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy + 11, ox + T - 1, oy + 11, C6)
  box(img, ox, oy + 12, ox + T - 1, oy + 12, N2)
  box(img, ox, oy + 13, ox + T - 1, oy + 14, C2)
  box(img, ox, oy + 15, ox + T - 1, oy + 15, OUT)
end

function R.rim_w(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy, ox, oy + T - 1, OUT)
  box(img, ox + 1, oy, ox + 2, oy + T - 1, C2)
  box(img, ox + 3, oy, ox + 3, oy + T - 1, C6)
  box(img, ox + 4, oy, ox + 4, oy + T - 1, N2)
end

function R.rim_e(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox + 11, oy, ox + 11, oy + T - 1, C6)
  box(img, ox + 12, oy, ox + 12, oy + T - 1, N2)
  box(img, ox + 13, oy, ox + 14, oy + T - 1, C2)
  box(img, ox + 15, oy, ox + 15, oy + T - 1, OUT)
end

function R.rim_nw(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy, ox + T - 1, oy, OUT)
  box(img, ox, oy, ox, oy + T - 1, OUT)
  box(img, ox + 1, oy + 1, ox + T - 1, oy + 2, C2)
  box(img, ox + 1, oy + 3, ox + 2, oy + T - 1, C2)
  box(img, ox + 3, oy + 3, ox + 3, oy + T - 1, C6)
  box(img, ox + 3, oy + 3, ox + T - 1, oy + 3, C6)
  box(img, ox + 4, oy + 4, ox + 4, oy + T - 1, N2)
  box(img, ox + 4, oy + 4, ox + T - 1, oy + 4, N2)
end

function R.rim_ne(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy, ox + T - 1, oy, OUT)
  box(img, ox + T - 1, oy, ox + T - 1, oy + T - 1, OUT)
  box(img, ox, oy + 1, ox + T - 2, oy + 2, C2)
  box(img, ox + T - 3, oy + 3, ox + T - 2, oy + T - 1, C2)
  box(img, ox, oy + 3, ox + T - 4, oy + 3, C6)
  box(img, ox + T - 4, oy + 3, ox + T - 4, oy + T - 1, C6)
  box(img, ox, oy + 4, ox + T - 4, oy + 4, N2)
  box(img, ox + T - 5, oy + 4, ox + T - 5, oy + T - 1, N2)
end

function R.rim_sw(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy + T - 1, ox + T - 1, oy + T - 1, OUT)
  box(img, ox, oy, ox, oy + T - 1, OUT)
  box(img, ox + 1, oy, ox + 2, oy + T - 4, C2)
  box(img, ox + 1, oy + T - 4, ox + T - 1, oy + T - 3, C2)
  box(img, ox + 3, oy, ox + 3, oy + T - 4, C6)
  box(img, ox + 3, oy + T - 5, ox + T - 1, oy + T - 5, C6)
  box(img, ox + 4, oy, ox + 4, oy + T - 4, N2)
  box(img, ox + 4, oy + T - 4, ox + T - 1, oy + T - 4, N2)
end

function R.rim_se(img, ox, oy)
  hullBase(img, ox, oy)
  box(img, ox, oy + T - 1, ox + T - 1, oy + T - 1, OUT)
  box(img, ox + T - 1, oy, ox + T - 1, oy + T - 1, OUT)
  box(img, ox + T - 3, oy, ox + T - 2, oy + T - 4, C2)
  box(img, ox, oy + T - 4, ox + T - 2, oy + T - 3, C2)
  box(img, ox + T - 4, oy, ox + T - 4, oy + T - 4, C6)
  box(img, ox, oy + T - 5, ox + T - 4, oy + T - 5, C6)
  box(img, ox + T - 5, oy, ox + T - 5, oy + T - 4, N2)
  box(img, ox, oy + T - 4, ox + T - 4, oy + T - 4, N2)
end

local ROOF_ORDER = {
  { R.plate, R.seam_h, R.seam_v, R.rivets },
  { R.vent, R.hazard, R.panel, R.radiator },
  { R.rim_n, R.rim_e, R.rim_s, R.rim_w },
  { R.rim_nw, R.rim_ne, R.rim_sw, R.rim_se },
  { R.plate_light },
}
local ROOF_AT = {}
for row = 1, #ROOF_ORDER do
  for col = 1, #ROOF_ORDER[row] do
    ROOF_AT[ROOF_ORDER[row][col]] = { ox = (col - 1) * T, oy = (row - 1) * T }
  end
end

local function renderRoofAtlas()
  local img = Image(4 * T, 5 * T, ColorMode.RGB)
  for row = 1, #ROOF_ORDER do
    for col = 1, #ROOF_ORDER[row] do
      ROOF_ORDER[row][col](img, (col - 1) * T, (row - 1) * T)
    end
  end
  return img
end

-- =====================================================================
-- LÁMINA
-- =====================================================================
local CW, CH = 425, 240
local BX, BY = 8, 8
local BW, BH = 19, 14

local base = loadArt(ROOT .. "/art/tiles/base/base_atlas.aseprite")
local ground = loadArt(ROOT .. "/game/content/map/tiles/ground_atlas.png")
local props = loadArt(WT .. "/game/content/map/props/props_atlas.png")
local solar = loadArt(WT .. "/game/content/machines/solar_array/solar_array.png")
local battery = loadArt(WT .. "/game/content/machines/battery/battery.png")
local cable = loadArt(WT .. "/game/content/machines/power_cable/power_cable_atlas.png")
local rack = loadArt(WT .. "/game/content/machines/hydroponics/art/sprites/hydroponics_rack.png")
local tank = loadArt(WT .. "/game/content/machines/hydroponics/art/sprites/nutrient_tank.png")
local roofAtlas = renderRoofAtlas()

local BASE_AT = {
  plate = { 0, 0 }, rivets = { 1, 0 }, vent = { 2, 0 }, diag = { 3, 0 },
  wall = { 0, 1 }, corner = { 1, 1 }, window = { 2, 1 }, door = { 3, 1 },
  corridor = { 0, 2 }, corridor_corner = { 1, 2 }, cross = { 2, 2 }, airlock = { 3, 2 },
  tee = { 0, 3 }, wall_end = { 1, 3 }, trans = { 2, 3 }, grate = { 3, 3 },
}

local function bx(lx) return BX + lx * T end
local function by(ly) return BY + ly * T end

local function baseTile(img, name, lx, ly, mode)
  local at = BASE_AT[name]
  blitTile(img, bx(lx), by(ly), base, at[1] * T, at[2] * T, mode)
end

-- ---------------------------------------------------------------------
-- planta (19 columnas x 14 filas)
--   0..18 columnas, 0..13 filas
--   arriba: taller (1-5) | comms (7-10) | energía (12-17)
--   abajo:  dormitorio-almacén (1-11) | invernadero (13-17)
--   pasillo 6-7 y esclusa 2x2 al este (16-17) con puertas en 15 y 18
-- ---------------------------------------------------------------------
local PLAN = {
  "WWVWWWWVWWWWWVWWWWW", -- 0 norte: ventanas taller / comms / energía
  "W.....W....W......W", -- 1
  "W..r..W..r.W..r...W", -- 2
  "V.....W....W......V", -- 3
  "W.....W....W......W", -- 4
  "WWWDWWWWDWWWWWDWWWW", -- 5 puertas taller / comms / energía
  "WccccccccccccccDgaD", -- 6 pasillo + esclusa
  "WccccccccccccccDgaD", -- 7 pasillo + esclusa
  "WWWWWDWWWDWWWWDWWWW", -- 8 puertas dormitorio x2 / invernadero
  "W...........W.....W", -- 9
  "V..r........W..r..W", -- 10
  "W...........W.....W", -- 11
  "W.....d.....W..d..W", -- 12
  "WWVWWWWWWWVWWWWVWWW", -- 13 sur: ventanas dormitorio / invernadero
}

for i, row in ipairs(PLAN) do
  if #row ~= BW then error("PLAN fila " .. i .. " mide " .. #row .. ", no " .. BW) end
end

local function planAt(x, y)
  if y < 0 or y >= BH or x < 0 or x >= BW then return nil end
  return PLAN[y + 1]:sub(x + 1, x + 1)
end

-- Loseta de muro: el canto iluminado mira al exterior.
local function wallTile(x, y)
  local left, right = (x == 0), (x == BW - 1)
  local top, bottom = (y == 0), (y == BH - 1)
  if top and left then return "corner", "id" end
  if top and right then return "corner", "h" end
  if bottom and left then return "corner", "r270" end
  if bottom and right then return "corner", "r180" end
  if top then return "wall", "id" end
  if bottom then return "wall", "v" end
  if left then return "wall", "r270" end
  if right then return "wall", "r90" end
  return "wall", "id"
end

-- ---------------------------------------------------------------------
-- capas y frames
-- ---------------------------------------------------------------------
local spr = Sprite(CW, CH, ColorMode.RGB)
spr:newEmptyFrame()
spr:newEmptyFrame()
local layerGround = spr:newLayer(); layerGround.name = "ground"
local layerFloor = spr:newLayer(); layerFloor.name = "floor"
local layerWalls = spr:newLayer(); layerWalls.name = "walls"
local layerMachines = spr:newLayer(); layerMachines.name = "machines"
local layerCable = spr:newLayer(); layerCable.name = "cable"
local layerRoof = spr:newLayer(); layerRoof.name = "roof"
local layerLabels = spr:newLayer(); layerLabels.name = "labels"
spr:deleteLayer(spr.layers[1])

local imgGround = Image(CW, CH, ColorMode.RGB)
local imgFloor = Image(CW, CH, ColorMode.RGB)
local imgWalls = Image(CW, CH, ColorMode.RGB)
local imgMachines = Image(CW, CH, ColorMode.RGB)
local imgCable = Image(CW, CH, ColorMode.RGB)
local imgRoof = Image(CW, CH, ColorMode.RGB)

-- ---------------------------------------------------------------------
-- suelo lunar: 3 variantes con hash estable, muestreo a la mitad
-- ---------------------------------------------------------------------
local function hash2(x, y)
  local h = (x * 374761393 + y * 668265263) % 2147483647
  h = (h * 1103515245) % 2147483647
  return h
end

for y = 0, CH - 1 do
  for x = 0, CW - 1 do
    local variant = hash2(math.floor(x / 16), math.floor(y / 16)) % 3
    local sx = variant * 32 + (x % 16) * 2
    local sy = (y % 16) * 2
    local c = pixelAt(ground, sx, sy) or GROUND_MARE
    put(imgGround, x, y, c)
  end
end

-- sombra de casco: banda sólida al sur-este y borde tramado
local margin = 8
for y = BY + margin, BY + BH * T + margin do
  for x = BX + margin, BX + BW * T + margin do
    local inside = x >= BX and x < BX + BW * T and y >= BY and y < BY + BH * T
    if not inside then put(imgGround, x, y, GROUND_DARK) end
  end
end
for y = BY + margin - 3, BY + BH * T + margin + 3 do
  for x = BX + margin - 3, BX + BW * T + margin + 3 do
    local inside = x >= BX and x < BX + BW * T and y >= BY and y < BY + BH * T
    local inBand = x >= BX + margin and x <= BX + BW * T + margin and
                   y >= BY + margin and y <= BY + BH * T + margin
    if not inside and not inBand and ((x + y) % 2 == 0) then
      put(imgGround, x, y, GROUND_DARK)
    end
  end
end

for i, p in ipairs({ { 340, 170 }, { 396, 136 }, { 352, 214 } }) do
  blitRegionHalf(imgGround, p[1], p[2], props, (i - 1) * 32, 0, 32, 32)
end

-- ---------------------------------------------------------------------
-- suelos, muros, puertas y ventanas
-- ---------------------------------------------------------------------
for y = 0, BH - 1 do
  for x = 0, BW - 1 do
    local ch = planAt(x, y)
    if ch == "." or ch == "r" or ch == "v" or ch == "d" then
      local under = "plate"
      if ch == "r" then under = "rivets"
      elseif ch == "v" then under = "vent"
      elseif ch == "d" then under = "diag" end
      baseTile(imgFloor, under, x, y, "id")
    elseif ch == "c" then
      baseTile(imgFloor, "corridor", x, y, "r90")
    elseif ch == "g" then
      baseTile(imgFloor, "grate", x, y, "id")
    elseif ch == "a" then
      baseTile(imgFloor, "airlock", x, y, "r90")
    else
      baseTile(imgFloor, "plate", x, y, "id")
    end
  end
end

for y = 0, BH - 1 do
  for x = 0, BW - 1 do
    local ch = planAt(x, y)
    if ch == "W" then
      local name, mode = wallTile(x, y)
      baseTile(imgWalls, name, x, y, mode)
    elseif ch == "V" then
      local _, mode = wallTile(x, y)
      baseTile(imgWalls, "window", x, y, mode)
    elseif ch == "D" then
      local vertical = planAt(x, y - 1) == "W" and planAt(x, y + 1) == "W"
      baseTile(imgWalls, "door", x, y, vertical and "r90" or "id")
    end
  end
end

-- ---------------------------------------------------------------------
-- máquinas y mobiliario. Escala del art-direction: consolas 2x1, cajas y
-- plantas 1x1; batería 2x3 y rack 3x2 son el arte real del juego.
-- ---------------------------------------------------------------------
local function machineBox(img, x, y, w, h, accent)
  box(img, x, y, x + w - 1, y + h - 1, OUT)
  box(img, x + 1, y + 1, x + w - 2, y + h - 2, C3)
  box(img, x + 1, y + 1, x + w - 2, y + 2, C2)
  box(img, x + 2, y + h - 3, x + w - 3, y + h - 2, C5)
  box(img, x + 1, y + 1, x + 1, y + h - 2, C2)
  box(img, x + w - 2, y + 2, x + w - 2, y + h - 2, C5)
  box(img, x + 3, y + 3, x + w - 4, y + h - 5, N3)
  if accent then
    put(img, x + 4, y + 4, accent)
    put(img, x + 5, y + 4, accent)
    put(img, x + 4, y + 5, accent)
  end
end

local function crate(img, x, y)
  box(img, x, y, x + 15, y + 15, OUT)
  box(img, x + 1, y + 1, x + 14, y + 14, C3)
  box(img, x + 1, y + 1, x + 14, y + 2, C2)
  box(img, x + 1, y + 1, x + 1, y + 14, C2)
  box(img, x + 2, y + 3, x + 13, y + 4, A3)
  box(img, x + 2, y + 11, x + 13, y + 12, A3)
  box(img, x + 3, y + 5, x + 6, y + 10, C4)
  box(img, x + 9, y + 5, x + 12, y + 10, C4)
end

local function plant(img, x, y)
  box(img, x + 5, y + 9, x + 10, y + 14, M2)
  box(img, x + 5, y + 9, x + 10, y + 9, C3)
  put(img, x + 7, y + 4, E3); put(img, x + 8, y + 4, E3)
  put(img, x + 6, y + 5, E3); put(img, x + 7, y + 5, E2); put(img, x + 8, y + 5, E3); put(img, x + 9, y + 5, E3)
  put(img, x + 5, y + 6, E4); put(img, x + 6, y + 6, E3); put(img, x + 7, y + 6, E2); put(img, x + 8, y + 6, E2); put(img, x + 9, y + 6, E3); put(img, x + 10, y + 6, E4)
  put(img, x + 6, y + 7, E4); put(img, x + 7, y + 7, E3); put(img, x + 8, y + 7, E3); put(img, x + 9, y + 7, E4)
  put(img, x + 7, y + 8, E5); put(img, x + 8, y + 8, E5)
end

-- taller: banco de reparación 2x1
machineBox(imgMachines, bx(2) + 8, by(2) + 12, 32, 16, A2)
-- comunicaciones: consola 2x1
machineBox(imgMachines, bx(7) + 12, by(2) + 12, 32, 16, E2)
-- energía: cuadro 2x1 + batería 2x3
machineBox(imgMachines, bx(12) + 4, by(1) + 6, 32, 16, E2)
blitRegionHalf(imgMachines, bx(14) + 8, by(1) + 6, battery, 0, 0, battery.img.width, battery.img.height)
-- invernadero: rack 3x2 + tanque 1x2 + plantas 1x1
blitRegionHalf(imgMachines, bx(13), by(9) + 8, rack, 0, 0, rack.img.width, rack.img.height)
blitRegionHalf(imgMachines, bx(17), by(10) + 8, tank, 0, 0, tank.img.width, tank.img.height)
plant(imgMachines, bx(13) + 8, by(12) + 2)
plant(imgMachines, bx(14) + 8, by(12) + 2)
plant(imgMachines, bx(15) + 8, by(12) + 2)
-- dormitorio-almacén: O2 (2x1), reciclador (2x1), refugio (2x2), cajas (1x1)
machineBox(imgMachines, bx(1) + 8, by(9) + 10, 32, 16, E2)
machineBox(imgMachines, bx(4) + 8, by(9) + 10, 32, 16, E2)
machineBox(imgMachines, bx(7) + 4, by(9) + 8, 32, 32, A2)
crate(imgMachines, bx(10) + 8, by(9) + 8)
crate(imgMachines, bx(10) + 8, by(10) + 8)
crate(imgMachines, bx(11) + 2, by(11) + 4)
-- pasillo: cuadro de luces 2x1 al oeste
machineBox(imgMachines, bx(1) + 8, by(6) + 8, 32, 16, A2)

-- astronauta de referencia (frame abajo), a escala de arte
local astronaut = loadArt(WT .. "/game/content/entities/astronaut/astronaut_4dir.png")
blitRegionHalf(imgMachines, 200, 110, astronaut, 0, 0, 32, 32)

-- ---------------------------------------------------------------------
-- cable: panel solar exterior -> pasamuros -> batería (cuerpo a y = 80)
-- ---------------------------------------------------------------------
local CABLE_MASKS = { [3] = { 1, 0 }, [9] = { 2, 1 }, [1] = { 2, 0 }, [5] = { 2, 3 } }
local function cablePiece(mask, x, y)
  local at = CABLE_MASKS[mask]
  blitTileHalf(imgCable, x, y, cable, at[1] * 32, at[2] * 32, "id")
end
cablePiece(3, 232, 32)   -- cuadro de distribución -> batería
cablePiece(3, 264, 72)   -- batería -> muro
cablePiece(3, 280, 72)   -- tramo dentro del muro
cablePiece(3, 312, 72)   -- fuera: muro -> panel

-- pasamuros en el muro este (fila 4)
box(imgCable, 296, 72, 311, 87, OUT)
box(imgCable, 297, 73, 310, 86, M2)
box(imgCable, 298, 74, 309, 85, N3)
box(imgCable, 299, 75, 308, 84, E2)
box(imgCable, 299, 79, 308, 80, E3)

-- bandeja de cables exterior (del pasamuros al panel)
box(imgCable, 312, 84, 327, 86, OUT)
box(imgCable, 312, 85, 327, 85, M1)

-- porche exterior del airlock (rejilla + franja de peligro)
for ty = 0, 1 do
  for tx = 0, 1 do
    blitTile(imgGround, 312 + tx * T, 104 + ty * T, base, BASE_AT.grate[1] * T, BASE_AT.grate[2] * T, "id")
  end
end
box(imgGround, 312, 103, 343, 103, OUT)
for x = 312, 343 do
  put(imgGround, x, 104, (x % 8 < 4) and A2 or N3)
end

-- ---------------------------------------------------------------------
-- panel solar exterior
-- ---------------------------------------------------------------------
blitRegionHalf(imgCable, 328, 24, solar, 0, 0, solar.img.width, solar.img.height)
box(imgGround, 332, 82, 404, 84, C5)
box(imgGround, 332, 85, 404, 85, N2)

-- ---------------------------------------------------------------------
-- TEJADO
-- ---------------------------------------------------------------------
local ROOF_ZONES = {
  ["13,2"] = R.vent, ["14,2"] = R.vent, ["13,3"] = R.vent, ["14,3"] = R.vent,
  ["2,10"] = R.radiator, ["3,10"] = R.radiator,
  ["5,10"] = R.panel,
  ["15,4"] = R.hazard, ["16,4"] = R.hazard, ["17,4"] = R.hazard,
  ["15,8"] = R.hazard, ["16,8"] = R.hazard, ["17,8"] = R.hazard,
}
for y = 0, BH - 1 do
  for x = 0, BW - 1 do
    local fn
    if x == 0 and y == 0 then fn = R.rim_nw
    elseif x == BW - 1 and y == 0 then fn = R.rim_ne
    elseif x == 0 and y == BH - 1 then fn = R.rim_sw
    elseif x == BW - 1 and y == BH - 1 then fn = R.rim_se
    elseif y == 0 then fn = R.rim_n
    elseif y == BH - 1 then fn = R.rim_s
    elseif x == 0 then fn = R.rim_w
    elseif x == BW - 1 then fn = R.rim_e
    else
      fn = ROOF_ZONES[x .. "," .. y]
      if not fn then
        local sx = (x % 3 == 0)
        local sy = (y % 3 == 0)
        if sx and sy then fn = R.rivets
        elseif sx then fn = R.seam_v
        elseif sy then fn = R.seam_h
        elseif (math.floor(x / 3) + math.floor(y / 3)) % 2 == 0 then fn = R.plate
        else fn = R.plate_light end
      end
    end
    local at = ROOF_AT[fn]
    blitTile(imgRoof, bx(x), by(y), { img = roofAtlas, indexed = false }, at.ox, at.oy, "id")
  end
end

-- escotilla del airlock (3x3 losetas) en losetas 14..16, 5..7
local HX, HY = bx(15), by(5)
box(imgRoof, HX + 3, HY + 3, HX + 45, HY + 45, OUT)
for y = 4, 44 do
  for x = 4, 44 do
    if x < 8 or x > 40 or y < 8 or y > 40 then
      put(imgRoof, HX + x, HY + y, ((x + y) % 8 < 4) and A2 or N3)
    end
  end
end
box(imgRoof, HX + 8, HY + 8, HX + 40, HY + 40, OUT)
box(imgRoof, HX + 9, HY + 9, HX + 39, HY + 39, C4)
box(imgRoof, HX + 9, HY + 9, HX + 39, HY + 10, C2)
box(imgRoof, HX + 9, HY + 9, HX + 10, HY + 39, C2)
box(imgRoof, HX + 9, HY + 38, HX + 39, HY + 39, C6)
box(imgRoof, HX + 38, HY + 9, HX + 39, HY + 39, C6)
box(imgRoof, HX + 14, HY + 14, HX + 34, HY + 34, C5)
box(imgRoof, HX + 14, HY + 14, HX + 34, HY + 15, C3)
box(imgRoof, HX + 14, HY + 14, HX + 15, HY + 34, C3)
for y = -8, 8 do
  for x = -8, 8 do
    local d = x * x + y * y
    if d <= 64 then put(imgRoof, HX + 24 + x, HY + 24 + y, C6) end
    if d <= 49 then put(imgRoof, HX + 24 + x, HY + 24 + y, M1) end
    if d <= 25 then put(imgRoof, HX + 24 + x, HY + 24 + y, M2) end
  end
end
box(imgRoof, HX + 16, HY + 23, HX + 32, HY + 25, N2)
box(imgRoof, HX + 23, HY + 16, HX + 25, HY + 32, N2)
put(imgRoof, HX + 24, HY + 24, A2)
for _, p in ipairs({ { 12, 12 }, { 36, 12 }, { 12, 36 }, { 36, 36 } }) do
  stud(imgRoof, HX + p[1] - 1, HY + p[2] - 1, C1, C3, C5)
end

-- antena sobre comunicaciones
local ACX, ACY = bx(8) + 8, by(2) + 8
box(imgRoof, ACX - 11, ACY - 11, ACX + 11, ACY + 11, OUT)
for y = -10, 10 do
  for x = -10, 10 do
    local d = x * x + y * y
    if d <= 100 then put(imgRoof, ACX + x, ACY + y, M2) end
    if d <= 81 then put(imgRoof, ACX + x, ACY + y, M1) end
    if d <= 49 and y < 0 then put(imgRoof, ACX + x, ACY + y, C2) end
  end
end
box(imgRoof, ACX - 2, ACY - 2, ACX + 2, ACY + 2, N2)
put(imgRoof, ACX, ACY, E2)
box(imgRoof, ACX - 1, ACY + 4, ACX, ACY + 10, M2)

-- balizas ámbar
for _, p in ipairs({ { bx(2) + 8, by(2) + 8 }, { bx(16) + 8, by(2) + 8 } }) do
  box(imgRoof, p[1] - 3, p[2] - 3, p[1] + 4, p[2] + 4, OUT)
  box(imgRoof, p[1] - 2, p[2] - 2, p[1] + 3, p[2] + 3, A2)
  box(imgRoof, p[1] - 1, p[2] - 1, p[1] + 1, p[2] + 1, A1)
end

-- pasamuros del cable en el canto este (fila 4)
box(imgRoof, 296, 72, 311, 87, OUT)
box(imgRoof, 297, 73, 310, 86, M2)
box(imgRoof, 298, 74, 309, 85, N3)
box(imgRoof, 299, 75, 308, 84, E2)

-- ---------------------------------------------------------------------
-- cels
-- ---------------------------------------------------------------------
for frame = 1, 3 do
  spr:newCel(layerGround, frame, imgGround, Point(0, 0))
  spr:newCel(layerFloor, frame, imgFloor, Point(0, 0))
  spr:newCel(layerWalls, frame, imgWalls, Point(0, 0))
  spr:newCel(layerMachines, frame, imgMachines, Point(0, 0))
  spr:newCel(layerCable, frame, imgCable, Point(0, 0))
end
local roofCel = spr:newCel(layerRoof, 2, imgRoof, Point(0, 0))
local roofGlassCel = spr:newCel(layerRoof, 3, imgRoof, Point(0, 0))
roofGlassCel.opacity = 56
spr:newCel(layerLabels, 1, Image(CW, CH, ColorMode.RGB), Point(0, 0))

spr:saveAs(ROOT .. "/art/tiles/base/base_plan.aseprite")
saveAseprite(roofAtlas, ROOT .. "/art/tiles/base/roof_atlas.aseprite")
saveSprite(roofAtlas, ROOT .. "/game/content/map/tiles/roof_atlas.png", 2)

print("OK plan: " .. CW .. "x" .. CH .. " frame 3 opacidad techo = " .. roofGlassCel.opacity)
