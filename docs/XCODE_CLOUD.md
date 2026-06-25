# Xcode Cloud setup

Hat Finder is a Flutter app with an iOS shell in `ios/Runner.xcworkspace`.
Xcode Cloud can own the archive/upload path so releases do not depend on a
particular developer Mac, Xcode install, unlocked keychain, or App Store upload
credential state.

## Repository support

The repo includes `ios/ci_scripts/ci_post_clone.sh`. Xcode Cloud runs this script
after cloning the repository. It:

- Clones the Flutter SDK from the configured channel.
- Runs `flutter precache --ios` and `flutter pub get`.
- Applies Xcode Cloud's `CI_BUILD_NUMBER` to Flutter's generated iOS settings.
- Optionally runs `flutter analyze` and `flutter test` when
  `RUN_FLUTTER_TESTS=1` is set in the workflow environment.
- Installs CocoaPods through Homebrew when needed and runs `pod install`.

References:

- Apple custom build scripts:
  https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
- Flutter Xcode Cloud guidance:
  https://docs.flutter.dev/deployment/cd#xcode-cloud

## Recommended workflow

Create the workflow from Xcode or App Store Connect:

1. Product or app: Hat Finder.
2. Repository: `rwakefi/hat_finder`.
3. Branch: `main`.
4. Workspace: `ios/Runner.xcworkspace`.
5. Scheme: `Runner`.
6. Platform/action: Archive for iOS only.
7. Distribution: TestFlight first. Do not auto-submit App Review until one
   cloud build has been manually verified.
8. Xcode version: latest App Store-accepted release or release candidate, not a
   beta unless Apple explicitly allows beta SDK submissions for that period.
9. Next Build Number: set to `23` after the `1.0.1 (22)` App Store submission.

Useful workflow environment variables:

- `FLUTTER_CHANNEL=stable`
- `RUN_FLUTTER_TESTS=1` when we want Cloud to fail on Dart analysis/tests before
  archiving.

## Build number notes

Flutter reads the iOS build number from `FLUTTER_BUILD_NUMBER`, normally
generated from `pubspec.yaml`. Xcode Cloud has its own build counter. The
post-clone script patches `ios/Flutter/Generated.xcconfig` with
`CI_BUILD_NUMBER` so Cloud builds do not repeatedly upload the same
`pubspec.yaml` build number.

If App Store Connect reports a duplicate build number, increase the workflow's
Next Build Number above the highest build already visible in App Store Connect.

## Local export note

`ios/ExportOptions.plist` sets `manageAppVersionAndBuildNumber` to `false`.
This avoids the local Xcode export pipeline silently changing the build number
during upload, which happened when `1.0.1 (21)` was exported locally as
`1.0.1 (22)`.

