# Moon Ridge Hat Finder

Flutter app for guided Moon Ridge hat recommendations backed by Shopify catalog
metadata. The current v1 direction is a fit quiz plus guided material, style,
crown, and brim selection. Camera/image analysis is intentionally deferred.

## Backend Configuration

The app defaults to the production Railway backend:

```bash
https://hatfinder-production.up.railway.app
```

For local or private review backends, pass an override at build/run time:

```bash
flutter run \
  --dart-define=HAT_FINDER_API_BASE_URL=https://your-review-backend.example.com
```

iOS TestFlight builds should use an HTTPS backend. Avoid shipping hardcoded
private IPs, localhost URLs, or broad App Transport Security exceptions.

## iOS Simulator

```bash
flutter pub get
flutter run -d ios
```

## Tests

```bash
flutter test
flutter analyze
```

Analyzer warnings are still being reduced, but tests should pass before handing
the branch to external testers.
