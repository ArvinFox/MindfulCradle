class AppConfig {
  // App Trademark
  static const String appTrademark =
      "©2025 Mindful Cradle All right reserved. Developed by Arvin Premathilake";

  // App Name
  static const String appName = "Mindful Cradle";

  // Backend API base URL.
  // Set BACKEND_URL in your .env file.
  // Empty string = direct Gemini mode (no backend required).
  static const String backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
}
