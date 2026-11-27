// Tests for the live-site parser and the stream-link rule.
// Fixtures are real pages saved from yallamedia.info on 2026-11-24:
// today = 20 matches, yesterday = 18 matches, tomorrow = no matches yet.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_shoot/models/match_model.dart';
import 'package:yalla_shoot/services/yalla_api.dart';

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
  group('hasStream — homepage / list links are NOT a stream', () {
    test('homepage links on both domains are not a stream', () {
      for (final u in [
        'https://yallah.media/',
        'https://yallah.media',
        'https://yallamedia.info/',
        'https://yallamedia.info',
        'https://yallah.news/',
        'https://yallah.news',
        'https://yallah.news/matches-today/',
        'https://yallah.news/matches-yesterday/',
        'https://yallah.news/yalla-live/',
        'https://yallamedia.info/matches-today/',
        'https://yallamedia.info/matches-yesterday/',
        'https://yallamedia.info/yalla-live/',
        '',
      ]) {
        expect(_matchWithUrl(u).hasStream, isFalse, reason: u);
      }
    });

    test('a real per-match / player link IS a stream', () {
      for (final u in [
        'https://yallamedia.info/match/12345',
        'https://yallamo.cfd/live/abc',
        'https://example.com/watch/match-1',
      ]) {
        expect(_matchWithUrl(u).hasStream, isTrue, reason: u);
      }
    });
  });

  group('parseMatchesHtml on real saved site pages', () {
    test('today: 20 matches, all complete', () {
      final html = File('test/fixtures/matches-today.html').readAsStringSync();
      final cards = YallaApi.parseMatchesHtml(html, 'today');
      expect(cards.length, 20);
      for (final c in cards) {
        expect(c.homeTeam.isNotEmpty, isTrue);
        expect(c.awayTeam.isNotEmpty, isTrue);
        expect(c.time.isNotEmpty, isTrue, reason: '${c.homeTeam} time');
        expect(c.status, MatchStatus.upcoming);
        expect(c.statusText, 'لم تبدأ بعد');
        expect(c.homeLogo.isNotEmpty, isTrue);
        expect(c.awayLogo.isNotEmpty, isTrue);
        expect(c.league.isNotEmpty, isTrue);
        expect(c.channel.isNotEmpty, isTrue);
        // Site links every card to its homepage today — so no stream yet.
        expect(c.streamUrl, 'https://yallamedia.info/');
        expect(c.hasStream, isFalse);
      }
    });

    test('yesterday: 18 finished matches with scores', () {
      final html =
          File('test/fixtures/matches-yesterday.html').readAsStringSync();
      final cards = YallaApi.parseMatchesHtml(html, 'yesterday');
      expect(cards.length, 18);
      for (final c in cards) {
        expect(c.status, MatchStatus.finished);
        expect(c.statusText, 'انتهت');
        expect(c.time.isNotEmpty, isTrue);
        expect(c.hasStream, isFalse);
      }
    });

    test('tomorrow: site has no matches yet, parser returns empty', () {
      final html =
          File('test/fixtures/matches-tomorrow.html').readAsStringSync();
      final cards = YallaApi.parseMatchesHtml(html, 'tomorrow');
      expect(cards, isEmpty);
    });
  });

  // NOTE: live fetchMatches() is verified separately, not in this suite:
  // a Dart http script fetched the live site successfully
  // (feed 404 in ~8s through this sandbox's egress proxy, HTML 200 in
  // ~6s), and curl/python verified all three day pages return 200 with
  // parseable cards. A live-network test here is flaky in the sandbox
  // because Dart's HttpClient is very slow through the egress proxy,
  // while on a real phone it connects directly. The fixture tests above
  // run the real parser on real saved pages and are deterministic.
}
