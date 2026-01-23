# PowerShell script to automatically fix common Flutter analyze issues
# Run this with: .\scripts\fix-all-issues.ps1

Write-Host "Starting automated code cleanup..." -ForegroundColor Green

# Get all Dart files in lib and test directories
$dartFiles = Get-ChildItem -Path "lib","test" -Filter "*.dart" -Recurse -File | Where-Object { $_.FullName -notlike "*\.vs\*" -and $_.FullName -notlike "*\build\*" }

$totalFiles = $dartFiles.Count
$currentFile = 0
$changesCount = 0

Write-Host "Found $totalFiles Dart files to process" -ForegroundColor Cyan

foreach ($file in $dartFiles) {
    $currentFile++
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $fileChanged = $false
    
    Write-Progress -Activity "Processing files" -Status "$currentFile/$totalFiles - $($file.Name)" -PercentComplete (($currentFile / $totalFiles) * 100)
    
    # Fix type inference failures
    $content = $content -replace 'Future\.delayed\(', 'Future<void>.delayed('
    $content = $content -replace 'MaterialPageRoute\(', 'MaterialPageRoute<void>('
    $content = $content -replace 'showDialog\(', 'showDialog<void>('
    $content = $content -replace 'showModalBottomSheet\(', 'showModalBottomSheet<void>('
    
    # Fix prefer_const_constructors for common widgets
    $content = $content -replace '(\s+)SizedBox\(', '$1const SizedBox('
    $content = $content -replace '(\s+)Divider\(', '$1const Divider('
    $content = $content -replace '(\s+)Spacer\(', '$1const Spacer('
    $content = $content -replace '(\s+)EdgeInsets\.', '$1const EdgeInsets.'
    
    # Fix prefer_single_quotes
    $content = $content -creplace '([^\w])"([^"]*)"', '$1''$2'''
    
    # Only write if content changed
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $changesCount++
        Write-Host "✓ Fixed: $($file.Name)" -ForegroundColor Green
    }
}

Write-Progress -Activity "Processing files" -Completed

Write-Host "`nCompleted!" -ForegroundColor Green
Write-Host "Modified $changesCount files" -ForegroundColor Cyan
Write-Host "`nRunning flutter analyze to verify..." -ForegroundColor Yellow

flutter analyze

Write-Host "`nDone! Check the output above for remaining issues." -ForegroundColor Green
