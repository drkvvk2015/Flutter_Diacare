# DiaCare Web Production Build Script

Write-Host "Building Web (Release)..." -ForegroundColor Green

# Build web with optimizations
flutter build web --release --web-renderer canvaskit

Write-Host "`n✅ Web build completed!" -ForegroundColor Green
Write-Host "Build location: build\web\" -ForegroundColor Cyan
Write-Host "`nTo deploy to Firebase Hosting:" -ForegroundColor Yellow
Write-Host "  firebase deploy --only hosting" -ForegroundColor White
