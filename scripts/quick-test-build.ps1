# DiaCare Quick Test Build Script
# Builds debug APK for immediate testing

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   DiaCare Quick Test Build             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

# Set Flutter path
$env:PATH = "C:\Users\CNSHO\develop\flutter\bin;$env:PATH"

Write-Host "`n📍 Working directory: d:\Flutter_Diacare" -ForegroundColor Yellow
Set-Location d:\Flutter_Diacare

# Check Flutter
Write-Host "`n1️⃣  Checking Flutter..." -ForegroundColor Yellow
flutter --version

# Get dependencies
Write-Host "`n2️⃣  Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Generate code (skip if it fails)
Write-Host "`n3️⃣  Generating code (optional)..." -ForegroundColor Yellow
try {
    flutter pub run build_runner build --delete-conflicting-outputs
} catch {
    Write-Host "⚠️  Code generation skipped (will use existing generated files)" -ForegroundColor Yellow
}

# Build debug APK
Write-Host "`n4️⃣  Building DEBUG APK for testing..." -ForegroundColor Green
Write-Host "   This may take a few minutes..." -ForegroundColor Cyan
flutter build apk --debug

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Build successful!" -ForegroundColor Green
    Write-Host "`n📦 APK Location:" -ForegroundColor Yellow
    Write-Host "   d:\Flutter_Diacare\build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Cyan
    Write-Host "`n📱 To install on device:" -ForegroundColor Yellow
    Write-Host "   1. Connect your Android device via USB" -ForegroundColor White
    Write-Host "   2. Enable USB debugging" -ForegroundColor White
    Write-Host "   3. Run: flutter install" -ForegroundColor White
    Write-Host "   OR copy the APK to your phone and install manually" -ForegroundColor White
} else {
    Write-Host "`n❌ Build failed. Check errors above." -ForegroundColor Red
}

Write-Host "`n🚀 Done!" -ForegroundColor Green
