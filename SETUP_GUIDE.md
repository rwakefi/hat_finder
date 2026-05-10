# Desktop Setup Guide for Hat Finder

This guide will help you set up your development environment on your desktop machine so you can continue building the Hat Finder app.

## 1. Install a Code Editor
You will need an editor to write code.
* **Recommended**: **Cursor** (The AI code editor you are likely using now) or **VS Code**.
* Download and install it on your desktop.

## 2. Install Flutter SDK
Flutter is the framework we are using to build the app.
1. Download the Flutter SDK for your OS (Windows or macOS) from the [official Flutter website](https://docs.flutter.dev/get-started/install).
2. Extract the file to a folder on your computer (e.g., `C:\development\flutter` on Windows or `~/development/flutter` on Mac).
3. **Add Flutter to your PATH**: This allows you to run `flutter` commands in the terminal.
   * **Windows**: Search for "Environment Variables" in Windows search, edit the `Path` variable, and add the path to `flutter\bin`.
   * **Mac**: Add `export PATH="$PATH:$HOME/development/flutter/bin"` to your `~/.zshrc` file.

## 3. Platform Setup (Where you want to run the app)

### For Web (Chrome) - Works on Windows and Mac
* Just make sure you have **Google Chrome** installed. Flutter supports web out of the box.

### For iOS (iPhone) - ⚠️ ONLY Works on Mac
If your desktop is a Windows PC, you cannot build or run the app for iOS. If it is a Mac:
1. Install **Xcode** from the Mac App Store.
2. Open Xcode once to accept the license agreement.
3. Install **CocoaPods** (for managing iOS plugins):
   * Run: `/opt/homebrew/bin/brew install cocoapods` (or use the terminal command recommended by Flutter).

### For Android - Works on Windows and Mac
1. Download and install **Android Studio**.
2. Open Android Studio and follow the setup wizard to install the **Android SDK**.
3. To run an Android emulator, create one in the "Device Manager" inside Android Studio.

## 4. Verify Setup
Open a terminal/command prompt and run:
```bash
flutter doctor
```
This command will tell you if anything is missing and how to fix it.

## 5. Get the Code
1. Copy your project folder (`hat_finder`) to your desktop machine.
2. Open the project folder in your code editor.
3. Open a terminal in that folder and run:
   ```bash
   flutter pub get
   ```
   This downloads all the packages the app needs.

## 6. Run the App
Run the app using the command line:
* For Chrome: `flutter run -d chrome`
* For iOS Simulator (Mac only): `flutter run -d ios`
