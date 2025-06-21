$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Resolve-Path (Join-Path $scriptDir "..")
$serverDir = Join-Path $rootDir "server"
$appDir = Join-Path $rootDir "my_app"

# Defaults for local MySQL + automatic dev seed data.
$dbHost = if ($env:DB_HOST) { $env:DB_HOST } else { "127.0.0.1" }
$dbPort = if ($env:DB_PORT) { $env:DB_PORT } else { "3306" }
$dbUser = if ($env:DB_USER) { $env:DB_USER } else { "root" }
$dbPassword = if ($env:DB_PASSWORD) { $env:DB_PASSWORD } else { "1234" }
$dbName = if ($env:DB_NAME) { $env:DB_NAME } else { "investments_db" }
$jwtSecret = if ($env:JWT_SECRET) { $env:JWT_SECRET } else { "CHANGE_THIS_SECRET_TO_SOMETHING_LONG_RANDOM" }
$devSeedEnabled = if ($env:DEV_SEED_ENABLED) { $env:DEV_SEED_ENABLED } else { "true" }
$devSeedEmail = if ($env:DEV_SEED_EMAIL) { $env:DEV_SEED_EMAIL } else { "dev@earn.local" }
$devSeedPassword = if ($env:DEV_SEED_PASSWORD) { $env:DEV_SEED_PASSWORD } else { "DevOnly@123" }
$devSeedOtpEmail = if ($env:DEV_SEED_OTP_EMAIL) { $env:DEV_SEED_OTP_EMAIL } else { "pending.dev@earn.local" }
$devSeedOtpCode = if ($env:DEV_SEED_OTP_CODE) { $env:DEV_SEED_OTP_CODE } else { "999999" }

# If backend is not reachable, start it in a separate PowerShell window.
$backendUp = $false
try {
    $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8080/health" -UseBasicParsing -TimeoutSec 2
    if ($resp.StatusCode -eq 200) {
        $backendUp = $true
    }
} catch {
    $backendUp = $false
}

if (-not $backendUp) {
    # Build command with proper escaping for nested PowerShell
    $backendCommand = @"
Set-Location '$serverDir'
`$env:DB_HOST = '$dbHost'
`$env:DB_PORT = '$dbPort'
`$env:DB_USER = '$dbUser'
`$env:DB_PASSWORD = '$dbPassword'
`$env:DB_NAME = '$dbName'
`$env:JWT_SECRET = '$jwtSecret'
`$env:DEV_SEED_ENABLED = '$devSeedEnabled'
`$env:DEV_SEED_EMAIL = '$devSeedEmail'
`$env:DEV_SEED_PASSWORD = '$devSeedPassword'
`$env:DEV_SEED_OTP_EMAIL = '$devSeedOtpEmail'
`$env:DEV_SEED_OTP_CODE = '$devSeedOtpCode'
dart run bin/server.dart
"@

    Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCommand
    Write-Host "Started backend server with auto schema + dev seed in a new PowerShell window."
} else {
    Write-Host "Backend already running on http://127.0.0.1:8080"
}

Set-Location $appDir
flutter run
