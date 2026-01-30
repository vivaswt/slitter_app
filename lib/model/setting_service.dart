import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _notionApiKey = 'notion_api_key';

  // --- Singleton Pattern ---
  SettingsService._();
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  // -------------------------

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> setNotionApiKey(String path) async {
    final prefs = await _prefsInstance;
    await prefs.setString(_notionApiKey, path);
  }

  Future<String> getNotionApiKey() async {
    final prefs = await _prefsInstance;
    return prefs.getString(_notionApiKey) ?? '';
  }
}
