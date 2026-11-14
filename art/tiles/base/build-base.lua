-- Tileset BASE (interior): suelo de plancha, muros y pasillos.
--   art/tiles/base/base_atlas.aseprite      64x64  (4x4 losetas de 16x16)
--   game/content/map/tiles/base_atlas.png  128x128 (x2)
--   art/tiles/base/_qa-sala.aseprite        prueba de sala (16x11 losetas -> 256x176)
--   art/tiles/base/_qa-sala.png             prueba de sala x2 (512x352)
-- Aseprite -b --script build-base.lua

local ROOT = "C:/Users/ramer/Documents/Proyects/MindSpace"

local function rgba(h)
  return app.pixelColor.rgba(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16),
                             tonumber(h:sub(5, 6), 16), 255)
end

-- paleta cerrada del brief
local OUT = rgba("0f171f")   -- contorno
local C1  = rgba("dfe8f0")   -- casco 1
local C2  = rgba("bcc9d6")   -- casco 2
local C3  = rgba("92a1b2")   -- casco 3
local C4  = rgba("7b8794")   -- casco 4
local C5  = rgba("64707e")   -- casco 5
local C6  = rgba("5f6b78")   -- casco 6
local M1  = rgba("a9b6c4")   -- metal
local M2  = rgba("6a7684")   -- metal oscuro
local E1  = rgba("57c8cc")   -- teal
local E2  = rgba("4aa8b4")
local E3  = rgba("2f9fa6")
local E4  = rgba("2a7f8b")
local E5  = rgba("186269")
local A1  = rgba("ffe27a")   -- ambar
local A2  = rgba("f0a72a")
local A3  = rgba("9c5f0c")
local N1  = rgba("3d5175")   -- navy
local N2  = rgba("26334f")
local N3  = rgba("1b2540")

local T = 16
local cur, ox, oy

local function p(x, y, c)
  local ax, ay = ox + x, oy + y
  if ax >= 0 and ax < cur.width and ay >= 0 and ay < cur.height then
    cur:putPixel(ax, ay, c)
  end
end

local function box(x0, y0, x1, y1, c)
  for y = y0, y1 do for x = x0, x1 do p(x, y, c) end end
end

-- luz 2x2 (arriba-izquierda iluminada)
local function stud(x, y, c1, c2, c3)
  p(x, y, c1); p(x + 1, y, c2); p(x, y + 1, c2); p(x + 1, y + 1, c3)
end

local B = {}

-- =====================================================================
-- FILA 0 · SUELO INTERIOR (plancha de laboratorio)
-- junta de 1 px en el borde -> al teselar sale una rejilla limpia
-- =====================================================================
local function plateBase()
  box(0, 0, T - 1, T - 1, C2)
  box(0, T - 1, T - 1, T - 1, C4)   -- junta (sur)
  box(T - 1, 0, T - 1, T - 2, C4)   -- junta (este)
end

function B.plate()
  plateBase()
end

function B.plate_rivets()
  plateBase()
  local function rivet(x, y)
    p(x, y, C1); p(x + 1, y, C4)
    p(x, y + 1, C4); p(x + 1, y + 1, C6)
  end
  rivet(2, 2); rivet(12, 2); rivet(2, 12); rivet(12, 12)
end

function B.vent()
  plateBase()
  box(2, 2, 13, 2, C3)          -- marco hundido, labio iluminado
  box(2, 3, 2, 13, C3)
  box(3, 13, 13, 13, C5)
  box(13, 3, 13, 12, C5)
  box(3, 3, 12, 12, N3)         -- cavidad oscura
  for _, y in ipairs({ 4, 7, 10 }) do
    box(3, y, 12, y, C4)        -- lamas
    box(3, y + 1, 12, y + 1, C5)
  end
end

function B.plate_diag()
  plateBase()
  for i = 0, T - 1 do
    p(i, T - 1 - i, C4)
    p(i, T - 2 - i, C3)
  end
end

-- =====================================================================
-- FILA 1 · MUROS (vistos desde arriba)
-- Luz desde arriba-izquierda: canto iluminado de 2 px en el lado norte
-- (y oeste, al girar la loseta) y sombra de apoyo + linea en el lado sur.
-- Sin contorno negro en los cuatro lados.
-- =====================================================================
-- muro recto: el cuerpo sigue a izquierda y derecha, el suelo queda al sur
function B.wall()
  box(0, 0, T - 1, T - 1, C6)
  box(0, 0, T - 1, 0, C1)       -- canto iluminado
  box(0, 1, T - 1, 1, C3)       -- canto iluminado
  box(0, 2, T - 1, 2, C5)       -- paso al cuerpo
  box(0, T - 2, T - 1, T - 2, N2)    -- sombra de apoyo
  box(0, T - 1, T - 1, T - 1, OUT)   -- linea de separacion con el suelo
end

-- esquina: el cuerpo sigue por dos lados, el canto hace L por fuera
function B.wall_corner()
  box(0, 0, T - 1, T - 1, C6)
  box(0, 0, T - 1, 0, C1)
  box(0, 1, T - 1, 1, C3)
  box(0, 2, T - 1, 2, C5)
  box(0, 0, 0, T - 1, C1)
  box(1, 2, 1, T - 1, C3)
  box(2, 2, 2, T - 1, C5)
  -- sombra suave en la esquina interior
  box(T - 3, T - 3, T - 1, T - 1, C5)
  box(T - 2, T - 2, T - 1, T - 1, N1)
end

function B.wall_window()
  B.wall()
  box(3, 3, 12, 12, C1)         -- marco exterior iluminado
  box(3, 3, 12, 3, C1)
  box(3, 13, 12, 13, C4)
  box(12, 3, 12, 12, C4)
  box(4, 4, 11, 12, E5)         -- cristal al exterior
  for i = 0, 5 do               -- reflejo diagonal
    p(4 + i, 6 + i, E4)
    p(5 + i, 6 + i, E3)
  end
  box(8, 4, 9, 12, M2)          -- montante
end

function B.wall_door()
  B.wall()
  box(5, 0, 10, T - 1, C4)      -- hueco pasante
  box(5, 0, 5, T - 1, C1)       -- jamba iluminada
  box(10, 0, 10, T - 1, C5)     -- jamba en sombra
  box(6, 7, 9, 8, M2)           -- umbral
  p(6, 8, C3); p(9, 8, C3)
  box(4, 0, 4, T - 1, M1)       -- marco
  box(11, 0, 11, T - 1, M2)
  p(5, 4, A2); p(5, 5, A3)      -- marcador de puerta
  p(10, 4, A3); p(10, 5, A2)
end

-- =====================================================================
-- FILA 2 · PASILLOS
-- base mas oscura que la plancha de sala (distincion por luminosidad)
-- =====================================================================
function B.corridor()
  box(0, 0, T - 1, T - 1, C4)
  box(0, 0, 1, T - 1, C5)       -- canaleta oeste
  box(14, 0, 15, T - 1, C5)     -- canaleta este
  box(5, 0, 5, T - 1, C5)       -- borde de la banda
  box(6, 0, 9, T - 1, C3)       -- banda central
  box(10, 0, 10, T - 1, C5)
  box(0, T - 1, T - 1, T - 1, M2)   -- junta transversal
  stud(3, 7, A1, A2, A3)             -- luces ambar a los lados
  stud(11, 7, A1, A2, A3)
end

function B.corridor_corner()
  box(0, 0, T - 1, T - 1, C4)
  box(0, 0, 1, T - 1, C5)
  box(0, 14, T - 1, 15, C5)
  -- banda en L (entra por el norte, sale por el este)
  box(6, 0, 9, 9, C3)
  box(6, 6, 15, 9, C3)
  box(5, 0, 5, 9, C5)
  box(10, 0, 10, 5, C5)
  box(10, 5, 15, 5, C5)
  box(6, 10, 15, 10, C5)
  stud(3, 3, A1, A2, A3)
  stud(11, 12, A1, A2, A3)
end

function B.corridor_cross()
  box(0, 0, T - 1, T - 1, C4)
  box(6, 0, 9, T - 1, C3)
  box(0, 6, T - 1, 9, C3)
  box(5, 0, 5, 5, C5); box(10, 0, 10, 5, C5)
  box(5, 10, 5, 15, C5); box(10, 10, 10, 15, C5)
  box(0, 5, 5, 5, C5); box(10, 5, 15, 5, C5)
  box(0, 10, 5, 10, C5); box(10, 10, 15, 10, C5)
  stud(2, 2, A1, A2, A3)
  stud(13, 2, A1, A2, A3)
  stud(2, 13, A1, A2, A3)
  stud(13, 13, A1, A2, A3)
end

function B.airlock()
  box(0, 0, T - 1, T - 1, C4)
  box(0, 0, 1, T - 1, C5)
  box(14, 0, 15, T - 1, C5)
  -- umbral con franja de peligro
  box(0, 5, T - 1, 5, OUT)
  for y = 6, 9 do
    for x = 0, T - 1 do
      p(x, y, ((x + y) % 8 < 4) and A2 or N3)
    end
  end
  box(0, 10, T - 1, 10, OUT)
  -- testigos teal
  p(3, 2, E2); p(4, 2, E2); p(3, 3, E3); p(4, 3, E5)
  p(11, 2, E2); p(12, 2, E2); p(11, 3, E3); p(12, 3, E5)
end

-- =====================================================================
-- FILA 3 · CIERRES Y TRANSICION
-- =====================================================================
-- muro en T: el cuerpo sigue por tres lados -> canto arriba y sin linea
function B.wall_tee()
  box(0, 0, T - 1, T - 1, C6)
  box(0, 0, T - 1, 0, C1)
  box(0, 1, T - 1, 1, C3)
  box(0, 2, T - 1, 2, C5)
  box(0, 12, 0, T - 1, C5)      -- el cuerpo baja por el centro
  box(T - 1, 12, T - 1, T - 1, C5)
end

-- muro extremo: tapa de pasillo (mamparo)
function B.wall_end()
  box(0, 0, T - 1, T - 1, C6)
  box(0, 0, T - 1, 0, C1)
  box(0, 1, T - 1, 1, C3)
  box(0, 2, T - 1, 2, C5)
  box(2, 4, 13, 12, N2)         -- panel hundido del mamparo
  box(2, 4, 13, 4, C3)          -- labio iluminado
  box(2, 5, 2, 12, C5)
  box(13, 5, 13, 12, C4)
  box(7, 5, 8, 12, C5)          -- junta central
  p(4, 6, C5); p(11, 6, C5)
  box(0, T - 2, T - 1, T - 2, N2)
  box(0, T - 1, T - 1, T - 1, OUT)
end

-- transicion: la plancha de sala muere en el muro (borde sur)
function B.floor_to_wall()
  box(0, 0, T - 1, 5, C2)
  box(0, 0, 0, 5, C2)
  box(0, 6, T - 1, 6, C4)       -- sombra de contacto
  box(0, 7, T - 1, 7, C1)       -- canto iluminado del muro
  box(0, 8, T - 1, 8, C3)
  box(0, 9, T - 1, 13, C6)
  box(0, 9, 0, 13, C5)
  box(T - 1, 9, T - 1, 13, C5)
  box(0, 14, T - 1, 14, N2)
  box(0, 15, T - 1, 15, OUT)
end

-- rejilla de suelo industrial (variante oscura)
function B.grate_floor()
  box(0, 0, T - 1, T - 1, C5)
  for y = 0, T - 1 do
    for x = 0, T - 1 do
      local mx, my = x % 4, y % 4
      if (mx == 1 or mx == 2) and (my == 1 or my == 2) then
        p(x, y, N3)
      elseif my == 0 then
        p(x, y, C4)
      end
    end
  end
  box(0, 0, T - 1, 0, C3)
  box(0, 0, 0, T - 1, C3)
end

-- =====================================================================
-- ORDEN DEL ATLAS
-- =====================================================================
local ORDER = {
  { B.plate, B.plate_rivets, B.vent, B.plate_diag },
  { B.wall, B.wall_corner, B.wall_window, B.wall_door },
  { B.corridor, B.corridor_corner, B.corridor_cross, B.airlock },
  { B.wall_tee, B.wall_end, B.floor_to_wall, B.grate_floor },
}

local function renderAtlas()
  local img = Image(4 * T, 4 * T, ColorMode.RGB)
  cur = img
  for row = 1, 4 do
    for col = 1, 4 do
      ox, oy = (col - 1) * T, (row - 1) * T
      ORDER[row][col]()
    end
  end
  return img
end

-- =====================================================================
-- SALIDA (PNG al doble)
-- =====================================================================
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
-- PRUEBA DE SALA (16 x 11 losetas)
-- Un tilemap gira/voltea la loseta de muro para colocarla en cada lado:
--   canto iluminado al norte-oeste, sombra al sur-este (luz de arriba-izq).
--   C esquina  N esquina girada  Q/Z esquinas mas giradas
--   S muro recto (horizontal)   W muro recto girado (vertical)
--   V ventana  D puerta  E muro extremo
--   X transicion suelo-muro     c pasillo    a airlock
--   . plancha  r remaches  v rejilla  d junta diagonal  g rejilla industrial
-- =====================================================================
local QA = {
  "CSSVSSSDSSSSSSSN",
  "W.....WcM......M",
  "W..rr.WcM...v..M",
  "W.rr..WcM......M",
  "W.....PcO......M",
  "W.....WcM....rrM",
  "W.....WaM....rrM",
  "W.d...WcM..g...M",
  "W.....WcM..dd..M",
  "W.....WEM......M",
  "ZXXXXXSSSXXXXXXQ",
}

local TILE_OF = {
  ["C"] = { B.wall_corner, "id" },
  ["N"] = { B.wall_corner, "h" },
  ["Q"] = { B.wall_corner, "r180" },
  ["Z"] = { B.wall_corner, "r270" },
  ["S"] = { B.wall, "id" },
  ["W"] = { B.wall, "r270" },
  ["M"] = { B.wall, "r90" },
  ["V"] = { B.wall_window, "id" },
  ["D"] = { B.wall_door, "id" },
  ["P"] = { B.wall_door, "r270" },
  ["O"] = { B.wall_door, "r90" },
  ["E"] = { B.wall_end, "id" },
  ["T"] = { B.wall_tee, "id" },
  ["X"] = { B.floor_to_wall, "id" },
  ["c"] = { B.corridor, "id" },
  ["a"] = { B.airlock, "id" },
  ["."] = { B.plate, "id" },
  ["r"] = { B.plate_rivets, "id" },
  ["v"] = { B.vent, "id" },
  ["d"] = { B.plate_diag, "id" },
  ["g"] = { B.grate_floor, "id" },
}

local function srcOf(t, x, y)
  if t == "id" then return x, y end
  if t == "r90" then return y, T - 1 - x end
  if t == "r180" then return T - 1 - x, T - 1 - y end
  if t == "r270" then return T - 1 - y, x end
  if t == "h" then return T - 1 - x, y end
  if t == "v" then return x, T - 1 - y end
  return x, y
end

local function renderQA()
  local rows, cols = #QA, #QA[1]
  local img = Image(cols * T, rows * T, ColorMode.RGB)
  for ry = 1, rows do
    for cx = 1, cols do
      local ch = QA[ry]:sub(cx, cx)
      local def = TILE_OF[ch]
      if not def then error("caracter desconocido en el mapa QA: [" .. ch .. "]") end
      -- dibuja la loseta en un buffer y la copia transformada
      local buf = Image(T, T, ColorMode.RGB)
      local pc, px0, py0 = cur, ox, oy
      cur, ox, oy = buf, 0, 0
      def[1]()
      cur, ox, oy = pc, px0, py0
      local dx0, dy0 = (cx - 1) * T, (ry - 1) * T
      for y = 0, T - 1 do
        for x = 0, T - 1 do
          local sx, sy = srcOf(def[2], x, y)
          img:putPixel(dx0 + x, dy0 + y, buf:getPixel(sx, sy))
        end
      end
    end
  end
  return img
end

local atlas = renderAtlas()
saveAseprite(atlas, ROOT .. "/art/tiles/base/base_atlas.aseprite")
saveSprite(atlas, ROOT .. "/game/content/map/tiles/base_atlas.png", 2)

local qa = renderQA()
saveAseprite(qa, ROOT .. "/art/tiles/base/_qa-sala.aseprite")
saveSprite(qa, ROOT .. "/art/tiles/base/_qa-sala.png", 2)

print("OK base: atlas 64x64 -> png 128x128 | qa " .. qa.width .. "x" .. qa.height ..
      " -> png " .. (qa.width * 2) .. "x" .. (qa.height * 2))
