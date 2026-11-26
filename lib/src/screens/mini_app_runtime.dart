
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/mini_app.dart';

/// Displays a submitted mini app as an immersive, edge-to-edge WebView.
class MiniAppRuntime extends StatefulWidget {
  const MiniAppRuntime({super.key, required this.app});

  final MiniApp app;

  @override
  State<MiniAppRuntime> createState() => _MiniAppRuntimeState();
}

class _MiniAppRuntimeState extends State<MiniAppRuntime> {
  late final WebViewController _controller;

  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('Mini App loading: $url');

            if (mounted) {
              setState(() {
                _loading = true;
                _hasError = false;
                _errorMessage = '';
              });
            }

            _applyImmersiveMode();
          },
          onPageFinished: (url) async {
            debugPrint('Mini App loaded: $url');
            // Lightweight page cleanup: stop common popup behaviour and hide
            // obvious ad containers without removing video/player iframes.
            try {
              await _controller.runJavaScript(r'''
                (function() {
                  try { window.open = function() { return null; }; } catch (_) {}
                  document.querySelectorAll('a[target="_blank"]').forEach(function(a) {
                    a.setAttribute('target', '_self');
                    a.setAttribute('rel', 'noopener noreferrer');
                  });
                  var selectors = [
                    '[id^="google_ads"]', '[id*="ad-container"]',
                    '[class*="ad-banner"]', '[class*="advertisement"]',
                    '[class="adsbygoogle"]', 'ins.adsbygoogle',
                    'iframe[src*="doubleclick.net"]',
                    'iframe[src*="googlesyndication.com"]'
                  ];
                  document.querySelectorAll(selectors.join(',')).forEach(function(el) {
                    el.style.setProperty('display', 'none', 'important');
                  });
                })();
              ''');
            } catch (_) { /* Some sites restrict injected scripts. */ }

            if (mounted) {
              setState(() {
                _loading = false;
                _hasError = false;
              });
            }

            _applyImmersiveMode();
          },
          onWebResourceError: (error) {
            debugPrint(
              'Mini App WebView error: '
                  '${error.errorCode} - ${error.description}',
            );

            // Ignore errors from subresources such as images,
            // advertisements, and analytics scripts.
            if (error.isForMainFrame == false) {
              return;
            }

            if (mounted) {
              setState(() {
                _loading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onHttpError: (error) {
            debugPrint(
              'Mini App HTTP error: '
                  '${error.response?.statusCode}',
            );
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);

            if (uri == null) {
              return NavigationDecision.prevent;
            }

            // Allow HTTP(S) page navigation; known advertising/redirect
            // domains are filtered below. Legitimate site redirects remain
            // enabled so canonical URLs and video/CDN links can work.
            if (uri.scheme == 'https' || uri.scheme == 'http') {
              final host = uri.host.toLowerCase();
              const blockedAdHosts = <String>[
                'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
                'adservice.google.com', 'popads.net', 'popcash.net',
                'exoclick.com', 'trafficjunky.net', 'propellerads.com',
                'adsterra.com', 'ad-maven.com', 'onclickalgo.com',
                'redirect.com', 'linkvertise.com',
              ];
              final isAdHost = blockedAdHosts.any((domain) =>
                  host == domain || host.endsWith('.$domain'));
              if (isAdHost) {
                debugPrint('Blocked advertising/redirect host: $host');
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            }

            // Prevent unsupported external schemes from crashing
            // or unexpectedly closing the mini app.
            debugPrint(
              'Blocked unsupported navigation: ${request.url}',
            );

            return NavigationDecision.prevent;
          },
        ),
      );

    _loadInitialPage();
  }

  void _applyImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  Future<void> _loadInitialPage() async {
    if (widget.app.packagePath != null) {
      try {
        if (!widget.app.packagePath!.toLowerCase().endsWith('.html')) {
          throw FormatException('The installed mini app entry file is invalid.');
        }
        await _controller.loadFile(widget.app.packagePath!);
        return;
      } catch (error) {
        if (mounted) setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Could not open the installed package: $error';
        });
        return;
      }
    }

    final uri = Uri.tryParse(widget.app.launchUrl);

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = 'Invalid mini app website URL.';
        });
      }
      return;
    }

    try {
      // Remove stale WebView resource cache entries.
      // This does not clear the website's cookies or login session.
      await _controller.clearCache();

      await _controller.loadRequest(uri);
    } catch (error) {
      debugPrint('Mini App launch failed: $error');

      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  Future<void> _retry() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (widget.app.packagePath != null) {
        await _controller.loadFile(widget.app.packagePath!);
        return;
      }
      await _controller.clearCache();

      // Retry the original website URL.
      await _controller.loadRequest(
        Uri.parse(widget.app.launchUrl),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),

          if (_loading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(
                minHeight: 2,
              ),
            ),

          if (_hasError)
            Container(
              color: Colors.white,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 56,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Unable to load mini app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
