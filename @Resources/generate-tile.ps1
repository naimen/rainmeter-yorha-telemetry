<#
.SYNOPSIS
    Generates the YoRHa seamless full-opened lattice tile (smokeglass.png).

.DESCRIPTION
    Creates a mathematically precise, seamless tile with customizable line width,
    dot size, grid spacing, dot intervals, and orientation (orthogonal or diagonal).
    Automatically refreshes Rainmeter if it is running so changes appear live instantly.

.PARAMETER LineWidth
    Width of the subtle grid lines in pixels (e.g. 1.0, 1.2, 1.5, 2.0). Default: 1.0

.PARAMETER DotSize
    Diameter of the sparse accent dots in pixels (e.g. 1.0, 1.5, 2.0, 2.5). Default: 1.5

.PARAMETER Diagonal
    Switch flag. If set, generates a 45-degree diamond lattice instead of square grid.

.PARAMETER GridSpacing
    Spacing between grid lines in pixels. Default: 6

.PARAMETER DotInterval
    Spacing between sparse accent dots in pixels. Default: 18

.PARAMETER LineAlpha
    Alpha intensity of grid lines (0-255). Default: 140

.PARAMETER DotAlpha
    Alpha intensity of accent dots (0-255). Default: 255

.PARAMETER OutputPath
    Target PNG file path. Defaults to @Resources\smokeglass.png

.EXAMPLE
    # Square grid with defaults (1.0px line, 1.5px dots):
    .\generate-tile.ps1

    # Diagonal diamond lattice with defaults:
    .\generate-tile.ps1 -Diagonal

    # Diagonal lattice with 1.2px lines and 2.0px dots:
    .\generate-tile.ps1 1.2 2.0 -Diagonal

    # Square grid with custom line thickness and dot size:
    .\generate-tile.ps1 1.5 2.0
#>

param(
    [Parameter(Position = 0)]
    [double]$LineWidth = 1.0,

    [Parameter(Position = 1)]
    [double]$DotSize = 1.5,

    [Alias("Diag")]
    [switch]$Diagonal,

    [int]$GridSpacing = 6,
    [int]$DotInterval = 18,
    [int]$TileSize = 36,
    [int]$LineAlpha = 140,
    [int]$DotAlpha = 255,
    [string]$OutputPath = ""
)

# Resolve target OutputPath robustly
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    if (-not $scriptDir) {
        $candidate = Join-Path (Get-Location).Path "@Resources"
        if (Test-Path $candidate) {
            $scriptDir = $candidate
        } else {
            $scriptDir = (Get-Location).Path
        }
    }
    $OutputPath = Join-Path $scriptDir "smokeglass.png"
}

Add-Type -AssemblyName System.Drawing

# Canonical YoRHa sand/khaki tone: RGB(157, 152, 129)
$r = 157
$g = 152
$b = 129

$halfLine = $LineWidth / 2.0
$dotRadius = $DotSize / 2.0
$bmp = New-Object System.Drawing.Bitmap($TileSize, $TileSize, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

if ($Diagonal) {
    # -------------------------------------------------------------
    # Diagonal (45-degree Diamond Lattice) Mode
    # -------------------------------------------------------------
    $offset = 3.0
    $sqrt2 = [Math]::Sqrt(2.0)

    # 4 Symmetrically centered dot crossings at 18px intervals
    $dotCenters = @(
        @{X=6;  Y=9},
        @{X=24; Y=9},
        @{X=6;  Y=27},
        @{X=24; Y=27}
    )

    for ($y = 0; $y -lt $TileSize; $y++) {
        for ($x = 0; $x -lt $TileSize; $x++) {
            # Diagonal 1: x + y - offset
            $u = ($x + $y - $offset)
            $nearestU = [Math]::Round($u / [double]$GridSpacing) * $GridSpacing
            $distD1 = [Math]::Abs($u - $nearestU) / $sqrt2

            # Diagonal 2: x - y - offset
            $v = ($x - $y - $offset)
            $nearestV = [Math]::Round($v / [double]$GridSpacing) * $GridSpacing
            $distD2 = [Math]::Abs($v - $nearestV) / $sqrt2

            $distLine = [Math]::Min($distD1, $distD2)

            # Subpixel antialiased line coverage
            $lineCoverage = 0.0
            if ($distLine -le ($halfLine - 0.5)) {
                $lineCoverage = 1.0
            } elseif ($distLine -lt ($halfLine + 0.5)) {
                $lineCoverage = ($halfLine + 0.5 - $distLine)
            }
            $aLine = $LineAlpha * $lineCoverage

            # Distance to nearest accent dot
            $minDotDist = [double]::MaxValue
            foreach ($dc in $dotCenters) {
                $d = [Math]::Sqrt([Math]::Pow($x - $dc.X, 2) + [Math]::Pow($y - $dc.Y, 2))
                if ($d -lt $minDotDist) { $minDotDist = $d }
            }

            # Subpixel antialiased dot coverage
            $dotCoverage = 0.0
            if ($minDotDist -le ($dotRadius - 0.5)) {
                $dotCoverage = 1.0
            } elseif ($minDotDist -lt ($dotRadius + 0.5)) {
                $dotCoverage = ($dotRadius + 0.5 - $minDotDist)
            }

            if ($dotCoverage -gt 0) {
                $aDot = $aLine + ($DotAlpha - $aLine) * $dotCoverage
                $finalA = [Math]::Min(255, [Math]::Max([int]$aLine, [int]$aDot))
            } else {
                $finalA = [Math]::Min(255, [int]$aLine)
            }

            if ($finalA -gt 0) {
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($finalA, $r, $g, $b))
            } else {
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            }
        }
    }
} else {
    # -------------------------------------------------------------
    # Orthogonal (0° / 90° Square Grid) Mode
    # -------------------------------------------------------------
    $offset = [Math]::Floor($GridSpacing / 2.0)
    $halfInterval = [Math]::Floor($DotInterval / 2.0)

    $dotCenters = @()
    for ($cy = $halfInterval; $cy -lt $TileSize; $cy += $DotInterval) {
        for ($cx = $halfInterval; $cx -lt $TileSize; $cx += $DotInterval) {
            $dotCenters += [PSCustomObject]@{ X = $cx; Y = $cy }
        }
    }

    for ($y = 0; $y -lt $TileSize; $y++) {
        for ($x = 0; $x -lt $TileSize; $x++) {
            # Distance to nearest vertical line
            $nearestLineX = $offset + [Math]::Round(($x - $offset) / [double]$GridSpacing) * $GridSpacing
            $dxLine = [Math]::Abs($x - $nearestLineX)

            # Distance to nearest horizontal line
            $nearestLineY = $offset + [Math]::Round(($y - $offset) / [double]$GridSpacing) * $GridSpacing
            $dyLine = [Math]::Abs($y - $nearestLineY)

            $distLine = [Math]::Min($dxLine, $dyLine)

            $lineCoverage = 0.0
            if ($distLine -le ($halfLine - 0.5)) {
                $lineCoverage = 1.0
            } elseif ($distLine -lt ($halfLine + 0.5)) {
                $lineCoverage = ($halfLine + 0.5 - $distLine)
            }
            $aLine = $LineAlpha * $lineCoverage

            $minDotDist = [double]::MaxValue
            foreach ($dc in $dotCenters) {
                $d = [Math]::Sqrt([Math]::Pow($x - $dc.X, 2) + [Math]::Pow($y - $dc.Y, 2))
                if ($d -lt $minDotDist) { $minDotDist = $d }
            }

            $dotCoverage = 0.0
            if ($minDotDist -le ($dotRadius - 0.5)) {
                $dotCoverage = 1.0
            } elseif ($minDotDist -lt ($dotRadius + 0.5)) {
                $dotCoverage = ($dotRadius + 0.5 - $minDotDist)
            }

            if ($dotCoverage -gt 0) {
                $aDot = $aLine + ($DotAlpha - $aLine) * $dotCoverage
                $finalA = [Math]::Min(255, [Math]::Max([int]$aLine, [int]$aDot))
            } else {
                $finalA = [Math]::Min(255, [int]$aLine)
            }

            if ($finalA -gt 0) {
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($finalA, $r, $g, $b))
            } else {
                $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            }
        }
    }
}

$outDir = Split-Path $OutputPath -Parent
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

$modeStr = if ($Diagonal) { "Diagonal (45° Diamond Lattice)" } else { "Orthogonal (Square Grid)" }
Write-Host "YoRHa Lattice Tile Updated:" -ForegroundColor Green
Write-Host "   Target File : $OutputPath"
Write-Host "   Pattern Mode: $modeStr"
Write-Host "   Line Width  : ${LineWidth} px"
Write-Host "   Dot Size    : ${DotSize} px"
Write-Host "   Grid Spacing: ${GridSpacing} px (Full-Opened)"
Write-Host "   Dot Interval: ${DotInterval} px"
Write-Host "   Line Alpha  : $LineAlpha / 255"
Write-Host "   Dot Alpha   : $DotAlpha / 255"

# Auto-refresh Rainmeter if it's currently running
$rmProc = Get-Process Rainmeter -ErrorAction SilentlyContinue
if ($rmProc) {
    $rmExe = "C:\Program Files\Rainmeter\Rainmeter.exe"
    if (Test-Path $rmExe) {
        & $rmExe "!RefreshApp"
        Write-Host "Rainmeter skins refreshed successfully!" -ForegroundColor Cyan
    }
} else {
    Write-Host "   (Rainmeter is not currently running)" -ForegroundColor DarkGray
}
