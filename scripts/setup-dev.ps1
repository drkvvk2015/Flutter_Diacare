# DiaCare Development Setup Script

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   DiaCare Development Setup            ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n🚀 Setting up DiaCare for development..." -ForegroundColor Green

# Check Flutter installation
Write-Host "`n1️⃣  Checking Flutter installation..." -ForegroundColor Yellow
try {
    flutter --version
    Write-Host "✓ Flutter is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Flutter not found. Please install Flutter SDK first." -ForegroundColor Red
    Write-Host "   Visit: https://docs.flutter.dev/get-started/install" -ForegroundColor Cyan
    exit 1
}

# Get Flutter packages
Write-Host "`n2️⃣  Installing Flutter packages..." -ForegroundColor Yellow
flutter pub get

# Check for .env file
Write-Host "`n3️⃣  Checking environment configuration..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "✓ .env file exists" -ForegroundColor Green
} else {
    Write-Host "⚠️  .env file not found. Creating from template..." -ForegroundColor Yellow
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "✓ Created .env file. Please update with your API keys!" -ForegroundColor Green
    } else {
        Write-Host "✗ .env.example not found" -ForegroundColor Red
    }
}

# Generate Hive adapters
Write-Host "`n4️⃣  Generating code (Hive adapters)..." -ForegroundColor Yellow
flutter pub run build_runner build --delete-conflicting-outputs

# Check Firebase configuration
Write-Host "`n5️⃣  Checking Firebase configuration..." -ForegroundColor Yellow
if (Test-Path "lib\firebase_options.dart") {
    Write-Host "✓ Firebase configuration exists" -ForegroundColor Green
} else {
    Write-Host "⚠️  Firebase not configured. Run: flutterfire configure" -ForegroundColor Yellow
}

# Check Android signing
Write-Host "`n6️⃣  Checking Android signing configuration..." -ForegroundColor Yellow
if (Test-Path "android\key.properties") {
    Write-Host "✓ Android signing configured" -ForegroundColor Green
} else {
    Write-Host "⚠️  Android signing not configured" -ForegroundColor Yellow
    Write-Host "   For release builds, copy android\key.properties.example to android\key.properties" -ForegroundColor Cyan
}

# Run Flutter doctor
Write-Host "`n7️⃣  Running Flutter doctor..." -ForegroundColor Yellow
flutter doctor

Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "`n✅ Setup completed!" -ForegroundColor Green
Write-Host "`n📋 Configuration Checklist:" -ForegroundColor Yellow
Write-Host "   [ ] Update .env with your API keys (Agora, Razorpay, etc.)" -ForegroundColor White
Write-Host "   [ ] Configure Firebase (run: flutterfire configure)" -ForegroundColor White
Write-Host "   [ ] Set up Android signing for release builds" -ForegroundColor White
Write-Host "   [ ] Configure Firebase Firestore security rules" -ForegroundColor White
Write-Host "`n🎯 You're ready to start developing!" -ForegroundColor Cyan
Write-Host "`nTo run the app:" -ForegroundColor Yellow
Write-Host "  flutter run" -ForegroundColor White
