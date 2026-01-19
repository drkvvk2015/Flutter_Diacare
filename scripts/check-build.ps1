# Check if APK build is complete
$apkPath = "d:\Flutter_Diacare\build\app\outputs\flutter-apk\app-debug.apk"

Write-Host "`n🔍 Checking build status..." -ForegroundColor Cyan

if (Test-Path $apkPath) {
    $apk = Get-Item $apkPath
    $sizeInMB = [math]::Round($apk.Length / 1MB, 2)
    
    Write-Host "`n✅ BUILD SUCCESSFUL!" -ForegroundColor Green
    Write-Host "`n📦 APK Details:" -ForegroundColor Yellow
    Write-Host "   Location: $apkPath" -ForegroundColor White
    Write-Host "   Size: $sizeInMB MB" -ForegroundColor White
    Write-Host "   Created: $($apk.LastWriteTime)" -ForegroundColor White
    
    Write-Host "`n📱 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Connect your Android device via USB" -ForegroundColor White
    Write-Host "   2. Enable USB debugging on your device" -ForegroundColor White
    Write-Host "   3. Run: flutter install" -ForegroundColor Cyan
    Write-Host "   OR copy the APK to your phone and install manually" -ForegroundColor White
    
} else {
    Write-Host "`n⏳ Build in progress..." -ForegroundColor Yellow
    Write-Host "   The APK will be at: $apkPath" -ForegroundColor White
    Write-Host "   Run this script again to check status" -ForegroundColor White
}
