class AppInfo {
  static const String appName = 'FinIMoi';
  static const String packageName = 'com.finimoi.app';
  static const String version = '1.0.0';
  static const int buildNumber = 1;

  // App Store / Play Store
  static const String appStoreUrl = 'https://apps.apple.com/app/finimoi';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.finimoi.app';

  // Support
  static const String supportEmail = 'support@finimoi.com';
  static const String websiteUrl = 'https://finimoi.com';
  static const String privacyPolicyUrl = 'https://finimoi.com/privacy';
  static const String termsOfServiceUrl = 'https://finimoi.com/terms';

  // Social Media
  static const String facebookUrl = 'https://facebook.com/finimoi';
  static const String twitterUrl = 'https://twitter.com/finimoi';
  static const String instagramUrl = 'https://instagram.com/finimoi';
  static const String linkedinUrl = 'https://linkedin.com/company/finimoi';

  // Development
  static const bool isDebugMode = true; // Will be false in production
  static const String apiBaseUrl = 'https://api.finimoi.com/v1';
  static const String apiBaseUrlDev = 'https://dev-api.finimoi.com/v1';

  // Features flags
  static const bool enableBiometricAuth = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
}
