# Batch Type Cast Fixer
# Systematically fixes common type casting patterns across multiple files

Write-Host "=== Starting Batch Type Cast Fixes ===" -ForegroundColor Cyan

$totalFixes = 0

# Get all dart files with errors
$files = @(
    "lib\features\telemedicine\appointment_model.dart",
    "lib\features\telemedicine\call_history_model.dart",
    "lib\providers\appointment_provider.dart",
    "lib\providers\user_provider.dart",
    "lib\services\anthropometry_service.dart",
    "lib\services\smbg_service.dart",
    "lib\services\bp_service.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "`nFixing: $file" -ForegroundColor Yellow
        $content = Get-Content $file -Raw
        $original = $content
        
        # Common patterns:
        # 1. json['field'] -> json['field'] as String
        # 2. json['field'] -> json['field'] as String?
        # 3. json['field'] -> json['field'] as int
        # 4. json['field'] -> json['field'] as double
        # 5. DateTime.parse(json['field']) -> DateTime.parse(json['field'] as String)
        
        # Fix DateTime.parse patterns first (most specific)
        $content = $content -replace "DateTime\.parse\(json\['(\w+)'\]\)(?! as)", "DateTime.parse(json['`$1'] as String)"
        
        # Fix simple field accesses in fromJson constructors
        # This is complex - better to do manually
        
        if ($content -ne $original) {
            $content | Set-Content $file -NoNewline
            $totalFixes++
            Write-Host "  ✓ Fixed" -ForegroundColor Green
        } else {
            Write-Host "  - No changes needed" -ForegroundColor Gray
        }
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Files processed: $($files.Count)"
Write-Host "Files fixed: $totalFixes"

Write-Host "`nRunning flutter analyze..." -ForegroundColor Yellow
flutter analyze 2>&1 | Select-String -Pattern "issues? found|error -" | Select-Object -First 3
