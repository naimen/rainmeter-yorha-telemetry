param (
    [ValidateSet("Interleaved", "Light", "Dark")]
    [string]$Profile = "Interleaved"
)

$baseDir = "C:\Users\naimen\Documents\Rainmeter\Skins\YorHa"
$modules = @("Clock", "Calendar", "CPU", "GPU", "RAM", "Fans", "Disks", "Network")

# Determine target per module
$bindings = @{}
switch ($Profile) {
    "Interleaved" {
        $bindings = @{
            "Clock"    = "Dark"
            "Calendar" = "Light"
            "CPU"      = "Dark"
            "GPU"      = "Light"
            "RAM"      = "Dark"
            "Fans"     = "Light"
            "Disks"    = "Dark"
            "Network"  = "Light"
        }
    }
    "Light" {
        foreach ($m in $modules) { $bindings[$m] = "Light" }
    }
    "Dark" {
        foreach ($m in $modules) { $bindings[$m] = "Dark" }
    }
}

Write-Host "Applying Profile: $Profile" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

foreach ($m in $modules) {
    $mode = $bindings[$m]
    $moduleDir = Join-Path $baseDir $m
    $iniLink = Join-Path $moduleDir "$m.ini"
    $targetFile = "$m-$mode.ini"
    $targetFullPath = Join-Path $moduleDir $targetFile

    if (-not (Test-Path $targetFullPath)) {
        Write-Warning "Target file not found: $targetFullPath"
        continue
    }

    # Remove existing link or file
    if (Test-Path $iniLink) {
        Remove-Item $iniLink -Force
    }

    # Create relative symbolic link
    New-Item -ItemType SymbolicLink -Path $iniLink -Target $targetFile | Out-Null
    Write-Host "  [$m] -> $targetFile ($mode)" -ForegroundColor Green
}

Write-Host "`nRefreshing Rainmeter..." -ForegroundColor Cyan
& "C:\Program Files\Rainmeter\Rainmeter.exe" !RefreshApp
Write-Host "Done! Profile [$Profile] active." -ForegroundColor Green