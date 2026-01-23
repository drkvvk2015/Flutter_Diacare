# Flutter Code Cleanup Script
$ErrorActionPreference = "Stop"

Write-Host "Starting code cleanup..." -ForegroundColor Cyan

$dartFiles = Get-ChildItem -Path "lib","test" -Filter "*.dart" -Recurse -File |
    Where-Object { $_.FullName -notlike "*\.vs\*" -and $_.FullName -notlike "*\build\*" }

$count = 0
$i = 0

foreach ($file in $dartFiles) {
    $i++
    Write-Progress -Activity "Processing" -Status "$i" -PercentComplete (($i/$dartFiles.Count)*100)
    
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrEmpty($content)) { continue }
    
    $original = $content
    
    $content = $content -replace '(\W)Future\.delayed\(', '$1Future<void>.delayed('
    $content = $content -replace '(\W)MaterialPageRoute\(', '$1MaterialPageRoute<void>('
    $content = $content -replace '(\W)showDialog\(', '$1showDialog<void>('
    $content = $content -replace '(\W)showModalBottomSheet\(', '$1showModalBottomSheet<void>('
    $content = $content -replace '(\W)openBox\(', '$1openBox<dynamic>('
    $content = $content -replace '(\W)Divider\(\)', '$1const Divider()'
    $content = $content -replace '(\W)Spacer\(\)', '$1const Spacer()'
    $content = $content -replace '(\d+)\.0\b', '$1'
    
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $count++
    }
}

Write-Progress -Activity "Processing" -Completed
Write-Host "Modified $count files" -ForegroundColor Green
Write-Host "Running flutter analyze..." -ForegroundColor Cyan
flutter analyze
