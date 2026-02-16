import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryItem {
  final String url;
  final String title;
  final DateTime timestamp;

  HistoryItem({
    required this.url,
    required this.title,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        url: json['url'],
        title: json['title'],
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class HistoryService extends ChangeNotifier {
  static const String _keyHistory = 'browser_history';
  List<HistoryItem> _history = [];

  List<HistoryItem> get history => List.unmodifiable(_history);

  HistoryService() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_keyHistory) ?? [];
    
    _history = historyJson
        .map((e) => HistoryItem.fromJson(jsonDecode(e)))
        .toList()
        .reversed // Should store chronologically, but maybe we want display reverse chron
        .toList(); // Actually let's store newest first in memory for simplicity of viewing
        
    // Wait, easiest is probably to store NEWEST first always.
    _history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
  }

  Future<void> addToHistory(String url, String title) async {
    // Avoid duplicates if same URL visited recently? 
    // Usually browser history keeps all visits or updates timestamp.
    // Let's remove existing entry for same URL if it exists to update timestamp to top
    final now = DateTime.now();
    
    _history.removeWhere((item) => item.url == url && item.timestamp.day == now.day); 
    // Simple logic: if visited today, update time. If older, keep record? 
    // Actually most browsers keep every visit or update recent one.
    // Creating a clean history: Remove exact URL duplicate to push to top
    _history.removeWhere((item) => item.url == url);

    _history.insert(0, HistoryItem(url: url, title: title, timestamp: now));
    
    // Limit history size? Maybe 1000 items?
    if (_history.length > 500) {
      _history = _history.sublist(0, 500);
    }
    
    notifyListeners();
    _saveHistory();
  }

  Future<void> clearHistory() async {
    _history.clear();
    notifyListeners();
    _saveHistory();
  }

  Future<void> clearHistorySince(Duration duration) async {
    if (duration == Duration.zero) {
        // "All time" case if passed as zero, or just use clearHistory
        await clearHistory();
        return;
    }
    
    if (duration.inDays > 365) {
        // "Forever" / All time
        await clearHistory();
        return;
    }

    final cutoff = DateTime.now().subtract(duration);
    _history.removeWhere((item) => item.timestamp.isAfter(cutoff));
    
    notifyListeners();
    _saveHistory();
  }

  Future<void> removeCheck(String url) async {
      _history.removeWhere((item) => item.url == url);
      notifyListeners();
      _saveHistory();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_keyHistory, historyJson);
  }
}
