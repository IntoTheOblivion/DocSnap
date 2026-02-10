# How to Run DocSnap PDF Scanner

## 1. Prerequisites
Ensure you have Flutter installed and in your PATH. 
If not, download it from [flutter.dev](https://flutter.dev/docs/get-started/install).

## 2. Initialize the Project
Since the project files were created manually, you need to fetch the dependencies and generate the code.

Open a terminal in this folder (`c:/Users/gabri/Desktop/app_pdf`) and run:

```bash
# 1. Get dependencies
flutter pub get

# 2. Generate code (Riverpod providers)
flutter pub run build_runner build --delete-conflicting-outputs
```

## 3. Run the App
Connect your iOS Simulator or Android Emulator/Device and run:

```bash
flutter run
```

## Troubleshooting
- **"Termine 'flutter' non riconosciuto"**: This means Flutter is not in your system PATH. Find where your Flutter SDK is installed (e.g., `C:\flutter\bin`) and add it to your Environment Variables, or run the commands using the full path (e.g., `C:\flutter\bin\flutter pub get`).
- **Missing Files**: Steps above will generate `.g.dart` files which are required for the code to compile. Do not skip step 2.
