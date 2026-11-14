# Convierte una imagen cualquiera a pixel art de rejilla fija.
#
#   pwsh -File pixelize.ps1 -In raw-C.png -Out menu-bg.png -Width 425 -Height 240 -Colors 32 -Scale 2
#
# -Width/-Height son la resolucion del ARTE (la rejilla real de pixeles).
# -Scale multiplica esa rejilla con vecino mas cercano: Scale 2 con 425x240 -> 850x480,
# y cada pixel artistico ocupa un bloque de 2x2 en pantalla (aspecto retro).
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Width = 425,
    [int]$Height = 240,
    [int]$Colors = 32,
    [ValidateSet("none", "ordered", "floyd")][string]$Dither = "none",
    [int]$Scale = 1,
    [switch]$Preview
)

$ErrorActionPreference = "Stop"

function Find-Magick {
    $candidates = @(
        "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe",
        "C:\Program Files\ImageMagick-7.1.0-Q16-HDRI\magick.exe"
    )
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    $found = Get-Command magick -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    throw "No encuentro magick.exe (ImageMagick 7)"
}

$magick = Find-Magick
$artGeometry = "${Width}x${Height}"

$cmd = @(
    $In,
    "-auto-orient",
    "-resize", "${artGeometry}^",      # cubre el marco sin dejar bordes
    "-gravity", "center",
    "-crop", "${artGeometry}+0+0",
    "+repage",
    "-filter", "Box",                   # promedio de bloque: sin halos ni ringing
    "-resize", $artGeometry
)

if ($Dither -eq "floyd") { $cmd += @("-dither", "FloydSteinberg") } else { $cmd += @("+dither") }
$cmd += @("-colors", "$Colors")

if ($Dither -eq "ordered") { $cmd += @("-ordered-dither", "o8x8") }

if ($Scale -gt 1) {
    $outGeometry = "$($Width * $Scale)x$($Height * $Scale)"
    $cmd += @("-filter", "point", "-resize", $outGeometry)
}

$cmd += @("-strip", "-define", "png:color-type=2", $Out)

& $magick @cmd
if ($LASTEXITCODE -ne 0) { throw "ImageMagick fallo (codigo $LASTEXITCODE)" }

$info = & $magick identify -format "%wx%h %[colors] colores" $Out
Write-Output "$Out -> $info"

if ($Preview) {
    $dir = [System.IO.Path]::GetDirectoryName($Out)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($Out)
    $previewPath = if ($dir) { Join-Path $dir "$name@3x.png" } else { "$name@3x.png" }
    & $magick $Out -filter point -resize 300% $previewPath
    Write-Output "preview -> $previewPath"
}
