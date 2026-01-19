# DiaCare iOS Release Build Script

# Check if running on macOS
if ($IsMacOS) {
    Write-Host "Building iOS Release..." -ForegroundColor Green
    
    # Build iOS
    flutter build ios --release
    
    # Build IPA (requires proper signing)
    flutter build ipa --release
    
    Write-Host "`n✅ iOS build completed!" -ForegroundColor Green
    Write-Host "IPA location: build\ios\ipa\" -ForegroundColor Cyan
} else {
    Write-Host "❌ iOS builds require macOS" -ForegroundColor Red
}
