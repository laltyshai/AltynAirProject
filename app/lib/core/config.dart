class AppConfig {
  // ---------------------------------------------------------------------------
  // CONFIGURATION: Select your environment
  // ---------------------------------------------------------------------------
  
  // OPTION 1: Android Emulator (Standard)
  // Use this if you are running on the Android Emulator on the same machine.
  static const String baseUrl = 'http://10.0.2.2:8000';

  // OPTION 2: iOS Simulator / Localhost Web
  // Use this for iOS Simulator or if running Web.
  // static const String baseUrl = 'http://127.0.0.1:8000';

  // OPTION 3: Physical Device (Real Phone)
  // 1. Connect phone to same Wi-Fi as PC.
  // 2. Get PC's IP address (e.g., ipconfig on Windows -> IPv4 Address).
  // 3. Replace the IP below with your PC's IP.
  // static const String baseUrl = 'http://192.168.1.X:8000';
}
