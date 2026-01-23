# Safe Manual Fixes Script
# Only fixes non-breaking style issues

Write-Host "=== Starting Safe Manual Fixes ===" -ForegroundColor Cyan
$fixCount = 0

# 1. Add library doc comments (safe)
Write-Host "`n1. Adding library declarations..." -ForegroundColor Yellow
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse -File
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match '^///[^\r\n]+\r?\n///[^\r\n]+\r?\n(?!library)') {
        $content = $content -replace '(^///[^\r\n]+\r?\n///[^\r\n]+\r?\n)', "`$1library;`r`n`r`n"
        $content | Set-Content $file.FullName -NoNewline
        $fixCount++
    }
}
Write-Host "  Added library declarations: $fixCount files"

# 2. Fix import ordering (organize imports alphabetically)
Write-Host "`n2. Organizing imports..." -ForegroundColor Yellow
$importFixes = 0
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse -File | Select-Object -First 20
foreach ($file in $files) {
    $lines = Get-Content $file.FullName
    $imports = @()
    $dartImports = @()
    $packageImports = @()
    $relativeImports = @()
    $otherLines = @()
    $inImports = $false
    
    foreach ($line in $lines) {
        if ($line -match "^import 'dart:") {
            $dartImports += $line
            $inImports = $true
        }
        elseif ($line -match "^import 'package:") {
            $packageImports += $line
            $inImports = $true
        }
        elseif ($line -match "^import '\.\.?/") {
            $relativeImports += $line
            $inImports = $true
        }
        elseif ($line -match "^(import|export)") {
            $imports += $line
            $inImports = $true
        }
        else {
            $otherLines += $line
        }
    }
    
    if ($dartImports.Count -gt 0 -or $packageImports.Count -gt 0 -or $relativeImports.Count -gt 0) {
        $sortedContent = @()
        if ($dartImports.Count -gt 0) {
            $sortedContent += ($dartImports | Sort-Object)
        }
        if ($packageImports.Count -gt 0) {
            if ($sortedContent.Count -gt 0) { $sortedContent += "" }
            $sortedContent += ($packageImports | Sort-Object)
        }
        if ($relativeImports.Count -gt 0) {
            if ($sortedContent.Count -gt 0) { $sortedContent += "" }
            $sortedContent += ($relativeImports | Sort-Object)
        }
        $sortedContent += $otherLines
        
        $sortedContent -join "`r`n" | Set-Content $file.FullName -NoNewline
        $importFixes++
    }
}
Write-Host "  Organized imports in: $importFixes files"

# 3. Add missing EOF newlines
Write-Host "`n3. Adding EOF newlines..." -ForegroundColor Yellow
$eofFixes = 0
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse -File
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    if ($content -and -not $content.EndsWith("`n")) {
        $content += "`n"
        $content | Set-Content $file.FullName -NoNewline
        $eofFixes++
    }
}
Write-Host "  Added EOF newlines: $eofFixes files"

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Library declarations: $fixCount"
Write-Host "Import organization: $importFixes"
Write-Host "EOF newlines: $eofFixes"
Write-Host "Total: $($fixCount + $importFixes + $eofFixes) fixes"

Write-Host "`nRunning flutter analyze..." -ForegroundColor Cyan
flutter analyze 2>&1 | Select-String -Pattern "issues? found"
