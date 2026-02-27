import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart'; // Unity Ads
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bookmark_service.dart';
import '../services/session_service.dart';
import '../services/history_service.dart';
import 'settings_page.dart';
import 'history_page.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final bool isIncognito;
  final bool? preferDesktopMode;

  const WebViewPage({
    super.key, required this.url,
    required this.title,
    this.isIncognito = false,
    this.preferDesktopMode,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> with SingleTickerProviderStateMixin {
  InAppWebViewController? _webViewController;
  late TextEditingController _urlController;
  late String _currentUrl;
  late String _currentTitle;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _isDesktopMode = false;
  bool _isHeaderVisible = true;
  bool _isfullscreen = false;
  final FocusNode _urlFocusNode = FocusNode();

  // Ad variables
  bool _isAdLoaded = false;
  static const String _placementId = 'Interstitial_Android'; 

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _currentTitle = widget.title;
    _urlController = TextEditingController(text: _currentUrl);
    _isDesktopMode = widget.preferDesktopMode ?? false;

    // Load ad
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    UnityAds.load(
      placementId: _placementId,
      onComplete: (placementId) {
        debugPrint('Load Complete $placementId');
        setState(() {
          _isAdLoaded = true;
        });
      },
      onFailed: (placementId, error, message) => debugPrint('Load Failed $placementId: $error $message'),
    );
  }

  Future<void> _showInterstitialAd() async {
    if (_isAdLoaded) {
      final prefs = await SharedPreferences.getInstance();
      final hasShown = prefs.getBool('has_shown_welcome_ad') ?? false;
      
      if (!hasShown) {
        UnityAds.showVideoAd(
          placementId: _placementId,
          onStart: (placementId) => debugPrint('Video Ad $placementId started'),
          onClick: (placementId) => debugPrint('Video Ad $placementId click'),
          onSkipped: (placementId) => debugPrint('Video Ad $placementId skipped'),
          onComplete: (placementId) {
            debugPrint('Video Ad $placementId completed');
            _isAdLoaded = false;
          },
          onFailed: (placementId, error, message) => debugPrint('Video Ad $placementId failed: $error $message'),
        );
        
        await prefs.setBool('has_shown_welcome_ad', true);
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _toggleDesktopMode() {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
    });
    _webViewController?.setSettings(settings: _browserSettings);
    _webViewController?.reload();
  }
  
  void _toggleFullscreenVideo() {
    if (_isfullscreen) {
      // Exit fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown, DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      // Enter fullscreen
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }
    setState(() {
      _isfullscreen = !_isfullscreen;
      _isHeaderVisible = !_isfullscreen; // Hide header in fullscreen
    });
  }

  InAppWebViewSettings get _browserSettings {
    return InAppWebViewSettings(
      isInspectable: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true,
      userAgent: _isDesktopMode ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" : null,
      preferredContentMode: _isDesktopMode ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.MOBILE,
      useHybridComposition: true,
      useShouldInterceptRequest: true,
    );
  }

  Future<void> _injectStealthAndFixes() async {
    const js = """
      // Remove ad placeholders
      document.querySelectorAll('div[id^="google_ads"], div[class*="ad-container"]').forEach(el => el.remove());
      
      // Fix specific site issues (e.g. Hotstar)
      if (window.location.hostname.includes('hotstar.com')) {
         // ... custom fixes ...
      }
    """;
    await _webViewController?.evaluateJavascript(source: js);
  }

  void _updateSession(String url, String title) {
    if (!widget.isIncognito) {
      // CORRECTED METHOD NAME: saveSession instead of updateSession
      Provider.of<SessionService>(context, listen: false).saveSession(url, title);
    }
  }

  void _loadUrl(String url) {
    if (!url.startsWith('http')) {
      url = 'https://$url';
    }
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    _urlFocusNode.unfocus();
  }

  int _scrollY = 0;

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _webViewController?.canGoBack() ?? false) {
          await _webViewController?.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  if (!isLandscape)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        height: _isHeaderVisible ? null : 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Theme.of(context).iconTheme.color),
                                onPressed: () async {
                                  if (await _webViewController?.canGoBack() ?? false) {
                                    _webViewController?.goBack();
                                  } else {
                                    if (context.mounted) Navigator.of(context).pop();
                                  }
                                },
                              ),
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    children: [
                                      if (widget.isIncognito)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 12, right: 4),
                                          child: Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.redAccent),
                                        )
                                      else if (_currentUrl.startsWith("https"))
                                        Padding(
                                          padding: const EdgeInsets.only(left: 12, right: 4),
                                          child: Icon(Icons.lock_rounded, size: 14, color: Theme.of(context).colorScheme.primary),
                                        ),
                                      Expanded(
                                        child: TextField(
                                          controller: _urlController,
                                          focusNode: _urlFocusNode,
                                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10), isDense: true,
                                          ),
                                          style: TextStyle(
                                            fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                                          keyboardType: TextInputType.url,
                                          textInputAction: TextInputAction.go,
                                          onSubmitted: _loadUrl,
                                        ),
                                      ),
                                      if (_urlFocusNode.hasFocus)
                                        IconButton(
                                          icon: const Icon(Icons.cancel, size: 16),
                                          onPressed: () {
                                            _urlController.clear();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh_rounded, color: Theme.of(context).iconTheme.color),
                                onPressed: () {
                                  _webViewController?.reload();
                                },
                              ),
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).iconTheme.color),
                                offset: const Offset(0, 45),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                onSelected: (value) async {
                                  if (value == 'settings') {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
                                  } else if (value == 'history') {
                                    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()));
                                    if (result != null && result is String) {
                                      _loadUrl(result);
                                    }
                                  } else if (value == 'desktop') {
                                    _toggleDesktopMode();
                                  } else if (value == 'fullscreen') {
                                    _toggleFullscreenVideo();
                                  } else if (value == 'bookmark') {
                                    final bookmarkService = Provider.of<BookmarkService>(context, listen: false);
                                    if (bookmarkService.isBookmarked(_currentUrl)) {
                                      bookmarkService.removeBookmark(_currentUrl);
                                    } else {
                                      bookmarkService.addBookmark(_currentTitle.isEmpty ? _currentUrl : _currentTitle, _currentUrl);
                                    }
                                  } else if (value == 'copy') {
                                    await Clipboard.setData(ClipboardData(text: _currentUrl));
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL Copied'), duration: Duration(seconds: 1)));
                                  } else if (value == 'share') {
                                    SharePlus.instance.share(ShareParams(text: _currentUrl));
                                  }
                                },
                                itemBuilder: (context) {
                                  final isBookmarked = Provider.of<BookmarkService>(context, listen: false).isBookmarked(_currentUrl);
                                  return [
                                    if (_urlFocusNode.hasFocus) ...[
                                      const PopupMenuItem(
                                        value: 'copy',
                                        child: Row(children: [Icon(Icons.copy, size: 20), SizedBox(width: 12), Text('Copy URL')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'share',
                                        child: Row(children: [Icon(Icons.share, size: 20), SizedBox(width: 12), Text('Share URL')]),
                                      ),
                                    ],
                                    PopupMenuItem(
                                      value: 'desktop',
                                      child: Row(
                                        children: [
                                          Icon(_isDesktopMode ? Icons.phone_android : Icons.desktop_mac, size: 20),
                                          const SizedBox(width: 12),
                                          Text(_isDesktopMode ? 'Mobile Site' : 'Desktop Site'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'fullscreen',
                                      child: Row(children: [Icon(Icons.fullscreen, size: 20), SizedBox(width: 12), Text('Toggle Fullscreen')]),
                                    ),
                                    if (!widget.isIncognito) ...[
                                      PopupMenuItem(
                                        value: 'bookmark',
                                        child: Row(
                                          children: [
                                            Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, size: 20),
                                            const SizedBox(width: 12),
                                            Text(isBookmarked ? 'Remove Bookmark' : 'Bookmark'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'history',
                                        child: Row(children: [Icon(Icons.history, size: 20), SizedBox(width: 12), Text('History')]),
                                      ),
                                    ],
                                    const PopupMenuItem(
                                      value: 'settings',
                                      child: Row(children: [Icon(Icons.settings, size: 20), SizedBox(width: 12), Text('Settings')],
                                      ),
                                    ),
                                  ];
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Listener(
                      onPointerMove: (details) {
                        // Only toggle header if NOT in exclusive fullscreen mode
                        if (!_isfullscreen) {
                          // Swipe Up to Hide
                          if (details.delta.dy < -10 && _isHeaderVisible) {
                            setState(() => _isHeaderVisible = false);
                          }
                          // Swipe Down to Show - ONLY if scrolled to top
                          if (details.delta.dy > 10 && !_isHeaderVisible && _scrollY <= 0) {
                            setState(() => _isHeaderVisible = true);
                          }
                        }
                      },
                      child: InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(_currentUrl), headers: {"X-Requested-With": ""}),
                        initialSettings: _browserSettings,
                        onWebViewCreated: (controller) {
                          _webViewController = controller;
                          if (_currentUrl.contains('hotstar.com')) {
                            controller.evaluateJavascript(source: "window.localStorage.clear(); window.sessionStorage.clear();");
                          }
                        },
                        onScrollChanged: (controller, x, y) {
                          _scrollY = y;
                        },
                        onPermissionRequest: (controller, request) async {
                          final resources = <PermissionResourceType>[];
                          for (var res in request.resources) {
                            if (res == PermissionResourceType.PROTECTED_MEDIA_ID) {
                              resources.add(res);
                            }
                          }
                          return PermissionResponse(resources: resources, action: resources.isEmpty ? PermissionResponseAction.DENY : PermissionResponseAction.GRANT);
                        },
                        shouldInterceptRequest: (controller, request) async {
                          if (request.headers != null) {
                            request.headers?.remove("X-Requested-With");
                            request.headers?.remove("x-requested-with");
                          }
                          return null;
                        },
                        onLoadStart: (controller, url) {
                          setState(() {
                            _isLoading = true;
                            _currentUrl = url.toString();
                            if (!_urlFocusNode.hasFocus) {
                              _urlController.text = _currentUrl;
                            }
                          });
                          _injectStealthAndFixes();
                        },
                        onLoadStop: (controller, url) async {
                          final title = await controller.getTitle();
                          final canGoBack = await controller.canGoBack();
                          setState(() {
                            _isLoading = false;
                            if (url != null) {
                              _currentUrl = url.toString();
                              if (!_urlFocusNode.hasFocus) {
                                _urlController.text = _currentUrl;
                              }
                              _updateSession(_currentUrl, title ?? '');

                              // Add to history
                              if (!widget.isIncognito) {
                                Provider.of<HistoryService>(context, listen: false).addToHistory(_currentUrl, title ?? '');
                              }
                            }
                            if (title != null && title.isNotEmpty) _currentTitle = title;
                            _canGoBack = canGoBack;
                          });
                          _injectStealthAndFixes();
                          
                          // Show Ad if needed
                          _showInterstitialAd();
                        },
                        onUpdateVisitedHistory: (controller, url, androidIsReload) async {
                          if (url != null) {
                            setState(() {
                              _currentUrl = url.toString();
                              if (!_urlFocusNode.hasFocus) {
                                _urlController.text = _currentUrl;
                              }
                            });
                            final title = await controller.getTitle();
                            _updateSession(_currentUrl, title ?? '');
                            // Add to history
                            if (!widget.isIncognito && context.mounted) {
                              Provider.of<HistoryService>(context, listen: false).addToHistory(_currentUrl, title ?? '');
                            }
                          }
                        },
                        onProgressChanged: (controller, progress) {
                          if (progress > 10 && progress < 90) {
                            _injectStealthAndFixes();
                          }
                          if (progress == 100) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fullscreen Exit Button - Only visible in explicit fullscreen mode
            if (_isfullscreen)
              Positioned(
                bottom: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    // Exit fullscreen
                    _toggleFullscreenVideo();
                    setState(() {
                      _isfullscreen = false;
                      _isHeaderVisible = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                  ),
                ),
              ),

            // Landscape Controls
            if (isLandscape && _isHeaderVisible)
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'landscape_back',
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                        onPressed: () async {
                          if (await _webViewController?.canGoBack() ?? false) {
                            _webViewController?.goBack();
                          } else {
                            if (context.mounted) Navigator.of(context).pop();
                          }
                        },
                        child: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      FloatingActionButton.small(
                        heroTag: 'landscape_close',
                        backgroundColor: Colors.red.withValues(alpha: 0.7),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isLoading)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
