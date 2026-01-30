import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_constants.dart';

class SiteItem {
  final String id;
  final String name;
  final String url;
  final String? asset;
  final String? type; // 'svg', 'image', 'icon', 'file'
  final int? colorValue;
  final int? iconCode;
  final bool isCustom;
  final bool isSystem; 

  SiteItem({
    required this.id,
    required this.name,
    required this.url,
    this.asset,
    this.type,
    this.colorValue,
    this.iconCode,
    this.isCustom = false,
    this.isSystem = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'asset': asset,
      'type': type,
      'colorValue': colorValue,
      'iconCode': iconCode,
      'isCustom': isCustom,
      'isSystem': isSystem,
    };
  }

  factory SiteItem.fromJson(Map<String, dynamic> json) {
    return SiteItem(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      asset: json['asset'],
      type: json['type'],
      colorValue: json['colorValue'],
      iconCode: json['iconCode'],
      isCustom: json['isCustom'] ?? false,
      isSystem: json['isSystem'] ?? false,
    );
  }
}

class SitesService extends ChangeNotifier {
  List<SiteItem> _sites = [];
  List<SiteItem> get sites => _sites;

  SitesService() {
    _loadSites();
  }

  Future<void> _loadSites() async {
    final prefs = await SharedPreferences.getInstance();
    final sitesString = prefs.getString('sites_list');
    
    if (sitesString != null) {
      final List<dynamic> decoded = jsonDecode(sitesString);
      _sites = decoded.map((e) => SiteItem.fromJson(e)).toList();
    } else {
      _initializeDefaultSites();
    }
    notifyListeners();
  }

  void _initializeDefaultSites() {
    _sites = [
      SiteItem(
        id: 'youtube',
        name: 'YouTube',
        url: 'https://www.youtube.com',
        asset: 'assets/youtube.svg',
        type: 'svg',
        colorValue: 0xFFFF0000,
      ),
      SiteItem(
        id: 'vimeo',
        name: 'Vimeo',
        url: 'https://vimeo.com',
        asset: 'assets/vimeo.svg',
        type: 'svg',
        colorValue: 0xFF1AB7EA,
      ),
      SiteItem(
        id: '9anime',
        name: '9anime',
        url: 'https://9animetv.to',
        asset: 'assets/9anime.svg',
        type: 'svg',
        colorValue: 0xFF6A1B9A,
      ),
      SiteItem(
        id: 'cineby',
        name: 'Cineby',
        url: 'https://cineby.app',
        asset: 'assets/Cineby.svg',
        type: 'svg',
        colorValue: 0xFFC62828,
      ),
      SiteItem(
        id: 'twitch',
        name: 'Twitch',
        url: 'https://www.twitch.tv',
        asset: 'assets/twitch.svg',
        type: 'svg',
        colorValue: 0xFF9146FF,
      ),
      SiteItem(
        id: 'dailymotion',
        name: 'Dailymotion',
        url: 'https://www.dailymotion.com',
        asset: 'assets/dailymotion.svg',
        type: 'svg',
        colorValue: 0xFF0066DC,
      ),
      SiteItem(
        id: 'google',
        name: 'Google',
        url: 'https://www.google.com',
        iconCode: Icons.search_rounded.codePoint,
        type: 'icon',
        colorValue: 0xFF4285F4,
      ),
      SiteItem(
        id: 'custom_url',
        name: 'Open URL',
        url: 'CUSTOM_URL',
        iconCode: Icons.link_rounded.codePoint,
        type: 'icon',
        colorValue: 0xFF00C853,
      ),
      SiteItem(
        id: 'saved_pages',
        name: 'Saved Pages',
        url: 'BOOKMARKS_PAGE',
        iconCode: Icons.bookmarks_rounded.codePoint,
        type: 'icon',
        colorValue: 0xFFFFA000,
      ),
      SiteItem(
        id: 'settings',
        name: 'Settings',
        url: 'SETTINGS_PAGE',
        iconCode: Icons.settings_rounded.codePoint,
        type: 'icon',
        colorValue: 0xFF607D8B,
        isSystem: true,
      ),
      SiteItem(
        id: 'incognito',
        name: 'Incognito',
        url: 'TOGGLE_INCOGNITO',
        iconCode: Icons.privacy_tip_outlined.codePoint,
        type: 'icon',
        colorValue: 0xFF9E9E9E, 
        isSystem: true,
      ),
    ];
    _saveSites();
  }

  Future<void> addSite(String name, String url) async {
    final domain = Uri.parse(url).host;
    // Token from user for logo.dev
    const token = AppConstants.logoDevToken;
    final logoUrl = 'https://img.logo.dev/$domain?token=$token&format=png';
    String? localPath;
    String type = 'icon'; // Default fall back

    String id = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final response = await http.get(Uri.parse(logoUrl));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/logo_$id.png';
        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);
        localPath = path;
        type = 'file';
      } else {
        debugPrint('Failed to download logo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading logo: $e');
    }

    // Find insertion index
    int settingsIndex = _sites.indexWhere((s) => s.id == 'settings');
    final targetIndex = settingsIndex != -1 ? settingsIndex : _sites.length;

    final newSite = SiteItem(
      id: id,
      name: name,
      url: url,
      type: type, 
      asset: localPath, 
      isCustom: true,
      colorValue: 0xFFFFFFFF,
      iconCode: type == 'icon' ? Icons.public.codePoint : null,
    );

    _sites.insert(targetIndex, newSite);
    await _saveSites();
    notifyListeners();
  }

  Future<void> removeSite(String id) async {
    final index = _sites.indexWhere((s) => s.id == id);
    if (index != -1) {
      final site = _sites[index];
      // Cleanup file if it exists
      if (site.type == 'file' && site.asset != null) {
        try {
          final file = File(site.asset!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting logo file: $e');
        }
      }
      _sites.removeAt(index);
      await _saveSites();
      notifyListeners();
    }
  }

  Future<void> editSite(String id, String newName, String newUrl) async {
    final index = _sites.indexWhere((s) => s.id == id);
    if (index != -1) {
      final oldSite = _sites[index];
      String? localPath = oldSite.asset;
      String type = oldSite.type ?? 'icon';
      int? iconCode = oldSite.iconCode;

      final oldDomain = Uri.parse(oldSite.url).host;
      final newDomain = Uri.parse(newUrl).host;

      if (oldDomain != newDomain) {
        // Domain changed, try to fetch new logo
        const token = AppConstants.logoDevToken;
        final logoUrl = 'https://img.logo.dev/$newDomain?token=$token&format=png';
        
        try {
          final response = await http.get(Uri.parse(logoUrl));
          if (response.statusCode == 200) {
            // Remove old logo if it exists
            if (oldSite.type == 'file' && oldSite.asset != null) {
              final oldFile = File(oldSite.asset!);
              if (await oldFile.exists()) {
                await oldFile.delete();
              }
            }

            final directory = await getApplicationDocumentsDirectory();
            final path = '${directory.path}/logo_${id}_${DateTime.now().millisecondsSinceEpoch}.png'; // Unique name
            final file = File(path);
            await file.writeAsBytes(response.bodyBytes);
            localPath = path;
            type = 'file';
            iconCode = null;
          } else {
             // Failed to download new logo
             // If manual fallback to icon is preferred
             localPath = null;
             type = 'icon';
             iconCode = Icons.public.codePoint;
          }
        } catch (e) {
             debugPrint('Error updating logo: $e');
             // Fallback to icon on error
             localPath = null;
             type = 'icon';
             iconCode = Icons.public.codePoint;
        }
      }

      _sites[index] = SiteItem(
        id: id,
        name: newName,
        url: newUrl,
        type: type,
        asset: localPath,
        colorValue: oldSite.colorValue,
        iconCode: iconCode,
        isCustom: oldSite.isCustom,
        isSystem: oldSite.isSystem,
      );

      await _saveSites();
      notifyListeners();
    }
  }

  void reorderSites(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final SiteItem item = _sites.removeAt(oldIndex);
    _sites.insert(newIndex, item);
    _saveSites();
    notifyListeners();
  }

  Future<void> _saveSites() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_sites.map((e) => e.toJson()).toList());
    await prefs.setString('sites_list', encoded);
  }
}
