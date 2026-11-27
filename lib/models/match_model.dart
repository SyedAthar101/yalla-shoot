import '../services/site_config.dart';

enum MatchStatus { live, upcoming, finished, unknown }

class YallaMatch {
  final String id;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final String time;
  final String homeScore;
  final String awayScore;
  final String statusText;
  final MatchStatus status;
  final String channel;
  final String commentator;
  final String league;
  final String streamUrl;
  final String day; // today | tomorrow | yesterday

  const YallaMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeLogo,
    required this.awayLogo,
    required this.time,
    required this.homeScore,
    required this.awayScore,
    required this.statusText,
    required this.status,
    required this.channel,
    required this.commentator,
    required this.league,
    required this.streamUrl,
    required this.day,
  });

  static MatchStatus statusFromText(String text, String cssClass) {
    final t = text.trim();
    if (cssClass.contains('live') || t.contains('جارية') || t.contains('مباشر')) {
      return MatchStatus.live;
    }
    if (cssClass.contains('finished') ||
        t.contains('انتهت') ||
        t.contains('انتهاء')) {
      return MatchStatus.finished;
    }
    if (cssClass.contains('not-started') || t.contains('لم تبدأ')) {
      return MatchStatus.upcoming;
    }
    return MatchStatus.unknown;
  }

  /// A stream link is only playable when it points somewhere other than
  /// the homepage / match-list pages themselves. The website currently
  /// links every match card to its homepage (yallah.media and
  /// yallamedia.info redirect to yallah.news), so that link must NOT count
  /// as a stream — otherwise tapping a match would just open the homepage
  /// again in the player.
  /// A real per-match link (a match page or an external player link) is
  /// the only thing that counts as a stream.
  bool get hasStream {
    final u = streamUrl.trim();
    if (u.isEmpty) return false;
    final n = u.toLowerCase().replaceAll(RegExp(r'/+$'), '');
    final noStream = <String>{
      'https://yallah.media',
      'http://yallah.media',
      'https://www.yallah.media',
      'https://yallamedia.info',
      'http://yallamedia.info',
      'https://www.yallamedia.info',
      'https://yallah.news',
      'http://yallah.news',
      'https://www.yallah.news',
      'https://yallah.media/matches-today',
      'https://yallah.media/matches-tomorrow',
      'https://yallah.media/matches-yesterday',
      'https://yallah.media/yalla-live',
      'https://yallamedia.info/matches-today',
      'https://yallamedia.info/matches-tomorrow',
      'https://yallamedia.info/matches-yesterday',
      'https://yallamedia.info/yalla-live',
      'https://yallah.news/matches-today',
      'https://yallah.news/matches-tomorrow',
      'https://yallah.news/matches-yesterday',
      'https://yallah.news/yalla-live',
    };
    // The site's currently resolved base (SiteConfig — the domain
    // can change without an app update) and its list pages are not
    // streams either, whatever domain the site lives on next.
    final base = SiteConfig.baseUrl.toLowerCase();
    noStream.add(base);
    noStream.add('$base/matches-today');
    noStream.add('$base/matches-tomorrow');
    noStream.add('$base/matches-yesterday');
    noStream.add('$base/yalla-live');
    final baseUri = Uri.tryParse(base);
    if (baseUri != null &&
        baseUri.host.isNotEmpty &&
        !baseUri.host.startsWith('www.')) {
      noStream.add('${baseUri.scheme}://www.${baseUri.host}');
    }
    if (noStream.contains(n)) return false;
    return u.startsWith('http');
  }

  String get scoreText => '$homeScore - $awayScore';

  // ------------------------------------------------------------------
  // Kickoff time: the site publishes match times as Africa/Cairo
  // wall-clock time. Everything below converts that instant to the
  // device's local timezone for display. No new dependency.
  //
  // Egypt DST rule (in force since 2023): clocks are UTC+3 during
  // daylight saving, from the last Friday of April until the last
  // Thursday of October, and UTC+2 the rest of the year.
  // ------------------------------------------------------------------

  static DateTime _lastWeekdayOfMonth(int year, int month, int weekday) {
    // DateTime.utc(year, month + 1, 0) is the last day of [month].
    var d = DateTime.utc(year, month + 1, 0);
    while (d.weekday != weekday) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  /// UTC offset of Africa/Cairo on the given (UTC) date.
  static Duration cairoOffsetFor(DateTime date) {
    final dstStart = _lastWeekdayOfMonth(date.year, 4, DateTime.friday);
    final dstEnd = _lastWeekdayOfMonth(date.year, 10, DateTime.thursday);
    final day = DateTime.utc(date.year, date.month, date.day);
    final isDst = !day.isBefore(dstStart) && !day.isAfter(dstEnd);
    return Duration(hours: isDst ? 3 : 2);
  }

  /// A Cairo wall-clock time on [date] (year/month/day) as a UTC instant.
  static DateTime cairoToUtc(DateTime date, int hour, int minute) {
    final wall =
        DateTime.utc(date.year, date.month, date.day, hour, minute);
    return wall.subtract(cairoOffsetFor(date));
  }

  /// Parse a site time string into a 24h time of day. Handles both
  /// "19:00" and the site's usual "03:30 PM" (plus Arabic-Indic digits).
  /// Returns null for anything that is not a time (live/finished labels).
  static ({int hour, int minute})? parseTimeOfDay(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    // Normalize Arabic-Indic digits to Western digits.
    s = s.split('').map((c) {
      final code = c.codeUnitAt(0);
      if (code >= 0x660 && code <= 0x669) {
        return String.fromCharCode(0x30 + code - 0x660);
      }
      if (code >= 0x6F0 && code <= 0x6F9) {
        return String.fromCharCode(0x30 + code - 0x6F0);
      }
      return c;
    }).join();
    final m = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp]\.?[Mm]\.?)?$')
        .firstMatch(s);
    if (m == null) return null;
    var hour = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final ampm = m.group(3);
    if (ampm != null) {
      final isPm = ampm.toLowerCase().startsWith('p');
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
    }
    if (hour > 23 || minute > 59) return null;
    return (hour: hour, minute: minute);
  }

  /// Kickoff as a UTC instant, built from this match's [day]
  /// (today/tomorrow/yesterday, in Cairo) and its [time] string
  /// (Cairo wall-clock). Null when the time is not a parseable
  /// HH:MM (e.g. live / finished matches).
  DateTime? get kickoffUtc {
    final tod = parseTimeOfDay(time);
    if (tod == null) return null;
    // Cairo's "today": shift UTC now by the Cairo offset. DST only
    // changes at Cairo midnight, so this is exact in practice.
    final utcNow = DateTime.now().toUtc();
    final cairoNow = utcNow.add(cairoOffsetFor(utcNow));
    var date = DateTime.utc(cairoNow.year, cairoNow.month, cairoNow.day);
    if (day == 'tomorrow') {
      date = date.add(const Duration(days: 1));
    } else if (day == 'yesterday') {
      date = date.subtract(const Duration(days: 1));
    }
    return cairoToUtc(date, tod.hour, tod.minute);
  }

  /// Kickoff in the device's local timezone. Null when unparseable.
  DateTime? get kickoffLocal => kickoffUtc?.toLocal();

  /// Time to show in the UI: kickoff converted to the device's local
  /// timezone, with the local timezone name, e.g. "19:00 PKT".
  /// Falls back to the raw site time when it cannot be parsed.
  String get localTimeText {
    final local = kickoffLocal;
    if (local == null) return time;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm ${DateTime.now().timeZoneName}';
  }

  factory YallaMatch.fromJson(Map<String, dynamic> json, String day) {
    final home = (json['home_team'] ?? '').toString();
    final away = (json['away_team'] ?? '').toString();
    final time = (json['time'] ?? '').toString();
    final statusText = (json['status_text'] ?? '').toString();
    final css = (json['status_class'] ?? '').toString();
    return YallaMatch(
      id: (json['id'] ?? '${day}_${home}_vs_${away}_$time').toString(),
      homeTeam: home,
      awayTeam: away,
      homeLogo: (json['home_logo'] ?? '').toString(),
      awayLogo: (json['away_logo'] ?? '').toString(),
      time: time,
      homeScore: (json['home_score'] ?? '0').toString(),
      awayScore: (json['away_score'] ?? '0').toString(),
      statusText: statusText,
      status: statusFromText(statusText, css),
      channel: (json['channel'] ?? '').toString(),
      commentator: (json['commentator'] ?? '').toString(),
      league: (json['league'] ?? '').toString(),
      streamUrl: (json['stream_url'] ?? '').toString(),
      day: day,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'home_team': homeTeam,
        'away_team': awayTeam,
        'home_logo': homeLogo,
        'away_logo': awayLogo,
        'time': time,
        'home_score': homeScore,
        'away_score': awayScore,
        'status_text': statusText,
        'channel': channel,
        'commentator': commentator,
        'league': league,
        'stream_url': streamUrl,
      };
}
