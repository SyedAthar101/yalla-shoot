import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves the site's base URL at startup, so a site domain change
/// never needs a new APK again.
///
/// The site has moved domains repeatedly (yallamedia.info ->
/// yalla.show -> yallah.news -> yalla.loans, all within Nov 2026). Instead of
/// hardcoding the domain, the app fetches a tiny remote config —
/// app_config.json in the GitHub repo (SyedAthar101/yalla-shoot,
/// main branch) — and uses its "base_url". From now on, a domain
/// change is a one-line edit to that file; every installed app
/// picks it up on its next launch.
///
/// Resolution order:
///   1. Remote config (5s timeout); the result is cached.
///   2. Last cached base URL (SharedPreferences).
///   3. https://yallah.media — the site's original domain, which
///      redirects to the current one; the HTTP client follows
///      redirects, so requests still land on the live site.
///   4. The hardcoded fallback (https://yalla.loans) is the value
///      used until resolution finishes, and [candidateBases] always
///      keeps it as a last-resort request target.
class SiteConfig {
  static const String remoteConfigUrl =
      'https://raw.githubusercontent.com/SyedAthar101/yalla-shoot/main/app_config.json';

  /// The site's original domain; redirects to its current domain.
  static const String legacyBase = 'https://yallah.media';

  /// Last-resort hardcoded base (the site's domain as of v1.3.0).
  static const String hardcodedBase = 'https://yalla.loans';

  /// SharedPreferences key for the last resolved base URL.
  static const String cacheKey = 'yalla_site_base_url';

  static String _baseUrl = hardcodedBase;
  static Future<String>? _resolution;

  /// The resolved base URL (no trailing slash). Until
  /// [ensureResolved] completes this is [hardcodedBase].
  static String get baseUrl => _baseUrl;

  /// Ordered, de-duplicated request targets: the resolved base
  /// first, then the redirecting legacy domain, then the hardcoded
  /// fallback. YallaApi walks this list until one base answers.
  static List<String> candidateBases() {
    final seen = <String>{};
    return [
      for (final b in [_baseUrl, legacyBase, hardcodedBase])
        if (seen.add(b)) b,
    ];
  }

  /// Starts the startup resolution (once) and returns its future.
  static Future<String> ensureResolved() => _resolution ??= resolve();

  /// Runs the resolution chain described above. [client] and
  /// [prefs] are injectable for tests.
  static Future<String> resolve({
    http.Client? client,
    SharedPreferences? prefs,
  }) async {
    // 1) Remote config.
    final remote = await _fetchRemoteBase(client);
    if (remote != null) {
      _baseUrl = remote;
      try {
        final p = prefs ?? await SharedPreferences.getInstance();
        await p.setString(cacheKey, remote);
      } catch (_) {
        // Caching is best-effort; the fetched value is already live.
      }
      return _baseUrl;
    }
    // 2) Last cached base URL.
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final cached = normalizeBaseUrl(p.getString(cacheKey));
      if (cached != null) {
        _baseUrl = cached;
        return _baseUrl;
      }
    } catch (_) {
      // Fall through to the legacy domain.
    }
    // 3) Legacy domain (redirects to the current site).
    _baseUrl = legacyBase;
    return _baseUrl;
  }

  static Future<String?> _fetchRemoteBase(http.Client? client) async {
    final ownClient = client == null;
    final c = client ?? http.Client();
    try {
      final res = await c
          .get(Uri.parse(remoteConfigUrl))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map) return null;
      return normalizeBaseUrl(decoded['base_url']?.toString());
    } catch (_) {
      return null;
    } finally {
      if (ownClient) c.close();
    }
  }

  /// Validates and normalizes a base URL: it must be http(s) with a
  /// host, and trailing slashes are stripped. Returns null for
  /// anything invalid.
  static String? normalizeBaseUrl(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    final uri = Uri.tryParse(s);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  @visibleForTesting
  static void debugSetBaseUrl(String url) {
    _baseUrl = url;
    _resolution = Future<String>.value(url);
  }

  @visibleForTesting
  static void debugReset() {
    _baseUrl = hardcodedBase;
    _resolution = null;
  }
}
