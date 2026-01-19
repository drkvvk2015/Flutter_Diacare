# DiaCare Complete Build Script - All Platforms

param(
    [switch]$Android,
    [switch]$iOS,
    [switch]$Web,
    [switch]$All
)

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  DiaCare Production Build System      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

# Pre-build checks
Write-Host "`n🔍 Running pre-build checks..." -ForegroundColor Yellow

# Check Flutter
try {
    $flutterVersion = flutter --version 2>&1
    Write-Host "✓ Flutter is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter not found. Please install Flutter SDK." -ForegroundColor Red
    exit 1
}

# Clean previous builds
Write-Host "`n🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
flutter pub get

# Generate code (Hive adapters, etc.)
Write-Host "`n⚙️  Generating code..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

# Run analysis
Write-Host "`n🔎 Running code analysis..." -ForegroundColor Yellow
flutter analyze

Write-Host "`n" + "="*50 -ForegroundColor Cyan

# Build platforms
if ($All -or (-not $Android -and -not $iOS -and -not $Web)) {
    Write-Host "`n📦 Building ALL platforms..." -ForegroundColor Magenta
    
    # Android
    Write-Host "`n[1/3] Building Android..." -ForegroundColor Yellow
    & "$PSScriptRoot\build-android.ps1"
    
    # iOS (if on macOS)
    Write-Host "`n[2/3] Building iOS..." -ForegroundColor Yellow
    & "$PSScriptRoot\build-ios.ps1"
    
    # Web
    Write-Host "`n[3/3] Building Web..." -ForegroundColor Yellow
    & "$PSScriptRoot\build-web.ps1"
} else {
    if ($Android) {
        Write-Host "`n📦 Building Android..." -ForegroundColor Magenta
        & "$PSScriptRoot\build-android.ps1"
    }
    
    if ($iOS) {
        Write-Host "`n📦 Building iOS..." -ForegroundColor Magenta
        & "$PSScriptRoot\build-ios.ps1"
    }
    
    if ($Web) {
        Write-Host "`n📦 Building Web..." -ForegroundColor Magenta
        & "$PSScriptRoot\build-web.ps1"
    }
}

Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "`n✨ Build process completed!" -ForegroundColor Green
Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test the builds on actual devices" -ForegroundColor White
Write-Host "  2. Upload to respective stores/hosting" -ForegroundColor White
Write-Host "  3. Monitor Firebase Crashlytics for errors" -ForegroundColor White
Write-Host "`n🚀 Happy Deploying!" -ForegroundColor Cyan
