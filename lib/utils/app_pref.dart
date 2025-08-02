import 'package:shared_preferences/shared_preferences.dart';

class AppPreference {
  static const String token = 'token';
  static late SharedPreferences _preferences;

  static Future<String> getToken() {
    return getString(token);
  }

  static Future<String> getString(String key) async {
    try {
      String value = _preferences.getString(key)!;
      return value;
    } catch (_) {}
    return '';
  }

  ///
  static Future<void> setToken(String value) async {
    await setString(token, value);
  }
  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  static Future<void> clear() async {
    await _preferences.clear();
  }
}