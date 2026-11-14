-- Limpia el cohete de aterrizaje conservando TODO su dibujo original
-- (lineas de panel, remaches, textura) y arreglando solo los defectos:
--   * alfa binario (el PNG venia con bordes semitransparentes)
--   * remapeo de los 14 colores sucios a la paleta de identidad
--   * tres patas apoyadas en la misma linea
--   * contorno continuo de 1 px

local SRC = "C:/Users/ramer/Documents/Proyecto predeterminado/art/sprites/ase/source-landing.png"
local OUT_DIR = "C:/Users/ramer/Documents/Proyecto predeterminado/art/sprites/ase"

local function rgba(h) return app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255) end
local OUT   = rgba("0f171f")
local CLEAR = app.pixelColor.rgba(0,0,0,0)
local HULLH = rgba("dfe8f0")
local HULL  = rgba("bcc9d6")
local HULLS = rgba("92a1b2")
local HULLM = rgba("7b8794")
local HULLD = rgba("5f6b78")
local METAL = rgba("a9b6c4")
local METALD= rgba("6a7684")
local TEALL = rgba("57c8cc")
local TEAL  = rgba("4aa8b4")
local TEALD = rgba("2a7f8b")
local AMBL  = rgba("ffe27a")
local AMB   = rgba("f0a72a")
local AMBD  = rgba("9c5f0c")
local NAVY  = rgba("26334f")
local NAVYL = rgba("3d5175")

local spr = app.open(SRC)
local W,H = spr.width, spr.height
local CX = (W-1)/2
local img = spr.cels[1].image
local pal = spr.palettes[1]

-- indice original -> color limpio (nil = transparente)
local map = {
  [0]=nil, [3]=nil,
  [1]=OUT,   [2]=OUT,
  [4]=HULLS,
  [6]=HULL,
  [7]=HULL,
  [8]=HULLM,
  [9]=HULLH,
  [13]=HULLS,          -- oliva sucio -> gris
  [5]=NAVY,
  [10]=TEAL,
  [11]=TEALD,
  [12]=AMB,
}

local out = Image(W,H,ColorMode.RGB)
for y=0,H-1 do
  for x=0,W-1 do
    local i = img:getPixel(x,y)
    if pal:getColor(i).alpha >= 128 then
      local c = map[i]
      if c then out:putPixel(x,y,c) end
    end
  end
end

-- ---------------------------------------------------------------- patas niveladas
local FEET = 120
local function clearRect(x0,y0,x1,y1)
  for y=y0,y1 do
    for x=x0,x1 do
      if x>=0 and x<W and y>=0 and y<H then out:putPixel(x,y,CLEAR) end
    end
  end
end
clearRect(0,113,W-1,H-1)
clearRect(0,104,26,112)
clearRect(71,104,W-1,112)

local function polyfill(pts,c)
  local n=#pts
  local miny,maxy=1e9,-1e9
  for i=1,n do
    if pts[i][2]<miny then miny=pts[i][2] end
    if pts[i][2]>maxy then maxy=pts[i][2] end
  end
  for y=math.floor(miny),math.ceil(maxy) do
    local xs={}
    for i=1,n do
      local a,b = pts[i], pts[i%n+1]
      if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then
        xs[#xs+1] = a[1]+(y-a[2])/(b[2]-a[2])*(b[1]-a[1])
      end
    end
    table.sort(xs)
    for i=1,#xs-1,2 do
      for x=math.floor(xs[i]+0.5),math.floor(xs[i+1]+0.5) do
        if x>=0 and x<W and y>=0 and y<H then out:putPixel(x,y,c) end
      end
    end
  end
end

local function leg(hipx, anklex, footx)
  polyfill({{hipx,104},{hipx+5,104},{anklex+5,FEET},{anklex,FEET}}, METAL)
  polyfill({{hipx+3,104},{hipx+5,104},{anklex+5,FEET},{anklex+3,FEET}}, METALD)
  polyfill({{footx-8,FEET},{footx+8,FEET},{footx+8,FEET+5},{footx-8,FEET+5}}, HULLS)
  polyfill({{footx-8,FEET},{footx+8,FEET},{footx+8,FEET+1},{footx-8,FEET+1}}, HULLH)
  polyfill({{footx-8,FEET+5},{footx+8,FEET+5},{footx+8,FEET+6},{footx-8,FEET+6}}, HULLD)
end
leg(29,19,20)
leg(69,79,78)
polyfill({{45,106},{51,106},{51,FEET},{45,FEET}}, METAL)
polyfill({{49,106},{51,106},{51,FEET},{49,FEET}}, METALD)
polyfill({{39,FEET},{59,FEET},{59,FEET+5},{39,FEET+5}}, HULLS)
polyfill({{39,FEET},{59,FEET},{59,FEET+1},{39,FEET+1}}, HULLH)
polyfill({{39,FEET+5},{59,FEET+5},{59,FEET+6},{39,FEET+6}}, HULLD)

-- ---------------------------------------------------------------- contorno continuo 1 px
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

-- ---------------------------------------------------------------- guardar
local s2 = Sprite(W,H,ColorMode.RGB)
local lay = s2:newLayer()
lay.name = "art"
s2:deleteLayer(s2.layers[1])
s2:newCel(lay,1,out,Point(0,0))
s2:resize(W, 127)
s2:saveAs(OUT_DIR.."/rocket-landing.aseprite")
s2:saveCopyAs(OUT_DIR.."/landing-final.png")
print("OK "..W.."x"..s2.height)
