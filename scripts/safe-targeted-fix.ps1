# Targeted Safe Fixes - No Regex, Direct File Reading
# Fixes only verified safe issues

$ErrorActionPreference = "Continue"
Write-Host "Starting targeted safe fixes..." -ForegroundColor Cyan

# FIX 1: Remove test file TODO style issues
$todoFixes = @(
    "test\providers\appointment_provider_test.dart",
    "test\providers\user_provider_test.dart",
    "test\services\health_service_test.dart",
    "test\services\security_service_test.dart"
)

foreach ($filePath in $todoFixes) {
    $fullPath = Join-Path $PWD $filePath
    if (Test-Path $fullPath) {
        $lines = Get-Content $fullPath
        $modified = $false
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match '^\s*//\s*TODO:\s*(.+)$') {
                $lines[$i] = $lines[$i] -replace '//\s*TODO:\s*', '// TODO(developer): '
                $modified = $true
            }
            elseif ($lines[$i] -match '^\s*//\s*TODO\s+([^:(].+)$') {
                $lines[$i] = $lines[$i] -replace '//\s*TODO\s+', '// TODO(developer): '
                $modified = $true
            }
        }
        if ($modified) {
            Set-Content $fullPath ($lines -join "`n") -NoNewline
            Write-Host "  Fixed TODO in $filePath" -ForegroundColor Green
        }
    }
}

# FIX 2: Comment out unused test variables
$unusedVars = @{
    "test\repositories\user_repository_test.dart" = @(15)
    "test\services\health_service_test.dart" = @(29)
    "test\services\security_service_test.dart" = @(40, 78, 87)
}

foreach ($file in $unusedVars.Keys) {
    $fullPath = Join-Path $PWD $file
    if (Test-Path $fullPath) {
        $lines = Get-Content $fullPath
        foreach ($lineNum in $unusedVars[$file]) {
            if ($lineNum -le $lines.Count) {
                $line = $lines[$lineNum - 1]
                if ($line -notmatch '^\s*//') {
                    $lines[$lineNum - 1] = '    // ' + $line.TrimStart()
                }
            }
        }
        Set-Content $fullPath ($lines -join "`n") -NoNewline
        Write-Host "  Commented unused vars in $file" -ForegroundColor Green
    }
}

# FIX 3: Remove specific unused imports
$importFixes = @{
    "test\services\health_service_test.dart" = @("import 'package:health/health.dart';", "import 'package:mockito/annotations.dart';")
}

foreach ($file in $importFixes.Keys) {
    $fullPath = Join-Path $PWD $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        foreach ($import in $importFixes[$file]) {
            $content = $content -replace [regex]::Escape($import) + "\s*\n", ""
        }
        Set-Content $fullPath $content -NoNewline
        Write-Host "  Removed unused imports from $file" -ForegroundColor Green
    }
}

Write-Host "`nRunning flutter analyze..." -ForegroundColor Cyan
$output = flutter analyze 2>&1 | Out-String
if ($output -match '(\d+) issues found') {
    Write-Host "Issues: $($matches[1])" -ForegroundColor Yellow
}
