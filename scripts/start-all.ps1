# Lifeline AI — start everything (one command)
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host "`n=== Lifeline AI — starting all services ===`n" -ForegroundColor Cyan

# Env files (safe defaults, no secrets committed)
if (-not (Test-Path "backend\.env")) {
  Copy-Item "backend\.env.example" "backend\.env"
  Write-Host "Created backend/.env" -ForegroundColor Yellow
}
if (-not (Test-Path "dashboard\.env")) {
  Copy-Item "dashboard\.env.example" "dashboard\.env"
  Write-Host "Created dashboard/.env" -ForegroundColor Yellow
}

# Install dependencies if needed
if (-not (Test-Path "backend\node_modules")) {
  Write-Host "Installing backend..." -ForegroundColor Gray
  Set-Location "$Root\backend"; npm install --silent
  Set-Location $Root
}
if (-not (Test-Path "dashboard\node_modules")) {
  Write-Host "Installing dashboard..." -ForegroundColor Gray
  Set-Location "$Root\dashboard"; npm install --silent
  Set-Location $Root
}

function Start-LifelineJob {
  param($Name, $Dir, $Command, $Port)
  $existing = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($existing) {
    Write-Host "  $Name already on port $Port" -ForegroundColor DarkGray
    return
  }
  Start-Process powershell -WindowStyle Minimized -ArgumentList @(
    "-NoExit", "-Command",
    "Set-Location '$Dir'; Write-Host '$Name on http://localhost:$Port' -ForegroundColor Green; $Command"
  ) | Out-Null
  Write-Host "  Started $Name -> http://localhost:$Port" -ForegroundColor Green
}

Start-LifelineJob "Backend API" "$Root\backend" "npm run dev" 8080
Start-Sleep -Seconds 2
Start-LifelineJob "Command dashboard" "$Root\dashboard" "npm run dev" 5173
Start-LifelineJob "Mobile preview" "$Root\preview" "npx --yes serve . -l 3000" 3000
Start-LifelineJob "Home alerts" "$Root\home" "npx --yes serve . -l 4000" 4000
Start-LifelineJob "Pitch deck" "$Root\hackathon" "npx --yes serve . -l 5000" 5000

Start-Sleep -Seconds 4

Write-Host "`nOpening in Chrome...`n" -ForegroundColor Cyan
$urls = @(
  "http://localhost:4000",
  "http://localhost:3000",
  "http://localhost:5173",
  "http://localhost:5000/pitch-deck.html"
)
foreach ($u in $urls) {
  Start-Process "chrome" $u -ErrorAction SilentlyContinue
}

Write-Host @"

  HOME (alerts)     http://localhost:4000
  MOBILE APP        http://localhost:3000
  COMMAND CENTER    http://localhost:5173  (key: lifeline-dashboard-dev)
  PITCH DECK        http://localhost:5000/pitch-deck.html
  API HEALTH        http://localhost:8080/health

  Dashboard login: lifeline-dashboard-dev
  Firebase optional — demo data works without serviceAccountKey.json

"@ -ForegroundColor White
