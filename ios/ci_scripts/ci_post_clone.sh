#!/bin/sh

# Xcode Cloud uses a fresh macOS worker for each build. Install Flutter,
# generate Flutter's iOS settings, and prepare iOS dependencies before xcodebuild.
set -eu

echo "Hat Finder Xcode Cloud post-clone setup"

REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$REPO_ROOT"

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter}"

if [ ! -x "$FLUTTER_ROOT/bin/flutter" ]; then
  echo "Installing Flutter channel: $FLUTTER_CHANNEL"
  rm -rf "$FLUTTER_ROOT"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_CHANNEL" "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version
flutter precache --ios
flutter pub get

if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  echo "Applying Xcode Cloud build number: $CI_BUILD_NUMBER"
  if [ ! -f ios/Flutter/Generated.xcconfig ]; then
    echo "Expected ios/Flutter/Generated.xcconfig after flutter pub get." >&2
    exit 1
  fi
  /usr/bin/sed -i '' "s/^FLUTTER_BUILD_NUMBER=.*/FLUTTER_BUILD_NUMBER=$CI_BUILD_NUMBER/" ios/Flutter/Generated.xcconfig
fi

if [ "${RUN_FLUTTER_TESTS:-0}" = "1" ]; then
  flutter analyze
  flutter test
fi

if command -v brew >/dev/null 2>&1; then
  export HOMEBREW_NO_AUTO_UPDATE=1
  brew list cocoapods >/dev/null 2>&1 || brew install cocoapods
elif ! command -v pod >/dev/null 2>&1; then
  echo "CocoaPods is required, but neither brew nor pod is available." >&2
  exit 1
fi

cd ios
pod install

