#!/usr/bin/env pwsh
# Comprehensive Flutter Code Cleanup Script

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting comprehensive code cleanup..." -ForegroundColor Cyan

# Get all Dart files excluding build artifacts
$dartFiles = Get-ChildItem -Path "lib","test" -Filter "*.dart" -Recurse -File |
    Where-Object { 
        $_.FullName -notlike "*\.vs\*" -and 
        $_.FullName -notlike "*\build\*"
    }

$totalFiles = $dartFiles.Count
$filesModified = 0

Write-Host "📁 Found $totalFiles Dart files" -ForegroundColor Yellow

$i = 0
foreach ($file in $dartFiles) {
    $i++
    Write-Progress -Activity "Processing" -Status "($i/$totalFiles)" -PercentComplete (($i/$totalFiles)*100)
    
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrEmpty($content)) { continue }
    
    $original = $content
    
    # Fix Future.delayed
    $content = $content -replace '(\W)Future\.delayed\(', '$1Future<void>.delayed('
    
    # Fix MaterialPageRoute
    $content = $content -replace '(\W)MaterialPageRoute\(', '$1MaterialPageRoute<void>('
    
    # Fix showDialog
    $content = $content -replace '(\W)showDialog\(', '$1showDialog<void>('
    
    # Fix showModalBottomSheet
    $content = $content -replace '(\W)showModalBottomSheet\(', '$1showModalBottomSheet<void>('
    
    # Fix openBox
    $content = $content -replace '(\W)openBox\(', '$1openBox<dynamic>('
    
    # Add const to simple widgets
    $content = $content -replace '(\W)Divider\(\)', '$1const Divider()'
    $content = $content -replace '(\W)Spacer\(\)', '$1const Spacer()'
    
    # Fix double literals  
    $content = $content -replace '(\d+)\.0\b', '$1'
    
    # Write if changed
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $filesModified++
        $relativePath = $file.FullName.Replace((Get-Location).Path + "\", "")
        Write-Host "  ✓ $relativePath" -ForegroundColor Green
    }
}

Write-Progress -Activity "Processing" -Completed
Write-Host ""
Write-Host "✨ Modified $filesModified files" -ForegroundColor Green
Write-Host ""
Write-Host "🔍 Running flutter analyze..." -ForegroundColor Cyan
flutter analyze
