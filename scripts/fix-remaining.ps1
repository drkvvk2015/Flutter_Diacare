# Comprehensive Dart Linter Fix Script
# Fixes remaining ~1100 style issues

$ErrorActionPreference = "Stop"

Write-Host "=== Phase 1: Fix Unused Variables & Imports ===" -ForegroundColor Cyan

# Remove unused imports
$removeUnusedImports = @(
    @{ file = "test\services\health_service_test.dart"; line = 3; pattern = "import 'package:health/health.dart';" },
    @{ file = "test\services\health_service_test.dart"; line = 4; pattern = "import 'package:mockito/annotations.dart';" }
)

foreach ($item in $removeUnusedImports) {
    $path = Join-Path $PWD $item.file
    $content = Get-Content $path -Raw
    $content = $content -replace [regex]::Escape($item.pattern) + "\s*\n", ""
    Set-Content $path $content -NoNewline
    Write-Host "Removed unused import from $($item.file)" -ForegroundColor Green
}

# Comment out unused variables
$unusedVars = @(
    @{ file = "test\repositories\user_repository_test.dart"; line = 15; var = "userRepository" },
    @{ file = "test\services\health_service_test.dart"; line = 29; var = "newSteps" },
    @{ file = "test\services\security_service_test.dart"; line = 40; var = "enabled" },
    @{ file = "test\services\security_service_test.dart"; line = 78; var = "value" },
    @{ file = "test\services\security_service_test.dart"; line = 87; var = "expectedValue" }
)

foreach ($item in $unusedVars) {
    $path = Join-Path $PWD $item.file
    $content = Get-Content $path
    $content[$item.line - 1] = "    // " + $content[$item.line - 1].TrimStart()
    Set-Content $path ($content -join "`n")
    Write-Host "Commented unused variable in $($item.file)" -ForegroundColor Green
}

Write-Host "`n=== Phase 2: Fix TODO Comments ===" -ForegroundColor Cyan

$dartFiles = Get-ChildItem -Path "test" -Filter "*.dart" -Recurse -File |
    Where-Object { $_.FullName -notlike "*\.vs\*" }

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $original = $content
    
    # Fix TODO format: TODO: -> TODO(username):
    $content = $content -replace '//\s*TODO:\s*([^\n]+)', '// TODO(developer): $1'
    $content = $content -replace '//\s*TODO\s+([^\n]+)', '// TODO(developer): $1'
    
    if ($content -ne $original) {
        Set-Content $file.FullName $content -NoNewline
        Write-Host "Fixed TODO style in $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n=== Phase 3: Fix Dangling Library Doc Comments ===" -ForegroundColor Cyan

$danglingDocs = Get-ChildItem -Path "lib","test" -Filter "*.dart" -Recurse -File |
    Where-Object { $_.FullName -notlike "*\.vs\*" }

foreach ($file in $danglingDocs) {
    $content = Get-Content $file.FullName -Raw
    if ($content -match '^///[^\n]*\n///[^\n]*\n\n(?!library\s)') {
        $content = $content -replace '^(///[^\n]*(?:\n///[^\n]*)*)\n\n', '$1\nlibrary;\n\n'
        Set-Content $file.FullName $content -NoNewline
        Write-Host "Fixed dangling doc in $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n=== Phase 4: Add Trailing Commas ===" -ForegroundColor Cyan

$dartFiles = Get-ChildItem -Path "lib","test" -Filter "*.dart" -Recurse -File |
    Where-Object { $_.FullName -notlike "*\.vs\*" }

foreach ($file in $dartFiles) {
    $lines = Get-Content $file.FullName
    $modified = $false
    
    for ($i = 0; $i -lt $lines.Count - 1; $i++) {
        # Add trailing comma if line ends with ) and next line is }
        if ($lines[$i] -match '\S\)$' -and $lines[$i+1] -match '^\s*[\)\]\}]') {
            if ($lines[$i] -notmatch ',\)$') {
                $lines[$i] = $lines[$i] -replace '\)$', ',)'
                $modified = $true
            }
        }
    }
    
    if ($modified) {
        Set-Content $file.FullName ($lines -join "`n")  -NoNewline
        Write-Host "Added trailing commas to $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n=== Complete! Running flutter analyze... ===" -ForegroundColor Cyan
flutter analyze
