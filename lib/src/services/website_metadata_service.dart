import 'dart:convert';

import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Reads common HTML/Open Graph metadata from a public HTTPS website.
///
/// For Flutter Web, browsers may block cross-origin requests. In production,
/// route this request through your own metadata-preview backend endpoint.
class WebsiteMetadata {
  const WebsiteMetadata({
    this.title,
    this.description,
    this.siteName,
    this.imageUrl,
    this.iconUrl,
    this.canonicalUrl,
    this.language,
    this.themeColor,
  });

  final String? title;
  final String? description;
  final String? siteName;
  final String? imageUrl;
  final String? iconUrl;
  final String? canonicalUrl;
  final String? language;
  final String? themeColor;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'siteName': siteName,
        'imageUrl': imageUrl,
        'iconUrl': iconUrl,
        'canonicalUrl': canonicalUrl,
        'language': language,
        'themeColor': themeColor,
      };
}

class WebsiteMetadataService {
  WebsiteMetadataService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<WebsiteMetadata> fetch(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Enter a valid public HTTPS website URL.');
    }

    final response = await _client
        .get(
          uri,
          headers: const {
            'User-Agent': 'TweenMiniAppStore/1.0 (+website metadata preview)',
            'Accept': 'text/html,application/xhtml+xml',
          },
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode < 200 || response.statusCode >= 400) {
      throw Exception('Website returned HTTP ${response.statusCode}.');
    }
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.isNotEmpty &&
        !contentType.toLowerCase().contains('text/html') &&
        !contentType.toLowerCase().contains('xhtml')) {
      throw const FormatException('This URL did not return an HTML webpage.');
    }

    // Avoid parsing very large pages in the UI isolate.
    final body = response.body;
    if (utf8.encode(body).length > 3 * 1024 * 1024) {
      throw const FormatException('Website HTML is too large to preview.');
    }
    final document = html_parser.parse(body);
    String? meta(String key, {String attribute = 'property'}) {
      final element = document.querySelector('meta[$attribute="$key"]') ??
          document.querySelector('meta[name="$key"]');
      final value = element?.attributes['content']?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    String? firstLink(List<String> rels) {
      for (final rel in rels) {
        final link = document.querySelector('link[rel~="$rel"]');
        final value = link?.attributes['href']?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    String? title = meta('og:title') ??
        meta('twitter:title', attribute: 'name') ??
        document.querySelector('title')?.text.trim();
    String? description = meta('og:description') ??
        meta('twitter:description', attribute: 'name') ??
        meta('description', attribute: 'name');
    String? siteName = meta('og:site_name');
    String? image = meta('og:image') ??
        meta('twitter:image', attribute: 'name');
    String? icon = firstLink([
      'apple-touch-icon',
      'icon',
      'shortcut',
    ]) ??
        document.querySelector('link[rel*="icon"]')?.attributes['href'];
    String? canonical = document
        .querySelector('link[rel="canonical"]')
        ?.attributes['href'];
    String? language = document.documentElement?.attributes['lang'];
    String? theme = meta('theme-color', attribute: 'name');

    String? resolve(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return uri.resolve(value.trim()).toString();
    }

    return WebsiteMetadata(
      title: _clean(title),
      description: _clean(description),
      siteName: _clean(siteName),
      imageUrl: resolve(image),
      iconUrl: resolve(icon),
      canonicalUrl: resolve(canonical) ?? uri.toString(),
      language: _clean(language),
      themeColor: _clean(theme),
    );
  }

  static String? _clean(String? value) {
    if (value == null) return null;
    final cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  void dispose() => _client.close();
}
