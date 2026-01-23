# Fix Type Casting Errors
# Adds proper type casts for dynamic values

Write-Host "Fixing type casting errors..." -ForegroundColor Cyan

$files = @(
    "lib\features\telemedicine\appointment_model.dart",
    "lib\features\telemedicine\call_history_model.dart",
    "lib\providers\appointment_provider.dart",
    "lib\providers\user_provider.dart",
    "lib\features\auth\login_screen.dart"
)

# Fix appointment_model.dart - cast_nullable_to_non_nullable was removed by dart fix
$file = "lib\features\telemedicine\appointment_model.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "callId: json\['callId'\]", "callId: json['callId'] as String"
    $content = $content -replace "doctorId: json\['doctorId'\]", "doctorId: json['doctorId'] as String"
    $content = $content -replace "patientId: json\['patientId'\]", "patientId: json['patientId'] as String"
    $content = $content -replace "status: json\['status'\](?!.*as)", "status: json['status'] as String?"
    $content | Set-Content $file -NoNewline
    Write-Host "  Fixed $file"
}

# Fix call_history_model.dart
$file = "lib\features\telemedicine\call_history_model.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "doctorId: json\['doctorId'\](?!.*as)", "doctorId: json['doctorId'] as String"
    $content = $content -replace "patientId: json\['patientId'\](?!.*as)", "patientId: json['patientId'] as String"
    $content = $content -replace "status: json\['status'\](?!.*as String)", "status: json['status'] as String?"
    $content | Set-Content $file -NoNewline
    Write-Host "  Fixed $file"
}

# Fix user_provider.dart - return types
$file = "lib\providers\user_provider.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace "return _user\?\.displayName;", "return _user?.displayName as String? ?? '';"
    $content = $content -replace "return _user\?\.email \?\? '';", "return (_user?.email as String?) ?? '';"
    $content = $content -replace "return _user\?\.photoURL;", "return (_user?.photoURL as String?) ?? '';"
    $content | Set-Content $file -NoNewline
    Write-Host "  Fixed $file"
}

# Fix error_boundary.dart - missing method
$file = "lib\core\error_boundary.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    if ($content -notmatch "void _resetError") {
        # Find the line with onPressed: _resetError and add method before the build method
        $content = $content -replace "(\s+@override\s+Widget build)", "`r`n  void _resetError() {`r`n    setState(() {`r`n      _hasError = false;`r`n      _errorDetails = null;`r`n    });`r`n  }`r`n`$1"
        $content | Set-Content $file -NoNewline
        Write-Host "  Fixed $file - added _resetError method"
    }
}

Write-Host "`nRunning flutter analyze..." -ForegroundColor Yellow
flutter analyze 2>&1 | Select-String -Pattern "issues? found|error -" | Select-Object -First 5
