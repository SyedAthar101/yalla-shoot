import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/match_model.dart';

/// Data source for the Yalla Shoot app.
///
/// Priority:
///   1. The official JSON feed from the Yalla Matches API plugin
///      (https://yallamedia.info/wp-json/yalla/v1/matches) — install the
///      plugin in wordpress-plugin/ on the site and this becomes
///      the live source, updated whenever the site is updated.
///   2. Fallback: parse the site's own rendered homepage for the day
///      (today / tomorrow / yesterday). Same data the website shows,
///      no third-party source involved.
///
/// Note: yallah.media 301-redirects to yallamedia.info (the site's
/// canonical domain), so the app talks to yallamedia.info directly
/// instead of depending on that redirect on every request.
class YallaApi {
  static const String siteBase = 'https://yallamedia.info';
  static const String jsonFeedBase = '$siteBase/wp-json/yalla/v1/matches';

  static String dayUrl(String day) {
    switch (day) {
      case 'tomorrow':
        return '$siteBase/matches-tomorrow/';
      case 'yesterday':
        return '$siteBase/matches-yesterday/';
      case 'today':
      default:
        return '$siteBase/matches-today/';
    }
  }

  static Future<List<YallaMatch>> fetchMatches(String day) async {
    // 1) Try the JSON feed first.
    try {
      final feed = await _fetchFromJsonFeed(day);
      if (feed.isNotEmpty) return feed;
    } catch (_) {
      // Fall through to HTML parsing — feed not installed yet.
    }
    // 2) Fallback: the site's own page.
    return _fetchFromHtml(day);
  }

  static Future<List<YallaMatch>> _fetchFromJsonFeed(String day) async {
    final uri = Uri.parse('$jsonFeedBase?day=$day');
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return [];
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final list = decoded is Map ? decoded['matches'] : decoded;
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((m) => YallaMatch.fromJson(
            Map<String, dynamic>.from(m), day))
        .toList();
  }

  static Future<List<YallaMatch>> _fetchFromHtml(String day) async {
    final uri = Uri.parse(dayUrl(day));
    final res = await http.get(uri, headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) YallaShootApp/1.0',
      'Accept': 'text/html',
    }).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('yallah.media se data nahi mila (${res.statusCode})');
    }
    return parseMatchesHtml(utf8.decode(res.bodyBytes), day);
  }

  /// Parse the AlbaYallaShoot theme markup: div.AY_Match with
  /// .TM_Name, .MT_Time, .RS-goals, .MT_Stat, .MT_Info li span,
  /// img[data-src] and the match <a href>.
  static List<YallaMatch> parseMatchesHtml(String html, String day) {
    final dom.Document doc = html_parser.parse(html);
    final cards = doc.querySelectorAll('div.AY_Match');
    final List<YallaMatch> out = [];
    for (final card in cards) {
      final names = card
          .querySelectorAll('.TM_Name')
          .map((e) => e.text.trim())
          .toList();
      if (names.length < 2) continue;
      final logos = card
          .querySelectorAll('img')
          .map((e) =>
              e.attributes['data-src'] ?? e.attributes['src'] ?? '')
          .where((s) => s.isNotEmpty && !s.startsWith('data:'))
          .toList();
      final goals = card
          .querySelectorAll('.RS-goals')
          .map((e) => e.text.trim())
          .toList();
      final time = card.querySelector('.MT_Time')?.text.trim() ?? '';
      final statusText =
          card.querySelector('.MT_Stat')?.text.trim() ?? '';
      final info = card
          .querySelectorAll('.MT_Info li span')
          .map((e) => e.text.trim())
          .toList();
      final link =
          card.querySelector('a')?.attributes['href'] ?? '';
      final cssClass = card.attributes['class'] ?? '';
      final home = names[0];
      final away = names[1];
      out.add(YallaMatch(
        id: '${day}_${home}_vs_${away}_$time',
        homeTeam: home,
        awayTeam: away,
        homeLogo: logos.isNotEmpty ? logos[0] : '',
        awayLogo: logos.length > 1 ? logos[1] : '',
        time: time,
        homeScore: goals.isNotEmpty ? goals[0] : '0',
        awayScore: goals.length > 1 ? goals[1] : '0',
        statusText: statusText,
        status: YallaMatch.statusFromText(statusText, cssClass),
        channel: info.isNotEmpty ? info[0] : '',
        commentator: info.length > 1 ? info[1] : '',
        league: info.length > 2 ? info[2] : '',
        streamUrl: link,
        day: day,
      ));
    }
    return out;
  }
}
