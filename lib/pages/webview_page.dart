
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/ad_block_service.dart';
import '../services/bookmark_service.dart';
import '../services/theme_service.dart';

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

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? _webViewController;
  late String _currentUrl;
  late String _currentTitle;
  bool _isLoading = true;
  bool _canGoBack = false;
  bool _isDesktopMode = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _currentTitle = widget.title;
    final themeService = Provider.of<ThemeService>(context, listen: false);
    _isDesktopMode = widget.preferDesktopMode ?? themeService.isDesktopMode;
    
    if (widget.isIncognito) {
      CookieManager.instance().deleteAllCookies();
    }
  }

  InAppWebViewSettings get _browserSettings {
    final userAgent = _isDesktopMode
        ? "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36"
        : "Mozilla/5.0 (Linux; Android 14; Pixel 8 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Mobile Safari/537.36";

    return InAppWebViewSettings(
      userAgent: userAgent,
      preferredContentMode: _isDesktopMode ? UserPreferredContentMode.DESKTOP : UserPreferredContentMode.MOBILE,
      useWideViewPort: true,
      loadWithOverviewMode: true,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      builtInZoomControls: true,
      displayZoomControls: false,
      supportZoom: true,
      transparentBackground: true,
      safeBrowsingEnabled: true,
      thirdPartyCookiesEnabled: true,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
      // KILL THE WEBVIEW SIGNATURE
      useShouldInterceptRequest: true,
    );
  }

  void _toggleDesktopMode() {
    setState(() {
      _isDesktopMode = !_isDesktopMode;
      _isLoading = true;
    });
    _webViewController?.setSettings(settings: _browserSettings);
    _webViewController?.reload();
  }

  void _forceFullscreenVideo() {
    _webViewController?.evaluateJavascript(
      source: """
      (function() {
        var videos = document.getElementsByTagName('video');
        if (videos.length > 0) {
          var v = videos[0];
          v.style.position = 'fixed';
          v.style.top = '0';
          v.style.left = '0';
          v.style.width = '100vw';
          v.style.height = '100vh';
          v.style.zIndex = '999999';
          v.style.backgroundColor = 'black';
          
          var container = v.parentElement;
          while(container && container !== document.body) {
             container.style.position = 'static';
             container.style.transform = 'none';
             container = container.parentElement;
          }
        }
      })();
    """,
    );
  }

  void _injectStealthAndFixes() {
    _webViewController?.evaluateJavascript(
      source:
          """
      (function() {
        const isDesktop = $_isDesktopMode;
        
        // 1. Critical: Hide WebView/Automation
        Object.defineProperty(navigator, 'webdriver', {get: () => false});
        window.navigator.chrome = {
          runtime: {},
          loadTimes: function() {},
          csi: function() {},
          app: { isInstalled: false }
        };

        // 2. Spoof Platform & Identity
        const platform = isDesktop ? 'Win32' : 'Linux armv8l';
        Object.defineProperty(navigator, 'platform', { get: () => platform });
        Object.defineProperty(navigator, 'vendor', { get: () => 'Google Inc.' });

        // 3. Spoof Hardware Fingerprint
        Object.defineProperty(navigator, 'deviceMemory', { get: () => 8 });
        Object.defineProperty(navigator, 'hardwareConcurrency', { get: () => 8 });
        Object.defineProperty(navigator, 'maxTouchPoints', { get: () => isDesktop ? 0 : 10 });

        // 4. Fix Permissions API
        const originalQuery = window.navigator.permissions.query;
        window.navigator.permissions.query = (parameters) => (
          parameters.name === 'notifications' ?
            Promise.resolve({ state: Notification.permission }) :
            originalQuery(parameters)
        );

        // 5. UserAgentData
        if (navigator.userAgentData) {
          Object.defineProperty(navigator.userAgentData, 'platform', { get: () => isDesktop ? 'Windows' : 'Android' });
          Object.defineProperty(navigator.userAgentData, 'mobile', { get: () => !isDesktop });
          Object.defineProperty(navigator.userAgentData, 'brands', { 
            get: () => [
              {brand: 'Not/A)Brand', version: '8'}, 
              {brand: 'Chromium', version: '126'}, 
              {brand: 'Google Chrome', version: '126'}
            ] 
          });
        }
        
        Object.defineProperty(navigator, 'languages', { get: () => ['en-US', 'en'] });
        
        // Video Fill Fixes
        var style = document.createElement('style');
        style.innerHTML = `
          video { width: 100% !important; height: auto !important; max-height: 100vh !important; } 
          .vjs-tech { width: 100% !important; height: 100% !important; }
        `;
        document.head.appendChild(style);

        // Viewport Fixes
        if (isDesktop) {
          var meta = document.querySelector('meta[name="viewport"]');
          const content = 'width=1280, initial-scale=0.35, maximum-scale=5.0, user-scalable=yes';
          if (meta) {
            meta.setAttribute('content', content);
          } else {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = content;
            document.getElementsByTagName('head')[0].appendChild(meta);
          }
          document.documentElement.style.minWidth = '1280px';
          document.body.style.minWidth = '1280px';
        }

        if (window.Android) { window.Android = undefined; }
      })();
    """,
    );
    
    final adBlockService = Provider.of<AdBlockService>(context, listen: false);
    if (adBlockService.isEnabled) {
      _webViewController?.evaluateJavascript(source: adBlockService.adBlockJs);
    }
  }

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
            Column(
              children: [
                if (!isLandscape)
                  SafeArea(
                    bottom: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      color: Theme.of(context).appBarTheme.backgroundColor,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_rounded,
                                size: 20, color: Theme.of(context).iconTheme.color),
                            onPressed: () async {
                              if (await _webViewController?.canGoBack() ?? false) {
                                _webViewController?.goBack();
                              } else {
                                if (context.mounted) Navigator.of(context).pop();
                              }
                            },
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                                  ),
                                ),
                                if (widget.isIncognito)
                                  const Text(
                                    'INCOGNITO',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isDesktopMode ? Icons.desktop_mac_rounded : Icons.phone_android_rounded,
                                      size: 20,
                                      color: _isDesktopMode ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
                                    ),
                                    tooltip: _isDesktopMode ? 'Switch to Mobile' : 'Switch to Desktop',
                                    onPressed: _toggleDesktopMode,
                                  ),
                                  IconButton(icon: const Icon(Icons.fullscreen_rounded, size: 20), tooltip: 'Force Fullscreen Video', onPressed: _forceFullscreenVideo),
                                  if (!widget.isIncognito)
                                    Consumer<BookmarkService>(
                                      builder: (context, bookmarkService, child) {
                                        final isBookmarked = bookmarkService.isBookmarked(_currentUrl);
                                        return IconButton(
                                          icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: isBookmarked ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color),
                                          onPressed: () {
                                            if (isBookmarked) {
                                              bookmarkService.removeBookmark(_currentUrl);
                                            } else {
                                              bookmarkService.addBookmark(_currentTitle.isEmpty ? _currentUrl : _currentTitle, _currentUrl);
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  IconButton(
                                    icon: Icon(Icons.refresh_rounded, color: Theme.of(context).iconTheme.color),
                                    onPressed: () {
                                      _webViewController?.reload();
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, color: Theme.of(context).disabledColor),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(_currentUrl), headers: {"X-Requested-With": ""}),
                    initialSettings: _browserSettings,
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      if (_currentUrl.contains('hotstar.com')) {
                        controller.evaluateJavascript(source: "window.localStorage.clear(); window.sessionStorage.clear();");
                      }
                    },
                    onPermissionRequest: (controller, request) async {
                      // CRITICAL FOR DRM: Explicitly allow protected media
                      return PermissionResponse(resources: request.resources, action: PermissionResponseAction.GRANT);
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
                      });
                      _injectStealthAndFixes();
                    },
                    onLoadStop: (controller, url) async {
                      final title = await controller.getTitle();
                      final canGoBack = await controller.canGoBack();
                      setState(() {
                        _isLoading = false;
                        if (url != null) _currentUrl = url.toString();
                        if (title != null && title.isNotEmpty) _currentTitle = title;
                        _canGoBack = canGoBack;
                      });
                      _injectStealthAndFixes();
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
              ],
            ),
            if (isLandscape)
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
