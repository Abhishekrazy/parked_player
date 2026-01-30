
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/ad_block_service.dart';
import '../services/bookmark_service.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final bool isIncognito;

  const WebViewPage({
    super.key, 
    required this.url, 
    required this.title,
    this.isIncognito = false,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _canGoBack = false;
  late String _currentUrl;
  late String _currentTitle;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _currentTitle = widget.title;

    if (widget.isIncognito) {
      WebViewCookieManager().clearCookies();
    }

    // Create the controller
    final WebViewController controller = WebViewController();

    // Configure Android-specific features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) async {
            final title = await controller.getTitle();
            if (mounted) {
              setState(() {
                _isLoading = false;
                _currentUrl = url;
                _currentTitle = (title != null && title.isNotEmpty) ? title : url;
              });
            }
            _injectAdBlocker();
            _checkCanGoBack();
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            final adBlockService =
                Provider.of<AdBlockService>(context, listen: false);
            if (adBlockService.shouldBlockRequest(request.url)) {
              debugPrint('Blocking Ad/Tracker: ${request.url}');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    _controller = controller;
  }
  
  @override
  void dispose() {
    if (widget.isIncognito) {
      WebViewCookieManager().clearCookies();
      _controller.clearLocalStorage();
    }
    super.dispose();
  }

  void _injectAdBlocker() {
    final adBlockService = Provider.of<AdBlockService>(context, listen: false);
    if (adBlockService.isEnabled) {
      _controller.runJavaScript(adBlockService.adBlockJs);
    }
  }

  Future<void> _checkCanGoBack() async {
    final canGoBack = await _controller.canGoBack();
    if (mounted) {
      setState(() {
        _canGoBack = canGoBack;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: !_canGoBack,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _controller.goBack();
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
                              if (await _controller.canGoBack()) {
                                _controller.goBack();
                              } else {
                                if (context.mounted) Navigator.of(context).pop();
                              }
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // Display current page title (or fallback to url/widget title logic handled in state)
                                  _currentTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: Theme.of(context).appBarTheme.titleTextStyle?.color,
                                  ),
                                ),
                                if (widget.isIncognito)
                                  const Text(
                                    'INCOGNITO',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                          if (!widget.isIncognito)
                            Consumer<BookmarkService>(
                              builder: (context, bookmarkService, child) {
                                final isBookmarked =
                                    bookmarkService.isBookmarked(_currentUrl);
                                return IconButton(
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isBookmarked
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).iconTheme.color,
                                  ),
                                  onPressed: () {
                                    if (isBookmarked) {
                                      bookmarkService.removeBookmark(_currentUrl);
                                    } else {
                                      // Save current URL and Title
                                      bookmarkService.addBookmark(
                                          _currentTitle.isEmpty ? _currentUrl : _currentTitle, _currentUrl);
                                    }
                                  },
                                );
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.refresh_rounded,
                                color: Theme.of(context).iconTheme.color),
                            onPressed: () {
                              _controller.reload();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded,
                                color: Theme.of(context).disabledColor),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(child: WebViewWidget(controller: _controller)),
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
                          if (await _controller.canGoBack()) {
                            _controller.goBack();
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
