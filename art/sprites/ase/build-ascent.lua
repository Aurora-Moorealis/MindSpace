-- Limpia el cohete de ascenso conservando su dibujo:
--   remapea la paleta a la paleta de identidad, fuerza alfa binario,
--   elimina el beige de las "rayas" y dibuja un contorno continuo de 1 px.

local SRC = "C:/Users/ramer/Documents/Proyecto predeterminado/art/sprites/ase/source-ascent.png"
local OUT_DIR = "C:/Users/ramer/Documents/Proyecto predeterminado/art/sprites/ase"

local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local OUT    = rgba("0f171f")
local HULLH  = rgba("dfe8f0")
local HULL   = rgba("bcc9d6")
local HULLS  = rgba("92a1b2")
local HULLD  = rgba("64707e")
local TEALL  = rgba("57c8cc")
local TEAL   = rgba("2f9fa6")
local TEALD  = rgba("186269")
local AMBL   = rgba("ffe27a")
local AMB    = rgba("f0a72a")
local AMBD   = rgba("9c5f0c")
local NAVY   = rgba("223050")
local NAVYL  = rgba("3d5175")
local FLAME  = rgba("e2551b")
local FLAMEC = rgba("ffc93c")

local spr = app.open(SRC)
local W,H = spr.width, spr.height
local img = spr.cels[1].image
local pal = spr.palettes[1]

-- indice -> color limpio  (nil = transparente)
local map = {
  [0]=nil, [1]=nil,
  [2]=OUT,               -- contorno
  [3]=NAVY,              -- aletas navy
  [4]=TEALD, [5]=TEAL, [6]=TEALL,   -- teales (morro + franjas)
  [7]=HULL, [8]=HULLH, [9]=HULLS, [11]=HULLD,  -- casco
  [10]=HULL,             -- beige de las rayas -> tono de casco
  [12]=FLAME, [13]=FLAMEC
}

local out = Image(W,H,ColorMode.RGB)
local isFlame = { [12]=true, [13]=true }
local function srcAt(x,y)
  if x<0 or x>=W or y<0 or y>=H then return 0 end
  return img:getPixel(x,y)
end
local function hasFlame(x,y)
  return isFlame[srcAt(x-1,y)] or isFlame[srcAt(x+1,y)]
      or isFlame[srcAt(x,y-1)] or isFlame[srcAt(x,y+1)]
end

for y=0,H-1 do
  for x=0,W-1 do
    local i = img:getPixel(x,y)
    local a = pal:getColor(i).alpha
    if a >= 128 then
      local c = map[i]
      if i == 10 and hasFlame(x,y) then c = FLAMEC end
      if c then out:putPixel(x,y,c) end
    end
  end
end

-- limpiar tonos de casco que cayeron dentro de la llama o de las aletas
local isHullIdx = { [7]=true, [8]=true, [9]=true, [10]=true, [11]=true }
local isFinIdx  = { [3]=true }
local function neigh(srcSet, x, y)
  local n = 0
  if srcSet[srcAt(x-1,y)] then n=n+1 end
  if srcSet[srcAt(x+1,y)] then n=n+1 end
  if srcSet[srcAt(x,y-1)] then n=n+1 end
  if srcSet[srcAt(x,y+1)] then n=n+1 end
  return n
end
for y=0,H-1 do
  for x=0,W-1 do
    local i = srcAt(x,y)
    if isHullIdx[i] and pal:getColor(i).alpha >= 128 then
      if neigh(isFlame,x,y) >= 2 then out:putPixel(x,y,FLAMEC)
      elseif neigh(isFinIdx,x,y) >= 3 then out:putPixel(x,y,NAVY) end
    end
  end
end

-- contorno continuo de 1 px
local snap = Image(out)
local function solid(x,y)
  if x<0 or x>=W or y<0 or y>=H then return false end
  return app.pixelColor.rgbaA(snap:getPixel(x,y)) > 0
end
for y=0,H-1 do
  for x=0,W-1 do
    if app.pixelColor.rgbaA(snap:getPixel(x,y))==0 then
      if solid(x-1,y) or solid(x+1,y) or solid(x,y-1) or solid(x,y+1) then
        out:putPixel(x,y,OUT)
      end
    end
  end
end

local s2 = Sprite(W,H,ColorMode.RGB)
local lay = s2:newLayer()
lay.name = "art"
s2:deleteLayer(s2.layers[1])
s2:newCel(lay,1,out,Point(0,0))
s2:saveAs(OUT_DIR.."/rocket-ascent.aseprite")
s2:saveCopyAs(OUT_DIR.."/ascent-final.png")
print("OK "..W.."x"..H)

