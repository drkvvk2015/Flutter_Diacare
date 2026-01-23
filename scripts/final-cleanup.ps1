# Final Comprehensive Flutter Lint Cleanup
# Fixes: directive ordering, constructor ordering, const usage, etc.

$ErrorActionPreference = "Continue"
$totalFixed = 0

Write-Host "Starting final cleanup of ~1100 issues..." -ForegroundColor Cyan

$dartFiles = Get-ChildItem -Path "lib","test" -Filter "*.dart" -Recurse -File |
    Where-Object { $_.FullName -notlike "*\.vs\*" -and $_.FullName -notlike "*\build\*" }

Write-Host "Processing $($dartFiles.Count) files..." -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrEmpty($content)) { continue }
    $original = $content
    
    # Fix directive ordering - sort imports
    if ($content -match "^import ") {
        $lines = $content -split "`n"
        $beforeImports = @()
        $dartImports = @()
        $packageImports = @()
        $relativeImports = @()
        $afterImports = @()
        $inImportSection = $false
        
        foreach ($line in $lines) {
            if ($line -match "^import 'dart:") {
                $dartImports += $line
                $inImportSection = $true
            }
            elseif ($line -match "^import 'package:") {
                $packageImports += $line
                $inImportSection = $true
            }
            elseif ($line -match "^import ") {
                $relativeImports += $line
                $inImportSection = $true
            }
            elseif ($inImportSection -and $line -match "^\s*$") {
                continue
            }
            elseif ($inImportSection) {
                $afterImports += $line
                $inImportSection = $false
            }
            elseif (-not $inImportSection -and $dartImports.Count -eq 0) {
                $beforeImports += $line
            }
            else {
                $afterImports += $line
            }
        }
        
        # Sort each section
        $dartImports = $dartImports | Sort-Object
        $packageImports = $packageImports | Sort-Object
        $relativeImports = $relativeImports | Sort-Object
        
        # Rebuild file
        $newContent = @()
        $newContent += $beforeImports
        if ($dartImports.Count -gt 0) {
            $newContent += $dartImports
            $newContent += ""
        }
        if ($packageImports.Count -gt 0) {
            $newContent += $packageImports
            $newContent += ""
        }
        if ($relativeImports.Count -gt 0) {
            $newContent += $relativeImports
            $newContent += ""
        }
        $newContent += $afterImports
        
        $content = $newContent -join "`n"
    }
    
    # Add 'library;' after doc comments if missing
    $content = $content -replace '(?m)^(///.*(?:\r?\n///.*)*)\r?\n\r?\n(?!library)', '$1' + "`nlibrary;`n`n"
    
    # Fix avoid_relative_lib_imports in test files
    if ($file.FullName -like "*\test\*") {
        $content = $content -replace "import '../../lib/", "import 'package:flutter_diacare/"
    }
    
    # Fix const EdgeInsets
    $content = $content -replace '(\s+)EdgeInsets\.', '$1const EdgeInsets.'
    
    # Fix const Text (simple cases)
    $content = $content -replace "child: Text\('", "child: const Text('"
    $content = $content -replace "return Text\('", "return const Text('"
    
    # Fix const Icon
    $content = $content -replace "child: Icon\(", "child: const Icon("
    $content = $content -replace "leading: Icon\(", "leading: const Icon("
    
    # Fix prefer_const_declarations
    $content = $content -replace '(?m)^(\s+)final (\w+) = EdgeInsets\.', '$1const $2 = EdgeInsets.'
    $content = $content -replace '(?m)^(\s+)final (\w+) = Duration\(', '$1const $2 = Duration('
    
    # Fix unnecessary raw strings (simple cases)
    $content = $content -replace "r'([^'\\]*)'", "'$1'"
    
    # Fix unnecessary null checks (remove redundant !)
    # This is complex, skip for now as it might break code
    
    # Write if changed
    if ($content -ne $original) {
        try {
            Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
            $totalFixed++
            $name = $file.Name
            Write-Host "  Fixed: $name" -ForegroundColor Green
        }
        catch {
            Write-Host "  Error: $($file.Name)" -ForegroundColor Red
        }
    }
}

Write-Host "`nFixed $totalFixed files" -ForegroundColor Green
Write-Host "Running flutter analyze to check results..." -ForegroundColor Cyan
flutter analyze 2>&1 | Select-String "issues found" | Select-Object -Last 1
