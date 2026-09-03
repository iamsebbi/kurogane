# Kurogane Android Port Forwarding Utility
# Forwards port 4000 on all connected physical devices and emulators to host localhost:4000

$adbPath = "adb"
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    $fallbackAdb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $fallbackAdb) {
        $adbPath = $fallbackAdb
    } else {
        Write-Error "adb not found in PATH or Android SDK folder ($fallbackAdb)."
        exit 1
    }
}

Write-Host "Verificare dispozitive Android conectate..." -ForegroundColor Cyan
$rawLines = & $adbPath devices
$devices = @()

foreach ($line in $rawLines) {
    $trimmed = $line.Trim()
    if ($trimmed -and -not $trimmed.StartsWith("List of devices")) {
        $parts = $trimmed -split '\s+'
        if ($parts.Count -ge 2 -and $parts[1] -eq "device") {
            $devices += $parts[0]
        }
    }
}

if ($devices.Count -eq 0) {
    Write-Warning "Niciun dispozitiv Android (telefon sau emulator) activ nu a fost gasit."
    exit 0
}

Write-Host "Dispozitive gasite: $($devices.Count)" -ForegroundColor Green
foreach ($dev in $devices) {
    Write-Host " -> Configurare port reverse 4000 pentru [$dev]..." -NoNewline
    $res = & $adbPath -s $dev reverse tcp:4000 tcp:4000
    if ($LASTEXITCODE -eq 0) {
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        Write-Host " [FAIL: $res]" -ForegroundColor Red
    }
}

Write-Host "Conexiunea este pregatita! Telefonul si emulatorul pot accesa API-ul la http://127.0.0.1:4000" -ForegroundColor Green
