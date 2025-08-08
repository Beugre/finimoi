class AppConstants {
  // App Info
  static const String appName = 'FinIMoi';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.finimoi.com';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String transactionsCollection = 'transactions';
  static const String tontinesCollection = 'tontines';
  static const String creditsCollection = 'credits';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';
  static const String cardsCollection = 'cards';
  static const String savingsCollection = 'savings';
  static const String merchantsCollection = 'merchants';
  static const String paymentsCollection = 'payments';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String documentsPath = 'documents';
  static const String receiptsPath = 'receipts';

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration quickAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int otpLength = 6;
  static const Duration otpValidityDuration = Duration(minutes: 5);

  // Monetary
  static const double minTransferAmount = 1.0;
  static const double maxTransferAmount = 1000000.0;
  static const double minRechargeAmount = 5.0;
  static const double maxRechargeAmount = 500000.0;

  // Biometric Auth
  static const String biometricStorageKey = 'biometric_enabled';
  static const String pinStorageKey = 'user_pin';

  // Credit Score
  static const int maxCreditScore = 850;
  static const int minCreditScore = 300;

  // Tontine
  static const int minTontineMembers = 2;
  static const int maxTontineMembers = 50;
  static const Duration tontineReminderFrequency = Duration(days: 1);

  // Gamification
  static const int dailyLoginPoints = 10;
  static const int transactionPoints = 5;
  static const int referralPoints = 100;
  static const int completedChallengePoints = 50;

  // Cache
  static const Duration cacheValidityDuration = Duration(hours: 1);
  static const Duration profileCacheValidityDuration = Duration(minutes: 30);

  // Network
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;

  // File Upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx'];
}
