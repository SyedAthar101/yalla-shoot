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
  /// links every match card to its homepage (yallah.media redirects to
  /// yallamedia.info), so that link must NOT count as a stream — otherwise
  /// tapping a match would just open the homepage again in the player.
  /// A real per-match link (a match page or an external player link) is
  /// the only thing that counts as a stream.
  bool get hasStream {
    final u = streamUrl.trim();
    if (u.isEmpty) return false;
    final n = u.toLowerCase().replaceAll(RegExp(r'/+$'), '');
    const noStream = {
      'https://yallah.media',
      'http://yallah.media',
      'https://www.yallah.media',
      'https://yallamedia.info',
      'http://yallamedia.info',
      'https://www.yallamedia.info',
      'https://yallah.media/matches-today',
      'https://yallah.media/matches-tomorrow',
      'https://yallah.media/matches-yesterday',
      'https://yallah.media/yalla-live',
      'https://yallamedia.info/matches-today',
      'https://yallamedia.info/matches-tomorrow',
      'https://yallamedia.info/matches-yesterday',
      'https://yallamedia.info/yalla-live',
    };
    if (noStream.contains(n)) return false;
    return u.startsWith('http');
  }

  String get scoreText => '$homeScore - $awayScore';

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
