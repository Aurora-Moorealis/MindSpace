-- Genera los paneles nine-patch de los botones: normal, hover y pulsado.
-- Textura 72x56 con margen de 20 px para el nine-patch (bordes + tornillos).
--   Aseprite.exe -b --script build-buttons.lua

local OUT_DIR = "C:/Users/ramer/Documents/Proyects/MindSpace/game/assets/images/ui"
local W, H = 72, 56

local function rgba(h)
  return app.pixelColor.rgba(tonumber(h:sub(1,2),16), tonumber(h:sub(3,4),16), tonumber(h:sub(5,6),16), 255)
end

local OUT    = rgba("0f171f")
local BEV_LO = rgba("dfe8f0")
local BODY   = rgba("bcc9d6")
local BEV_HI = rgba("64707e")
local SCREW_D= rgba("5f6b78")
local SCREW_M= rgba("a9b6c4")
local SCREW_L= rgba("dfe8f0")
local TEAL_L = rgba("57c8cc")
local TEAL   = rgba("4aa8b4")
local TEAL_D = rgba("2a7f8b")
local BODY_P = rgba("92a1b2")

local function rect(img, x0, y0, x1, y1, c)
  for y = y0, y1 do
    for x = x0, x1 do
      if x >= 0 and x < W and y >= 0 and y < H then img:putPixel(x, y, c) end
    end
  end
end

local function screw(img, ox, oy)
  -- cabeza de 10x10: aro oscuro, metal, brillo arriba-izquierda y punto central
  for y = 0, 9 do
    for x = 0, 9 do
      local dx, dy = x - 4.5, y - 4.5
      local d = dx * dx + dy * dy
      if d <= 23 then
        img:putPixel(ox + x, oy + y, SCREW_D)
      end
      if d <= 13 then
        img:putPixel(ox + x, oy + y, SCREW_M)
      end
    end
  end
  img:putPixel(ox + 3, oy + 3, SCREW_L)
  img:putPixel(ox + 4, oy + 3, SCREW_L)
  img:putPixel(ox + 3, oy + 4, SCREW_L)
  img:putPixel(ox + 4, oy + 4, SCREW_D)
  img:putPixel(ox + 5, oy + 5, SCREW_D)
end

local function build(name, body, bevel_light, bevel_dark)
  local img = Image(W, H, ColorMode.RGB)
  rect(img, 0, 0, W - 1, H - 1, OUT)
  rect(img, 2, 2, W - 3, H - 3, body)
  rect(img, 2, 2, W - 3, 3, bevel_light)
  rect(img, 2, 2, 3, H - 3, bevel_light)
  rect(img, 2, H - 4, W - 3, H - 3, bevel_dark)
  rect(img, W - 4, 2, W - 3, H - 3, bevel_dark)
  screw(img, 5, 5)
  screw(img, 57, 5)
  screw(img, 5, 41)
  screw(img, 57, 41)

  local spr = Sprite(W, H, ColorMode.RGB)
  local lay = spr:newLayer()
  lay.name = "panel"
  spr:deleteLayer(spr.layers[1])
  spr:newCel(lay, 1, img, Point(0, 0))
  spr:saveCopyAs(OUT_DIR .. "/" .. name .. ".png")
  print("OK " .. name)
end

build("button_normal",  BODY,   BEV_LO, BEV_HI)
build("button_hover",   BODY,   TEAL,   TEAL_D)
build("button_pressed", BODY_P, BEV_HI, BEV_LO)
