# validate_project.ps1 - Native PowerShell Validation Suite for Waypoint Lab
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Waypoint Lab - Native PowerShell Validator" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$BaseDir = $PSScriptRoot
if (-not $BaseDir) { $BaseDir = Get-Location }

$ProjectDir = Join-Path $BaseDir "WaypointLab"
$PbxPath = Join-Path $BaseDir "WaypointLab.xcodeproj\project.pbxproj"
$InfoPlist = Join-Path $ProjectDir "Resources\Info.plist"
$GpxPath = Join-Path $ProjectDir "Resources\SampleRoute.gpx"
$WorkflowPath = Join-Path $BaseDir ".github\workflows\build.yml"
$BuildScriptPath = Join-Path $BaseDir "build_ipa.sh"

$RequiredFiles = @(
    (Join-Path $ProjectDir "WaypointLabApp.swift"),
    (Join-Path $ProjectDir "Models\Waypoint.swift"),
    (Join-Path $ProjectDir "Models\RoutePoint.swift"),
    (Join-Path $ProjectDir "Services\LocationManager.swift"),
    (Join-Path $ProjectDir "Services\SearchService.swift"),
    (Join-Path $ProjectDir "Services\RouteSimulationManager.swift"),
    (Join-Path $ProjectDir "Services\FavoritesManager.swift"),
    (Join-Path $ProjectDir "Views\MainTabView.swift"),
    (Join-Path $ProjectDir "Views\MapView.swift"),
    (Join-Path $ProjectDir "Views\ManualCoordinateView.swift"),
    (Join-Path $ProjectDir "Views\SearchView.swift"),
    (Join-Path $ProjectDir "Views\RouteSimulationView.swift"),
    (Join-Path $ProjectDir "Views\FavoritesView.swift"),
    (Join-Path $ProjectDir "Views\SettingsView.swift"),
    $InfoPlist,
    $GpxPath,
    $PbxPath,
    $WorkflowPath,
    $BuildScriptPath
)

Write-Host "`n[1/6] Checking file structure..." -ForegroundColor Yellow
foreach ($file in $RequiredFiles) {
    if (Test-Path $file) {
        $rel = Resolve-Path -Relative $file
        Write-Host "  [PASS] Found: $rel" -ForegroundColor Green
    } else {
        Write-Error "  [FAIL] Missing file: $file"
    }
}

Write-Host "`n[2/6] Validating SampleRoute.gpx XML..." -ForegroundColor Yellow
[xml]$gpxXml = Get-Content $GpxPath
$trkpts = $gpxXml.gpx.trk.trkseg.trkpt
Write-Host "  [INFO] Extracted $($trkpts.Count) trackpoints." -ForegroundColor Gray
foreach ($pt in $trkpts) {
    $lat = [double]$pt.lat
    $lon = [double]$pt.lon
    if ($lat -lt -90.0 -or $lat -gt 90.0 -or $lon -lt -180.0 -or $lon -gt 180.0) {
        Write-Error "Coordinates out of bounds: $lat, $lon"
    }
}
Write-Host "  [PASS] All trackpoints valid within WGS84 bounds." -ForegroundColor Green

Write-Host "`n[3/6] Checking Info.plist privacy keys..." -ForegroundColor Yellow
[xml]$plistXml = Get-Content $InfoPlist
$keys = $plistXml.plist.dict.key
$requiredKeys = @("CFBundleDisplayName", "CFBundleIdentifier", "NSLocationWhenInUseUsageDescription", "LSRequiresIPhoneOS")
foreach ($rk in $requiredKeys) {
    if ($keys -contains $rk) {
        Write-Host "  [PASS] Found key: $rk" -ForegroundColor Green
    } else {
        Write-Error "Missing key: $rk"
    }
}

Write-Host "`n[4/6] Checking Xcode project file references..." -ForegroundColor Yellow
$pbxContent = Get-Content $PbxPath -Raw
if ($pbxContent -match "WaypointLabApp\.swift" -and $pbxContent -match "com\.example\.waypointlab") {
    Write-Host "  [PASS] Project definitions and bundle identifier verified." -ForegroundColor Green
} else {
    Write-Error "PBX project file missing essential configurations."
}

Write-Host "`n[5/6] Checking Swift syntax balance..." -ForegroundColor Yellow
$swiftFiles = Get-ChildItem -Path $ProjectDir -Filter "*.swift" -Recurse
foreach ($sf in $swiftFiles) {
    $code = Get-Content $sf.FullName -Raw
    $openB = ($code.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $closeB = ($code.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    if ($openB -ne $closeB) {
        Write-Error "Mismatched braces in $($sf.Name): $openB open, $closeB close"
    }
    Write-Host "  [PASS] Syntax sanity verified: $($sf.Name)" -ForegroundColor Green
}

Write-Host "`n[6/6] Validating GitHub Actions CI workflow..." -ForegroundColor Yellow
$wfContent = Get-Content $WorkflowPath -Raw
if ($wfContent -match "runs-on:\s*macos-latest" -and $wfContent -match "actions/upload-artifact@v4" -and $wfContent -match "CODE_SIGNING_ALLOWED=NO") {
    Write-Host "  [PASS] GitHub Actions workflow configuration verified." -ForegroundColor Green
} else {
    Write-Error "GitHub Actions workflow missing required build parameters."
}

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  ALL VALIDATION CHECKS PASSED [OK]" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
