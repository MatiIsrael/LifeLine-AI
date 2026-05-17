Set-Location "$PSScriptRoot\..\dashboard"
if (-not (Test-Path "node_modules")) { npm install }
npm run dev
