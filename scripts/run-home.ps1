Set-Location "$PSScriptRoot\..\home"
Write-Host "Opening http://localhost:4000"
npx --yes serve . -l 4000
