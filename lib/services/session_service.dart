
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService extends ChangeNotifier {
  static const String _keySessionUrl = 'last_session_url';
  static const String _keySessionTitle = 'last_session_title';
  static const String _keyRestoreEnabled = 'restore_session_enabled';

  String? _lastSessionUrl;
  String? _lastSessionTitle;
  bool _isRestoreEnabled = true;
  bool _isLoaded = false;

  String? get lastSessionUrl => _lastSessionUrl;
  String? get lastSessionTitle => _lastSessionTitle;
  bool get isRestoreEnabled => _isRestoreEnabled;
  bool get isLoaded => _isLoaded;

  bool get hasSession => _lastSessionUrl != null && _lastSessionUrl!.isNotEmpty;

  SessionService() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isRestoreEnabled = prefs.getBool(_keyRestoreEnabled) ?? true;
    _lastSessionUrl = prefs.getString(_keySessionUrl);
    _lastSessionTitle = prefs.getString(_keySessionTitle);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleRestoreEnabled(bool value) async {
    _isRestoreEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRestoreEnabled, value);
    if (!value) {
      clearSession();
    }
    notifyListeners();
  }

  Future<void> saveSession(String url, String title) async {
    if (!_isRestoreEnabled) return;
    
    _lastSessionUrl = url;
    _lastSessionTitle = title;
    // Don't notify listeners on every URL change to prioritize performance
    // notifyListeners(); 

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySessionUrl, url);
    await prefs.setString(_keySessionTitle, title);
  }

  Future<void> clearSession() async {
    _lastSessionUrl = null;
    _lastSessionTitle = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionUrl);
    await prefs.remove(_keySessionTitle);
    notifyListeners();
  }
}
