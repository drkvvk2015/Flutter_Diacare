# DiaCare Production Build Scripts

# Build Android Release APK (split per ABI for smaller size)
Write-Host "Building Android APK (Release - Split per ABI)..." -ForegroundColor Green
flutter build apk --release --split-per-abi

# Build Android App Bundle (for Play Store)
Write-Host "`nBuilding Android App Bundle (Release)..." -ForegroundColor Green
flutter build appbundle --release

Write-Host "`n✅ Android builds completed!" -ForegroundColor Green
Write-Host "APKs location: build\app\outputs\flutter-apk\" -ForegroundColor Cyan
Write-Host "App Bundle location: build\app\outputs\bundle\release\" -ForegroundColor Cyan
