
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdBlockService extends ChangeNotifier {
  static const List<String> kDefaultBlockedDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'googleadservices.com',
    'adnxs.com',
    'rubiconproject.com',
    'criteo.com',
    'advertising.com',
    'outbrain.com',
    'taboola.com',
    'popads.net',
    'popcash.net',
  ];

  bool _isEnabled = true;
  List<String> _blockedDomains = List.from(kDefaultBlockedDomains);
  Set<String> _inactiveDomains = {};

  AdBlockService() {
    _loadSettings();
  }

  bool get isEnabled => _isEnabled;
  List<String> get blockedDomains => _blockedDomains;
  
  bool isDomainBlocked(String domain) {
    return !_inactiveDomains.contains(domain);
  }

  bool isDefaultDomain(String domain) => kDefaultBlockedDomains.contains(domain);

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('adblock_enabled') ?? true;
    final savedDomains = prefs.getStringList('blocked_domains');
    if (savedDomains != null) {
      _blockedDomains = savedDomains;
    }
    final savedInactive = prefs.getStringList('inactive_domains');
    if (savedInactive != null) {
      _inactiveDomains = savedInactive.toSet();
    }
    notifyListeners();
  }

  Future<void> toggleAdBlock(bool value) async {
    _isEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adblock_enabled', value);
    notifyListeners();
  }

  Future<void> addDomain(String domain) async {
    if (!_blockedDomains.contains(domain)) {
      _blockedDomains.add(domain);
      await _saveDomains();
      notifyListeners();
    }
  }

  Future<void> removeDomain(String domain) async {
    if (_blockedDomains.contains(domain)) {
      _blockedDomains.remove(domain);
      _inactiveDomains.remove(domain); // Clean up if it was inactive
      await _saveDomains();
      notifyListeners();
    }
  }
  
  Future<void> toggleDomainBlockedStatus(String domain, bool isBlocked) async {
    if (_blockedDomains.contains(domain)) {
      if (isBlocked) {
        _inactiveDomains.remove(domain);
      } else {
        _inactiveDomains.add(domain);
      }
      await _saveDomains();
      notifyListeners();
    }
  }

  Future<void> _saveDomains() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blocked_domains', _blockedDomains);
    await prefs.setStringList('inactive_domains', _inactiveDomains.toList());
  }

  bool shouldBlockRequest(String url) {
    if (!_isEnabled) return false;
    for (final domain in _blockedDomains) {
      // Only block if the domain is NOT in the inactive set
      if (!_inactiveDomains.contains(domain) && url.contains(domain)) {
        return true;
      }
    }
    return false;
  }

  // Basic JS to remove common ad elements
  String get adBlockJs => _isEnabled
      ? '''
      (function() {
        var style = document.createElement('style');
        style.innerHTML = 'iframe[src*="ads"], div[id*="ad-"], div[class*="ad-"], .adsbygoogle { display: none !important; }';
        document.head.appendChild(style);
      })();
    '''
      : '';
}
