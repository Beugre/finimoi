import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // First Launch
  static bool get isFirstLaunch => _prefs?.getBool(_keyFirstLaunch) ?? true;
  static Future<void> setFirstLaunchDone() async {
    await _prefs?.setBool(_keyFirstLaunch, false);
  }

  // Theme Mode
  static String get themeMode => _prefs?.getString(_keyThemeMode) ?? 'system';
  static Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(_keyThemeMode, mode);
  }

  // Language
  static String get language => _prefs?.getString(_keyLanguage) ?? 'fr';
  static Future<void> setLanguage(String languageCode) async {
    await _prefs?.setString(_keyLanguage, languageCode);
  }
}
