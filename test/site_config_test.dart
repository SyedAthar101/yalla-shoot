// Tests for SiteConfig: the remote-config base-URL resolution that
// makes the app survive site domain changes without an APK update.
// All network access is mocked (MockClient); SharedPreferences uses
// the flutter_test mock store. No live network in this suite.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yalla_shoot/models/match_model.dart';
import 'package:yalla_shoot/services/site_config.dart';

YallaMatch _matchWithUrl(String url) => YallaMatch(
      id: 'test',
      homeTeam: 'A',
      awayTeam: 'B',
      homeLogo: '',
      awayLogo: '',
      time: '03:30 PM',
      homeScore: '0',
      awayScore: '0',
      statusText: 'لم تبدأ بعد',
      status: MatchStatus.upcoming,
      channel: '',
      commentator: '',
      league: '',
      streamUrl: url,
      day: 'today',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SiteConfig.debugReset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SiteConfig.debugReset();
  });

  group('normalizeBaseUrl', () {
    test('accepts an https URL and strips the trailing slash', () {
      expect(SiteConfig.normalizeBaseUrl('https://yallah.news/'),
          'https://yallah.news');
      expect(SiteConfig.normalizeBaseUrl('  https://example.com  '),
          'https://example.com');
      expect(SiteConfig.normalizeBaseUrl('http://example.com'),
          'http://example.com');
    });

    test('rejects invalid values', () {
      expect(SiteConfig.normalizeBaseUrl(null), isNull);
      expect(SiteConfig.normalizeBaseUrl(''), isNull);
      expect(SiteConfig.normalizeBaseUrl('   '), isNull);
      expect(SiteConfig.normalizeBaseUrl('yallah.news'), isNull);
      expect(SiteConfig.normalizeBaseUrl('ftp://example.com'), isNull);
      expect(SiteConfig.normalizeBaseUrl('https://'), isNull);
    });
  });

  group('resolve', () {
    test('uses the remote config base_url and caches it', () async {
      final prefs = await SharedPreferences.getInstance();
      final client = MockClient((req) async {
        expect(req.url.toString(), SiteConfig.remoteConfigUrl);
        return http.Response(
            jsonEncode({'base_url': 'https://new-domain.example/'}), 200);
      });
      final base = await SiteConfig.resolve(client: client, prefs: prefs);
      expect(base, 'https://new-domain.example');
      expect(SiteConfig.baseUrl, 'https://new-domain.example');
      expect(prefs.getString(SiteConfig.cacheKey),
          'https://new-domain.example');
    });

    test('falls back to the cached base when the remote fetch fails',
        () async {
      SharedPreferences.setMockInitialValues(
          {SiteConfig.cacheKey: 'https://cached.example'});
      final prefs = await SharedPreferences.getInstance();
      final client =
          MockClient((req) async => http.Response('not found', 404));
      final base = await SiteConfig.resolve(client: client, prefs: prefs);
      expect(base, 'https://cached.example');
      expect(SiteConfig.baseUrl, 'https://cached.example');
    });

    test('falls back to the legacy redirect domain when nothing works',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final client = MockClient(
          (req) async => throw http.ClientException('offline'));
      final base = await SiteConfig.resolve(client: client, prefs: prefs);
      expect(base, SiteConfig.legacyBase);
      expect(SiteConfig.baseUrl, SiteConfig.legacyBase);
    });

    test('ignores an invalid base_url in the remote config', () async {
      SharedPreferences.setMockInitialValues(
          {SiteConfig.cacheKey: 'https://cached.example'});
      final prefs = await SharedPreferences.getInstance();
      final client = MockClient((req) async =>
          http.Response(jsonEncode({'base_url': 'not a url'}), 200));
      final base = await SiteConfig.resolve(client: client, prefs: prefs);
      expect(base, 'https://cached.example');
    });

    test('ignores a non-JSON remote config', () async {
      final prefs = await SharedPreferences.getInstance();
      final client =
          MockClient((req) async => http.Response('<html>404</html>', 200));
      final base = await SiteConfig.resolve(client: client, prefs: prefs);
      expect(base, SiteConfig.legacyBase);
    });
  });

  group('candidateBases', () {
    test('resolved base first, then legacy, then hardcoded', () {
      SiteConfig.debugSetBaseUrl('https://new-domain.example');
      expect(SiteConfig.candidateBases(), [
        'https://new-domain.example',
        SiteConfig.legacyBase,
        SiteConfig.hardcodedBase,
      ]);
    });

    test('de-duplicates when the resolved base is the hardcoded one',
        () {
      expect(SiteConfig.candidateBases(), [
        SiteConfig.hardcodedBase,
        SiteConfig.legacyBase,
      ]);
    });

    test('de-duplicates when the resolved base is the legacy one',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final client = MockClient(
          (req) async => throw http.ClientException('offline'));
      await SiteConfig.resolve(client: client, prefs: prefs);
      expect(SiteConfig.candidateBases(), [
        SiteConfig.legacyBase,
        SiteConfig.hardcodedBase,
      ]);
    });
  });

  group('hasStream follows the resolved base', () {
    test('homepage / list pages of a future domain are not a stream',
        () {
      SiteConfig.debugSetBaseUrl('https://future-domain.example');
      expect(_matchWithUrl('https://future-domain.example/').hasStream,
          isFalse);
      expect(_matchWithUrl('https://future-domain.example').hasStream,
          isFalse);
      expect(
          _matchWithUrl('https://future-domain.example/matches-today/')
              .hasStream,
          isFalse);
      expect(
          _matchWithUrl('https://www.future-domain.example/').hasStream,
          isFalse);
    });

    test('a per-match page on the future domain IS a stream', () {
      SiteConfig.debugSetBaseUrl('https://future-domain.example');
      expect(
          _matchWithUrl('https://future-domain.example/match/12345')
              .hasStream,
          isTrue);
    });
  });
}
