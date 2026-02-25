# SeedVest Mobile Release Checklist

## Versioning Rule
- Use `version: MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`.
- For every app update:
  - Increase `PATCH` for normal fixes/features.
  - Increase `BUILD` every single release upload.

Example:
- `1.0.1+2` -> next release `1.0.2+3`

## 1. Pre-release
1. Confirm API URL in `.env` is correct for target environment.
2. Run checks:
   - `dart analyze`
   - `flutter test` (if tests exist)
3. Update `pubspec.yaml` version.

## 2. Build
### APK (manual distribution)
```powershell
flutter build apk --release
```
Output:
- `build/app/outputs/flutter-apk/app-release.apk`

### AAB (Play Store)
```powershell
flutter build appbundle --release
```
Output:
- `build/app/outputs/bundle/release/app-release.aab`

## 3. Distribute
### Manual APK update
1. Share `app-release.apk` (WhatsApp/Drive/Email/etc.).
2. User installs same package signed by same key.
3. Android will show **Update** instead of **Install**.

### Play Store update
1. Upload `.aab` to Play Console.
2. Add release notes.
3. Roll out to Internal/Closed/Production track.

## 4. Post-release validation
1. Install/update on at least one real device.
2. Test:
   - login
   - contributions
   - approvals (admin)
   - biometric login
3. Verify backend connectivity and timeouts.
