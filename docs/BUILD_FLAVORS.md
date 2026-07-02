# Flutter Flavors - Build Commands

## Development

### Debug
```bash
flutter run --flavor development --target lib/main_development.dart
```

### Release
```bash
flutter build apk --flavor development --target lib/main_development.dart --release
flutter build appbundle --flavor development --target lib/main_development.dart --release
```

---

## Staging

### Debug
```bash
flutter run --flavor staging --target lib/main_staging.dart
```

### Release
```bash
flutter build apk --flavor staging --target lib/main_staging.dart --release
flutter build appbundle --flavor staging --target lib/main_staging.dart --release
```

---

## Production

### Debug
```bash
flutter run --flavor production --target lib/main_production.dart
```

### Release
```bash
flutter build apk --flavor production --target lib/main_production.dart --release
flutter build appbundle --flavor production --target lib/main_production.dart --release
flutter build ipa --flavor production --target lib/main_production.dart --release
```

---

## iOS

### Development
```bash
flutter build ios --flavor development --target lib/main_development.dart --release
```

### Staging
```bash
flutter build ios --flavor staging --target lib/main_staging.dart --release
```

### Production
```bash
flutter build ios --flavor production --target lib/main_production.dart --release
```

---

## Quick Commands

### Run on device/simulator
```bash
# Dev
flutter run --flavor development -t lib/main_development.dart

# Staging
flutter run --flavor staging -t lib/main_staging.dart

# Prod
flutter run --flavor production -t lib/main_production.dart
```

### Check which flavor is running
- Dev: Shows "Reflex Journey DEV" as app name, debug banner visible
- Staging: Shows "Reflex Journey STAGING" as app name, no debug banner
- Prod: Shows "Reflex Journey" as app name, no debug banner

### Different Bundle IDs
- Dev: `de.reflexjourney.app.dev`
- Staging: `de.reflexjourney.app.staging`
- Prod: `de.reflexjourney.app`

This allows installing all 3 versions side-by-side on the same device!
