# DiaCare Testing Script

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      DiaCare Test Suite                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host "`n🧪 Running tests..." -ForegroundColor Green

# Run Flutter analyze
Write-Host "`n1️⃣  Running static analysis..." -ForegroundColor Yellow
flutter analyze
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Static analysis passed" -ForegroundColor Green
} else {
    Write-Host "✗ Static analysis found issues" -ForegroundColor Red
}

# Run tests
Write-Host "`n2️⃣  Running unit tests..." -ForegroundColor Yellow
flutter test
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Tests passed" -ForegroundColor Green
} else {
    Write-Host "✗ Tests failed" -ForegroundColor Red
}

# Generate coverage
Write-Host "`n3️⃣  Generating coverage report..." -ForegroundColor Yellow
flutter test --coverage
if (Test-Path "coverage\lcov.info") {
    Write-Host "✓ Coverage report generated" -ForegroundColor Green
    Write-Host "   Location: coverage\lcov.info" -ForegroundColor Cyan
} else {
    Write-Host "⚠️  Coverage report not generated" -ForegroundColor Yellow
}

Write-Host "`n✅ Test suite completed!" -ForegroundColor Green
