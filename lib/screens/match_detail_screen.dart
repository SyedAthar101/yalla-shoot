import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../widgets/ui_kit.dart';
import 'player_screen.dart';

class MatchDetailScreen extends StatelessWidget {
  final YallaMatch match;
  final bool isFavorite;
  final VoidCallback onFavorite;

  const MatchDetailScreen({
    super.key,
    required this.match,
    required this.isFavorite,
    required this.onFavorite,
  });

  Widget _team(String logo, String name) {
    return Expanded(
      child: Column(
        children: [
          TeamLogo(url: logo, name: name, size: 104),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.redBright),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 15),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'غير معروف' : value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = match.status == MatchStatus.live;
    final showScore =
        live || match.status == MatchStatus.finished;
    final upcoming = match.status == MatchStatus.upcoming;
    final kickoff = match.kickoffLocal;
    final showCountdown =
        upcoming && kickoff != null && kickoff.isAfter(DateTime.now());
    final pillLabel = match.statusText.isNotEmpty
        ? match.statusText
        : MatchStatusLabel.label(match);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.appBarGradient,
          ),
        ),
        title: Text(
          match.league,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? AppColors.gold : Colors.white),
            onPressed: onFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (pillLabel.isNotEmpty)
                    StatusPill(
                      label: pillLabel,
                      color: live
                          ? Colors.white
                          : Colors.white.withOpacity(0.85),
                      isLive: live,
                    ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _team(match.homeLogo, match.homeTeam),
                      Padding(
                        padding: const EdgeInsets.only(top: 26),
                        child: Column(
                          children: [
                            Text(
                              showScore
                                  ? match.scoreText
                                  : match.localTimeText,
                              style: TextStyle(
                                fontSize: showScore ? 46 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              showScore
                                  ? match.localTimeText
                                  : 'بتوقيتك المحلي',
                              style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      Colors.white.withOpacity(0.75)),
                            ),
                          ],
                        ),
                      ),
                      _team(match.awayLogo, match.awayTeam),
                    ],
                  ),
                  if (showCountdown) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: KickoffCountdown(
                        kickoffLocal: kickoff,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.tv, 'القناة', match.channel),
                  Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                  _infoRow(Icons.mic, 'المعلق', match.commentator),
                  Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                  _infoRow(Icons.emoji_events, 'البطولة', match.league),
                  Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                  _infoRow(Icons.access_time, 'الوقت', match.localTimeText),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (match.hasStream)
              GradientButton(
                label: 'شاهد المباراة الآن',
                icon: Icons.play_arrow,
                height: 52,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(match: match),
                    ),
                  );
                },
              )
            else ...[
              const MutedLabel(text: 'البث غير متاح بعد'),
              const SizedBox(height: 10),
              Text(
                'الموقع ينشر رابط البث عند اقتراب وقت المباراة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
