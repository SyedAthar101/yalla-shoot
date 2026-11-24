import 'package:flutter/material.dart';

import '../models/match_model.dart';

class MatchCard extends StatelessWidget {
  final YallaMatch match;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const MatchCard({
    super.key,
    required this.match,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  Color _statusColor(BuildContext context) {
    switch (match.status) {
      case MatchStatus.live:
        return const Color(0xFFE53935);
      case MatchStatus.finished:
        return Colors.grey;
      case MatchStatus.upcoming:
        return const Color(0xFF2E9E5B);
      case MatchStatus.unknown:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    if (match.statusText.isNotEmpty) return match.statusText;
    switch (match.status) {
      case MatchStatus.live:
        return 'جارية الان';
      case MatchStatus.finished:
        return 'انتهت';
      case MatchStatus.upcoming:
        return 'لم تبدأ بعد';
      case MatchStatus.unknown:
        return '';
    }
  }

  Widget _logo(String url, String name) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Center(
              child: Text(
                name.isNotEmpty ? name.characters.first : '?',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Center(
                child: Text(
                  name.isNotEmpty ? name.characters.first : '?',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = match.status == MatchStatus.live;
    return Card(
      color: const Color(0xFF1B1B24),
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: live
              ? const Color(0xFF931800).withOpacity(0.7)
              : Colors.white.withOpacity(0.07),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor(context).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (live)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            color: _statusColor(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.league,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite
                          ? const Color(0xFFFFC107)
                          : Colors.white54,
                      size: 22,
                    ),
                    onPressed: onFavorite,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _logo(match.homeLogo, match.homeTeam),
                        const SizedBox(height: 6),
                        Text(
                          match.homeTeam,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        live || match.status == MatchStatus.finished
                            ? match.scoreText
                            : match.time,
                        style: TextStyle(
                          fontSize:
                              live || match.status == MatchStatus.finished
                                  ? 24
                                  : 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        live || match.status == MatchStatus.finished
                            ? match.time
                            : 'بتوقيت القاهرة',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _logo(match.awayLogo, match.awayTeam),
                        const SizedBox(height: 6),
                        Text(
                          match.awayTeam,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.white.withOpacity(0.08)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tv, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      match.channel.isEmpty
                          ? 'القناة غير معروفة'
                          : match.channel,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.65),
                      ),
                    ),
                  ),
                  if (match.commentator.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(Icons.mic, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        match.commentator,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    match.hasStream
                        ? Icons.play_circle_fill
                        : Icons.schedule,
                    size: 16,
                    color: match.hasStream
                        ? const Color(0xFF931800)
                        : Colors.white38,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
