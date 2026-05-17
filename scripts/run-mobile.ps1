$flutter = "C:\src\flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) { $flutter = "flutter" }

Set-Location "$PSScriptRoot\..\mobile"

& $flutter pub get
& $flutter create . --org com.lifeline --project-name lifeline_ai --platforms=android,ios,web
& $flutter run
