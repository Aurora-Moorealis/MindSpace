-- Generador de arte de la red electrica:
--   art/sprites/machines/solar_array.aseprite       80x56  (5x3.5 losetas)
--   art/sprites/machines/battery.aseprite           32x48  (2x3 losetas)
--   art/sprites/machines/power_cable_atlas.aseprite 64x64  (4x4 losetas de 16)
-- Exporta a game/content/machines/... al doble (pixel artistico = 2x2 en pantalla).
-- Uso: Aseprite -b --script build-energy.lua

local ROOT = "C:/Users/ramer/Documents/Proyects/MindSpace"
local ART = ROOT .. "/art/sprites/machines"
local GAME = ROOT .. "/game/content/machines"

local function rgba(h)
  return app.pixelColor.rgba(tonumber(h:sub(1, 2), 16), tonumber(h:sub(3, 4), 16),
                             tonumber(h:sub(5, 6), 16), 255)
end

-- Paleta cerrada de la spec art-style
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

-- ---------------------------------------------------------------------------
-- Utilidades
-- ---------------------------------------------------------------------------

local function newSprite(w, h, name)
  local spr = Sprite(w, h, ColorMode.RGB)
  local layer = spr.layers[1]
  layer.name = name
  local img = Image(spr.spec)
  return spr, layer, img
end

local function fill(img, x, y, c)
  if x >= 0 and x < img.width and y >= 0 and y < img.height then
    img:putPixel(x, y, c)
  end
end

local function box(img, x0, y0, x1, y1, c)
  for y = y0, y1 do
    for x = x0, x1 do
      fill(img, x, y, c)
    end
  end
end

-- Contorno de 1 px alrededor de una mascara booleana. Los bordes de la loseta
-- se dejan abiertos cuando la mascara declara continuacion en esa direccion.
local function outlineMask(img, mask, w, h, open_edges)
  local function inside(x, y)
    if x < 0 or x >= w or y < 0 or y >= h then
      if open_edges then
        if x < 0 and open_edges.w then return true end
        if x >= w and open_edges.e then return true end
        if y < 0 and open_edges.n then return true end
        if y >= h and open_edges.s then return true end
      end
      return false
    end
    return mask[y * w + x] == true
  end
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if not mask[y * w + x] then goto continue end
      if not inside(x - 1, y) or not inside(x + 1, y)
        or not inside(x, y - 1) or not inside(x, y + 1) then
        fill(img, x, y, OUT)
      end
      ::continue::
    end
  end
end

local function rectMask(mask, w, x0, y0, x1, y1)
  for y = y0, y1 do
    for x = x0, x1 do
      if x >= 0 and y >= 0 and x < w then mask[y * w + x] = true end
    end
  end
end

local function save2x(img, path)
  local big = Image(img.width * 2, img.height * 2)
  for y = 0, img.height - 1 do
    for x = 0, img.width - 1 do
      local c = img:getPixel(x, y)
      big:putPixel(x * 2, y * 2, c)
      big:putPixel(x * 2 + 1, y * 2, c)
      big:putPixel(x * 2, y * 2 + 1, c)
      big:putPixel(x * 2 + 1, y * 2 + 1, c)
    end
  end
  big:saveAs(path)
end

local function commit(spr, layer, img, aseprite_path, png_path)
  spr:newCel(layer, 1, img, Point(0, 0))
  spr:saveAs(aseprite_path)
  save2x(img, png_path)
  print("OK " .. aseprite_path .. " -> " .. png_path)
end

-- ---------------------------------------------------------------------------
-- Panel solar 80x56 (5x3.5 losetas). Referencia real: marco de aluminio,
-- celdas monocristalinas azul marino con dedos y busbars plateados, caja de
-- conexion con cable.
-- ---------------------------------------------------------------------------

local function buildSolar()
  local w, h = 80, 56
  local spr, layer, img = newSprite(w, h, "solar_array")
  local mask = {}

  -- Silueta: marco + viga + patas + caja de conexion, todo conectado.
  rectMask(mask, w, 3, 3, 76, 44)     -- marco del panel
  rectMask(mask, w, 8, 44, 71, 49)    -- viga de soporte
  rectMask(mask, w, 10, 49, 20, 54)   -- pata izquierda
  rectMask(mask, w, 60, 49, 70, 54)   -- pata derecha
  rectMask(mask, w, 66, 40, 76, 51)   -- caja de conexion

  -- Marco de aluminio: luz arriba-izquierda, sombra abajo-derecha.
  box(img, 4, 4, 75, 43, M2)
  box(img, 4, 4, 75, 5, M1)
  box(img, 4, 4, 5, 43, M1)
  box(img, 74, 4, 75, 43, C5)
  box(img, 4, 42, 75, 43, C5)
  box(img, 6, 6, 73, 41, C6)         -- bisel interior

  -- Fondo plateado entre celdas (cintas de string).
  box(img, 5, 5, 74, 42, M2)

  -- Celdas monocristalinas: 6 columnas x 4 filas de 10x8 con 1 px de cinta.
  local cw, ch, step_x, step_y = 10, 8, 11, 9
  for row = 0, 3 do
    for col = 0, 5 do
      local cx = 7 + col * step_x
      local cy = 6 + row * step_y
      box(img, cx, cy, cx + cw - 1, cy + ch - 1, N2)
      box(img, cx, cy, cx + cw - 1, cy, N1)                 -- luz arriba
      box(img, cx, cy, cx, cy + ch - 1, N1)                 -- luz izquierda
      box(img, cx, cy + ch - 1, cx + cw - 1, cy + ch - 1, N3) -- sombra abajo
      box(img, cx + cw - 1, cy, cx + cw - 1, cy + ch - 1, N3) -- sombra derecha
      fill(img, cx + 1, cy + 1, N1)                         -- brillo de esquina
      -- Dedos metalicos verticales.
      for fy = cy + 2, cy + 5 do
        fill(img, cx + 3, fy, C4)
        fill(img, cx + 6, fy, C4)
      end
      -- Busbar horizontal.
      box(img, cx + 1, cy + 4, cx + cw - 2, cy + 4, M2)
    end
  end

  -- Viga de soporte de aluminio.
  box(img, 8, 44, 71, 49, M2)
  box(img, 8, 44, 71, 44, M1)
  box(img, 8, 48, 71, 49, C5)

  -- Patas.
  box(img, 10, 49, 20, 54, M2)
  box(img, 10, 49, 20, 49, M1)
  box(img, 10, 53, 20, 54, C5)
  box(img, 60, 49, 70, 54, M2)
  box(img, 60, 49, 70, 49, M1)
  box(img, 60, 53, 70, 54, C5)

  -- Etiqueta de serie en la viga.
  box(img, 22, 45, 38, 47, C1)
  box(img, 24, 46, 27, 46, N3)
  box(img, 29, 46, 34, 46, N3)

  -- Caja de conexion con puerto teal.
  box(img, 66, 40, 76, 51, C3)
  box(img, 66, 40, 76, 41, C2)
  box(img, 75, 40, 76, 51, C5)
  box(img, 66, 50, 76, 51, C5)
  box(img, 69, 43, 74, 48, E4)
  box(img, 70, 44, 73, 47, E2)
  fill(img, 70, 44, E1)

  -- Tornillos del marco.
  local function rivet(x, y)
    fill(img, x, y, C1)
    fill(img, x + 1, y, C4)
    fill(img, x, y + 1, C4)
    fill(img, x + 1, y + 1, C6)
  end
  rivet(4, 4)
  rivet(72, 4)
  rivet(4, 40)
  rivet(72, 40)

  outlineMask(img, mask, w, h, nil)
  commit(spr, layer, img, ART .. "/solar_array.aseprite", GAME .. "/solar_array/solar_array.png")
end

-- ---------------------------------------------------------------------------
-- Bateria 32x48
-- ---------------------------------------------------------------------------

local function buildBattery()
  local w, h = 32, 48
  local spr, layer, img = newSprite(w, h, "battery")
  local mask = {}

  rectMask(mask, w, 10, 1, 14, 4)    -- borne izquierdo
  rectMask(mask, w, 18, 1, 22, 4)    -- borne derecho
  rectMask(mask, w, 6, 4, 25, 8)     -- tapa
  rectMask(mask, w, 5, 8, 26, 41)    -- cuerpo
  rectMask(mask, w, 7, 41, 24, 45)   -- base
  rectMask(mask, w, 22, 37, 29, 44)  -- caja de conexion

  -- Bornes teal.
  box(img, 10, 1, 14, 4, E4)
  box(img, 10, 1, 14, 1, E2)
  box(img, 18, 1, 22, 4, E4)
  box(img, 18, 1, 22, 1, E2)

  -- Tapa y cuerpo con luz arriba-izquierda.
  box(img, 6, 4, 25, 8, C3)
  box(img, 6, 4, 25, 4, C2)
  box(img, 6, 8, 25, 8, C5)
  box(img, 5, 8, 26, 41, C2)
  box(img, 5, 8, 6, 41, C1)
  box(img, 5, 8, 26, 9, C1)
  box(img, 25, 8, 26, 41, C4)
  box(img, 5, 40, 26, 41, C5)

  -- Indicador de carga: ventana oscura con tres barras ambar.
  box(img, 9, 12, 18, 36, N3)
  box(img, 9, 12, 18, 12, N2)
  box(img, 9, 12, 9, 36, N2)
  box(img, 18, 12, 18, 36, N2)
  box(img, 10, 14, 17, 20, A2)
  box(img, 10, 14, 17, 14, A1)
  box(img, 10, 23, 17, 29, A2)
  box(img, 10, 23, 17, 23, A1)
  box(img, 10, 32, 17, 34, A3)

  -- Remaches.
  local function rivet(x, y)
    fill(img, x, y, C1)
    fill(img, x + 1, y, C4)
    fill(img, x, y + 1, C4)
    fill(img, x + 1, y + 1, C6)
  end
  rivet(7, 11)
  rivet(22, 11)
  rivet(7, 37)
  rivet(22, 37)

  -- Base.
  box(img, 7, 41, 24, 45, M2)
  box(img, 7, 41, 24, 41, M1)
  box(img, 7, 44, 24, 45, C5)

  -- Caja de conexion con puerto teal.
  box(img, 22, 37, 29, 44, C3)
  box(img, 22, 37, 29, 38, C2)
  box(img, 27, 37, 29, 44, C5)
  box(img, 22, 43, 29, 44, C5)
  box(img, 24, 39, 27, 42, E4)
  box(img, 25, 40, 26, 41, E2)

  outlineMask(img, mask, w, h, nil)
  commit(spr, layer, img, ART .. "/battery.aseprite", GAME .. "/battery/battery.png")
end

-- ---------------------------------------------------------------------------
-- Cable electrico: atlas 4x4 de losetas 16x16 (mascara N=1 E=2 S=4 W=8)
-- ---------------------------------------------------------------------------

local function buildCableAtlas()
  local tile = 16
  local cols = 4
  local spr = Sprite(tile * cols, tile * cols, ColorMode.RGB)
  local layer = spr.layers[1]
  layer.name = "cable"
  local img = Image(spr.spec)

  local function armMask(mask, ox, oy)
    local filled = {}
    local function put(x, y)
      if x >= 0 and x < tile and y >= 0 and y < tile then
        filled[y * tile + x] = true
      end
    end
    -- Nucleo central de 6x6.
    for y = 5, 10 do for x = 5, 10 do put(x, y) end end
    if mask == 0 then
      -- Nodo suelto: bloque central ya dibujado.
    else
      if mask % 2 >= 1 then for y = 0, 10 do for x = 5, 10 do put(x, y) end end end       -- N
      if math.floor(mask / 2) % 2 >= 1 then for x = 5, 15 do for y = 5, 10 do put(x, y) end end end -- E
      if math.floor(mask / 4) % 2 >= 1 then for y = 5, 15 do for x = 5, 10 do put(x, y) end end end -- S
      if math.floor(mask / 8) % 2 >= 1 then for x = 0, 10 do for y = 5, 10 do put(x, y) end end end -- W
    end

    -- Relleno metalico con nucleo teal.
    for y = 0, tile - 1 do
      for x = 0, tile - 1 do
        if filled[y * tile + x] then
          local core = (x >= 7 and x <= 8) or (y >= 7 and y <= 8)
          local color = M2
          if core then color = E3 end
          if (y == 5 and not core) or (x == 5 and not core) then color = M1 end
          fill(img, ox + x, oy + y, color)
        end
      end
    end

    -- Contorno: borde de la mascara, abierto en las direcciones que conectan.
    local open = {
      n = (mask % 2 >= 1),
      e = (math.floor(mask / 2) % 2 >= 1),
      s = (math.floor(mask / 4) % 2 >= 1),
      w = (math.floor(mask / 8) % 2 >= 1),
    }
    local function inside(x, y)
      if x < 0 then return open.w end
      if x >= tile then return open.e end
      if y < 0 then return open.n end
      if y >= tile then return open.s end
      return filled[y * tile + x] == true
    end
    for y = 0, tile - 1 do
      for x = 0, tile - 1 do
        if filled[y * tile + x] then
          if not inside(x - 1, y) or not inside(x + 1, y)
            or not inside(x, y - 1) or not inside(x, y + 1) then
            fill(img, ox + x, oy + y, OUT)
          end
        end
      end
    end
  end

  for mask = 0, 15 do
    local ox = (mask % cols) * tile
    local oy = math.floor(mask / cols) * tile
    armMask(mask, ox, oy)
  end

  spr:newCel(layer, 1, img, Point(0, 0))
  spr:saveAs(ART .. "/power_cable_atlas.aseprite")
  save2x(img, GAME .. "/power_cable/power_cable_atlas.png")
  print("OK cable atlas -> " .. GAME .. "/power_cable/power_cable_atlas.png")
end

buildSolar()
buildBattery()
buildCableAtlas()
print("build-energy: done")
