# Airline Booking System - Flutter App

This is the mobile frontend for the Airline Booking System. It allows passengers to search flights, book tickets, check in, view boarding passes, and receive flight updates via a dedicated notification center. Staff members can manage flights, create new ones, and monitor operational status.

## Prerequisites

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** (for Android Emulator) or **VS Code**.
- **Running Backend**: The FastAPI backend must be running before starting the app.

## 🚀 Key Step: Connection Configuration

**Before running the app**, you must tell it where the Backend API is located.

1. Open `lib/core/config.dart`.
2. Choose the correct `baseUrl` for your testing environment:

### option A: Android Emulator (Default)
If you are running the app on the standard Android Emulator on the same computer:
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

### Option B: Physical Device (Real Phone)
If you are running the app on a real phone connected via USB or Wi-Fi:
1. Ensure your Phone and Computer are on the **SAME Wi-Fi network**.
2. Find your Computer's IP Address:
   - **Windows**: Open terminal, type `ipconfig`. Look for "IPv4 Address" (e.g., `192.168.1.15`).
   - **Mac/Linux**: Open terminal, type `ifconfig`.
3. Update `config.dart`:
```dart
static const String baseUrl = 'http://192.168.1.15:8000'; // Replace with YOUR IP
```
4. **IMPORTANT**: When running the backend, use `host 0.0.0.0`:
   ```bash
   python -m uvicorn main:app --reload --host 0.0.0.0
   ```

### Option C: iOS Simulator
```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

## How to Run

1. **Install Dependencies**:
   Open a terminal in the `flutter_app_1` folder run:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   - Ensure your device (Emulator or Phone) is connected and recognized (`flutter devices`).
   - Run:
   ```bash
   flutter run
   ```

## Troubleshooting

- **"Connection Refused"**: This usually means the IP address in `config.dart` is wrong, or the backend is not running.
- **"Network Error"**: Check if your firewall is blocking port 8000.
- **White Screen**: Wait a moment, the app might be fetching initial data. Check the terminal for error logs.
