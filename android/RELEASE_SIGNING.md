# Android Release Signing Setup

1. Create keystore folder:
```powershell
mkdir android\keystore
```

2. Generate upload keystore:
```powershell
keytool -genkey -v -keystore android\keystore\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

3. Create `android/key.properties` from template:
```powershell
copy android\key.properties.example android\key.properties
```

4. Edit `android/key.properties` with real values:
- `storePassword`
- `keyPassword`
- `keyAlias`
- `storeFile` (default: `../keystore/upload-keystore.jks`)

5. Build release artifact:
```powershell
flutter build apk --release
```
or
```powershell
flutter build appbundle --release
```

If `android/key.properties` is missing, release currently falls back to debug signing for local testing only.
