import 'package:flutter/material.dart';

import '../models/match_model.dart';
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

  Widget _team(BuildContext context, String logo, String name, bool home) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: logo.isEmpty
                ? Center(
                    child: Text(
                      name.isNotEmpty ? name.characters.first : '?',
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  )
                : Image.network(
                    logo,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        name.isNotEmpty ? name.characters.first : '?',
                        style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 16,
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
          Icon(icon, size: 20, color: const Color(0xFF931800)),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'غير معروف' : value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF931800),
        title: Text(
          match.league,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.star : Icons.star_border,
                color:
                    isFavorite ? const Color(0xFFFFC107) : Colors.white),
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
                color: const Color(0xFF1B1B24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (live
                              ? const Color(0xFFE53935)
                              : const Color(0xFF2E9E5B))
                          .withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      match.statusText.isEmpty
                          ? match.time
                          : match.statusText,
                      style: TextStyle(
                        color: live
                            ? const Color(0xFFE53935)
                            : const Color(0xFF2E9E5B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _team(context, match.homeLogo, match.homeTeam, true),
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Column(
                          children: [
                            Text(
                              match.scoreText,
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              match.time,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                      _team(context, match.awayLogo, match.awayTeam, false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.tv, 'القناة', match.channel),
                  _infoRow(Icons.mic, 'المعلق', match.commentator),
                  _infoRow(Icons.emoji_events, 'البطولة', match.league),
                  _infoRow(Icons.access_time, 'الوقت', match.time),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: match.hasStream
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(match: match),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow, size: 26),
                label: Text(
                  match.hasStream
                      ? 'شاهد المباراة الآن'
                      : 'البث غير متاح بعد — تحقق وقت المباراة',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF931800),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white38,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (!match.hasStream) ...[
              const SizedBox(height: 10),
              Text(
                'الموقع ينشر رابط البث عند اقتراب المباراة — اسحب للتحديث.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
