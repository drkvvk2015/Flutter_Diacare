# Deprecated Files - To Be Removed

This document lists duplicate and deprecated files that should be removed in the next cleanup cycle.

## Duplicate Appointment Screens

### Issue
Two identical appointment screen files exist:
- `lib/screens/appointment_screen.dart` (837 lines) - **ACTIVE**
- `lib/screens/appointment_screen_fixed.dart` (607 lines) - **DEPRECATED**

### Analysis
- Both files export the same `AppointmentScreen` class
- `appointment_screen.dart` is actively imported in:
  - router.dart
  - dashboard_screen.dart
  - admin_dashboard_screen.dart
  - quick_book_appointment_screen.dart
- `appointment_screen_fixed.dart` is NOT imported anywhere

### Recommendation
**DELETE**: `lib/screens/appointment_screen_fixed.dart`

**Command**:
```bash
rm lib/screens/appointment_screen_fixed.dart
```

---

## Duplicate Patient Login Screens

### Issue
Two identical patient login screen files exist:
- `lib/screens/patient_login_screen.dart` (540 lines) - **ACTIVE**
- `lib/screens/premium_patient_login_screen.dart` (540 lines) - **DUPLICATE**

### Analysis
- Both files are byte-for-byte identical
- `patient_login_screen.dart` is imported in:
  - login_selection_screen.dart
- `premium_patient_login_screen.dart` is NOT imported anywhere

### Recommendation
**DELETE**: `lib/screens/premium_patient_login_screen.dart`

**Command**:
```bash
rm lib/screens/premium_patient_login_screen.dart
```

---

## Cleanup Script

Run the following commands to remove deprecated files:

```powershell
# From Flutter_Diacare directory
Remove-Item "lib\screens\appointment_screen_fixed.dart" -Force
Remove-Item "lib\screens\premium_patient_login_screen.dart" -Force
```

Or on Unix/Mac:

```bash
cd Flutter_Diacare
rm lib/screens/appointment_screen_fixed.dart
rm lib/screens/premium_patient_login_screen.dart
```

---

## Post-Cleanup Verification

After removing files, verify the app still builds:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

---

## Additional Cleanup Recommendations

### Build Artifacts (Already in .gitignore)
The following directories contain ~30+ build artifacts but are properly ignored:
- `build/` directory and all subdirectories
- Consider running `flutter clean` periodically

### Test Cache
- `test_cache/` directory exists but is now in .gitignore
- Can be safely deleted: `rm -rf test_cache/`

### Unit Test Assets
- `unit_test_assets/` directory exists but is now in .gitignore  
- Can be safely deleted: `rm -rf unit_test_assets/`

---

## Summary

| File | Status | Action | Impact |
|------|--------|--------|--------|
| appointment_screen_fixed.dart | Unused | DELETE | None - not imported |
| premium_patient_login_screen.dart | Duplicate | DELETE | None - not imported |
| test_cache/ | Build artifact | DELETE | None - in .gitignore |
| unit_test_assets/ | Build artifact | DELETE | None - in .gitignore |

**Last Updated**: {{ DATE }}
