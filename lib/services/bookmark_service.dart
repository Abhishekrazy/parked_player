
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService extends ChangeNotifier {
  List<Map<String, String>> _bookmarks = [];

  List<Map<String, String>> get bookmarks => _bookmarks;

  BookmarkService() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? bookmarksJson = prefs.getString('bookmarks');
    if (bookmarksJson != null) {
      final List<dynamic> decoded = jsonDecode(bookmarksJson);
      _bookmarks = decoded.map((e) => Map<String, String>.from(e)).toList();
      notifyListeners();
    }
  }

  Future<void> addBookmark(String title, String url) async {
    // Check for duplicates
    if (_bookmarks.any((element) => element['url'] == url)) return;

    _bookmarks.add({'title': title, 'url': url});
    _saveBookmarks();
    notifyListeners();
  }

  Future<void> removeBookmark(String url) async {
    _bookmarks.removeWhere((element) => element['url'] == url);
    _saveBookmarks();
    notifyListeners();
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookmarks', jsonEncode(_bookmarks));
  }
  
  bool isBookmarked(String url) {
    return _bookmarks.any((element) => element['url'] == url);
  }
}
