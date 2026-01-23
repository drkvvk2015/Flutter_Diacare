# Massive Automated Flutter Lint Fix
# Handles bulk of remaining ~1500 style issues

$ErrorActionPreference = "Continue"
Write-Host "Starting massive cleanup..." -ForegroundColor Cyan

$files = Get-ChildItem -Path "lib","test" -Filter "*.dart" -Recurse -File |
    Where-Object { $_.FullName -notlike "*\.vs\*" -and $_.FullName -notlike "*\build\*" }

$totalFixed = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrEmpty($content)) { continue }
    $original = $content
    
    # Fix prefer_single_quotes - change double to single (simple cases only)
    $content = $content -creplace '= "([^"\\]*)"', "= '$1'"
    $content = $content -creplace ': "([^"\\]*)"', ": '$1'"
    $content = $content -creplace '\("([^"\\]*)"\)', "('$1')"
    $content = $content -creplace 'Text\("([^"\\]*)"\)', "Text('$1')"
    $content = $content -creplace "key: (?!r')[^\s]+", { $_.Value -replace '"', "'" }
    
    # Fix prefer_const_constructors for Text widgets
    $content = $content -replace '(\s+)Text\(', '$1const Text('
    $content = $content -replace '(\s+)Icon\(Icons\.', '$1const Icon(Icons.'
    $content = $content -replace '(\s+)SizedBox\(', '$1const SizedBox('
    $content = $content -replace '(\s+)Divider\(\)', '$1const Divider()'
    $content = $content -replace '(\s+)Spacer\(\)', '$1const Spacer()'
    
    # Fix prefer_final_locals (simple cases)
    $content = $content -creplace '(\n\s+)var (\w+) = (?:const |''|"|\d|\[|\{|true|false)', '$1final $2 = '
    
    # Fix cascade_invocations - add .. (very simple cases)
    # Skip this as it's complex and error-prone
    
    # Fix avoid_redundant_argument_values
    $content = $content -replace ', crossAxisAlignment: CrossAxisAlignment\.start,?\s*\)', ')'
    $content = $content -replace ', mainAxisAlignment: MainAxisAlignment\.start,?\s*\)', ')'
    
    # Fix use_if_null_to_convert_nulls_to_bools
    $content = $content -creplace '(\w+) == true \? true : false', '$1 ?? false'
    $content = $content -creplace '(\w+) != null \? (\w+) : false', '$1 ?? false'
    
    # Fix unawaited_futures by adding unawaited() wrapper
    $content = $content -replace '(\s+)(showDialog\()', '$1unawaited($2)'
    $content = $content -replace '(\s+)(showModalBottomSheet\()', '$1unawaited($2)'
    $content = $content -replace '(\s+)(Navigator\.push\()', '$1unawaited($2)'
    
    # Remove duplicate const keywords
    $content = $content -replace 'const const ', 'const '
    
    # Fix double literals to int (simple .0 cases)
    $content = $content -replace '(\d+)\.0([^\d])', '$1$2'
    
    if ($content -ne $original) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        $totalFixed++
    }
}

Write-Host "Fixed $totalFixed files" -ForegroundColor Green
Write-Host "Running flutter analyze..." -ForegroundColor Cyan
flutter analyze 2>&1 | Select-String "issues found"
