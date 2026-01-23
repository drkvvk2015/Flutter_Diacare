# Comprehensive Final Fix Script
# Fixes common issues safely across the codebase

$fixCount = 0

# 1. Add unawaited() wrapper for intentional fire-and-forget futures
Write-Host "Adding unawaited() wrappers..." -ForegroundColor Cyan

# First, ensure unawaited is imported where needed
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse | Where-Object {
    $content = Get-Content $_.FullName -Raw
    $content -match 'FirebaseCrashlytics\.' -and $content -notmatch "import 'dart:async';"
}

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match "^import ") {
        $content = $content -replace "(^import [^\r\n]+\r?\n)", "`$1import 'dart:async' show unawaited;`r`n"
        $content | Set-Content $file.FullName -NoNewline
        $fixCount++
        Write-Host "  Added dart:async import to $($file.Name)"
    }
}

# 2. Fix print statements - replace with proper logger
Write-Host "`nReplacing print() with logger..." -ForegroundColor Cyan

$printFiles = @(
    "lib\api\interceptors\http_interceptor.dart",
    "lib\repositories\user_repository.dart"
)

foreach ($filePath in $printFiles) {
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        $original = $content
        
        # Add logger import if not present
        if ($content -notmatch "import.*logger") {
            $content = $content -replace "(^import [^\r\n]+\r?\n)", "`$1import '../utils/logger.dart';`r`n"
        }
        
        # Add logger instance if not present
        if ($content -notmatch "final.*Logger.*=") {
            $content = $content -replace "(class \w+[^{]+\{)", "`$1`r`n  final _logger = Logger('`${className}');`r`n"
        }
        
        # Replace print statements
        $content = $content -replace "print\(([^)]+)\);", "_logger.debug(`$1);"
        
        if ($content -ne $original) {
            $content | Set-Content $filePath -NoNewline
            $fixCount++
            Write-Host "  Fixed print statements in $filePath"
        }
    }
}

# 3. Fix TODO formatting
Write-Host "`nFixing TODO comments..." -ForegroundColor Cyan

$todoPattern = '\s*//\s*TODO[:\s]+(.+)'
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    $content = $content -replace '//\s*TODO:\s*(.+)', '// TODO(dev): $1'
    $content = $content -replace '//\s*TODO\s+(.+)', '// TODO(dev): $1'
    
    if ($content -ne $original) {
        $content | Set-Content $file.FullName -NoNewline
        $fixCount++
        Write-Host "  Fixed TODOs in $($file.Name)"
    }
}

# 4. Add missing newlines at end of files
Write-Host "`nAdding missing newlines at EOF..." -ForegroundColor Cyan

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -and -not $content.EndsWith("`n")) {
        $content += "`n"
        $content | Set-Content $file.FullName -NoNewline
        $fixCount++
        Write-Host "  Added newline to $($file.Name)"
    }
}

# 5. Fix bool parameters hint - convert to named parameters (manual intervention needed)
Write-Host "`nDetecting bool parameter issues..." -ForegroundColor Yellow
flutter analyze 2>&1 | Select-String "avoid_positional_boolean_parameters" | Select-Object -First 5

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Total automated fixes applied: $fixCount"
Write-Host "`nRunning flutter analyze..."

flutter analyze 2>&1 | Select-String -Pattern "issues? found"
