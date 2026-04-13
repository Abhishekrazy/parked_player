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
  final bool preferDesktopMode;

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
    this.preferDesktopMode = false,
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
      'preferDesktopMode': preferDesktopMode,
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
      preferDesktopMode: json['preferDesktopMode'] ?? false,
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
      
      // Ensure system sites are present (migration/restoration)
      _ensureSystemSites();
    } else {
      _initializeDefaultSites();
    }
    notifyListeners();
  }

  void _ensureSystemSites() {
    final systemIds = ['incognito', 'bookmarks', 'custom_url', 'settings'];
    bool changed = false;
    
    for (final id in systemIds) {
      if (!_sites.any((s) => s.id == id)) {
        // Find where to insert it based on original order
        final systemSite = _getSystemSite(id);
        if (systemSite != null) {
          // Add to start for now
          _sites.insert(0, systemSite);
          changed = true;
        }
      }
    }
    
    if (changed) {
      _saveSites();
    }
  }

  SiteItem? _getSystemSite(String id) {
     switch (id) {
       case 'incognito':
         return SiteItem(id: 'incognito', name: 'Incognito', url: 'TOGGLE_INCOGNITO', iconCode: Icons.privacy_tip.codePoint, colorValue: 0xFFF44336, isSystem: true);
       case 'bookmarks':
         return SiteItem(id: 'bookmarks', name: 'Saved', url: 'BOOKMARKS_PAGE', iconCode: Icons.bookmarks.codePoint, colorValue: 0xFF4CAF50, isSystem: true);
       case 'custom_url':
         return SiteItem(id: 'custom_url', name: 'Custom URL', url: 'CUSTOM_URL', iconCode: Icons.link.codePoint, colorValue: 0xFF2196F3, isSystem: true);
       case 'settings':
         return SiteItem(id: 'settings', name: 'Settings', url: 'SETTINGS_PAGE', iconCode: Icons.settings.codePoint, colorValue: 0xFF9E9E9E, isSystem: true);
       default:
         return null;
     }
  }

  void _initializeDefaultSites() {
    _sites = [
      _getSystemSite('incognito')!,
      _getSystemSite('bookmarks')!,
      _getSystemSite('custom_url')!,
      _getSystemSite('settings')!,
    ];
    _saveSites();
  }

  Future<void> addSite(String name, String url, {bool preferDesktopMode = false}) async {
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
      preferDesktopMode: preferDesktopMode,
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

  Future<void> editSite(String id, String newName, String newUrl, {bool preferDesktopMode = false}) async {
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
        preferDesktopMode: preferDesktopMode,
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
