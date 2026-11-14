# Convierte un concepto con fondo magenta en un sprite pixel art con transparencia.
#
#   pwsh -File make-sprite.ps1 -In raw\rocket-up.png -Out rocket-up.png -MaxW 48 -MaxH 64 -Colors 10 -Scale 2
#
# Pasos: quita el magenta por relleno desde las 4 esquinas (no borra magenta interior)
# -> recorta al contenido -> baja a la rejilla Box -> cuantiza -> PNG con alfa.
# Genera tambien un preview sobre fondo oscuro, porque el alfa no se ve en el visor.
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$MaxW = 48,
    [int]$MaxH = 64,
    [int]$Colors = 10,
    [int]$Scale = 2,
    [switch]$FullSize
)

$ErrorActionPreference = "Stop"

function Find-Magick {
    foreach ($c in @(
            "C:\Program Files\ImageMagick-7.1.2-Q16-HDRI\magick.exe",
            "C:\Program Files\ImageMagick-7.1.0-Q16-HDRI\magick.exe")) {
        if (Test-Path $c) { return $c }
    }
    $found = Get-Command magick -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    throw "No encuentro magick.exe (ImageMagick 7)"
}

$magick = Find-Magick
$Out = [System.IO.Path]::GetFullPath($Out)
$dir = [System.IO.Path]::GetDirectoryName($Out)
$base = [System.IO.Path]::GetFileNameWithoutExtension($Out)
$tmp = @{}

# 1. Quitar el magenta: relleno desde las cuatro esquinas, tolerancia moderada.
$tmp.keyed = Join-Path $dir "$base-keyed.png"
& $magick $In -fuzz 18% -fill none -draw "color 0,0 floodfill" $tmp.keyed
foreach ($g in @("NorthEast", "SouthWest", "SouthEast")) {
    $tmpKey = Join-Path $dir "$base-keyed2.png"
    & $magick $tmp.keyed -gravity $g -fuzz 18% -fill none -draw "color 0,0 floodfill" $tmpKey
    Move-Item $tmpKey $tmp.keyed -Force
}

# 2. Recortar al contenido y calcular factor de bajada.
$geom = & $magick identify -format "%w %h" $tmp.keyed
$parts = $geom -split " "
$w = [int]$parts[0]; $h = [int]$parts[1]

if ($FullSize) {
    $target = "${MaxW}x${MaxH}"
} else {
    # cabe dentro de MaxW x MaxH respetando proporcion
    $ratioW = $MaxW / [double]$w
    $ratioH = $MaxH / [double]$h
    $ratio = [Math]::Min($ratioW, $ratioH)
    $nw = [Math]::Max(1, [int][Math]::Round($w * $ratio))
    $nh = [Math]::Max(1, [int][Math]::Round($h * $ratio))
    $target = "${nw}x${nh}"
}

$tmp.art = "$dir\$base-art.png"
& $magick $tmp.keyed -trim +repage -filter Box -resize $target -colors $Colors -strip $tmp.art

# 3. Salida escalada (pixel gordo) o a tamano real.
if ($Scale -gt 1 -and -not $FullSize) {
    & $magick $tmp.art -filter point -resize "$($Scale * 100)%" -strip $Out
} else {
    Copy-Item $tmp.art $Out -Force
}

# 4. Preview sobre fondo oscuro.
$preview = "$dir\$base-preview.png"
& $magick $Out -background "#141a2b" -alpha remove -alpha off -filter point -resize 300% $preview

$info = & $magick identify -format "%wx%h %[colors] colores" $Out
Write-Output "$Out -> $info"
Write-Output "art (sin escalar) -> $($tmp.art)"

Remove-Item $tmp.keyed, $tmp.art -ErrorAction SilentlyContinue
