import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  static const _darkModeKey = 'app.darkMode';

  Future<bool> loadDarkMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_darkModeKey) ?? false;
  }

  Future<void> saveDarkMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, enabled);
  }
}
