import 'package:flutter/material.dart';

import '../models/match_model.dart';
import 'ui_kit.dart';

class MatchCard extends StatelessWidget {
  final YallaMatch match;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  /// Opens the in-app player. Falls back to [onTap] (match details,
  /// which also has a Watch button) when not provided.
  final VoidCallback? onWatch;

  const MatchCard({
    super.key,
    required this.match,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    final live = match.status == MatchStatus.live;
    final showScore =
        live || match.status == MatchStatus.finished;
    return Card(
      color: AppColors.card,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: live
              ? AppColors.red.withOpacity(0.7)
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
                  StatusPill(
                    label: MatchStatusLabel.label(match),
                    color: MatchStatusLabel.color(match),
                    isLive: live,
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
                          ? AppColors.gold
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
                        TeamLogo(
                          url: match.homeLogo,
                          name: match.homeTeam,
                          size: 56,
                        ),
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
                        showScore ? match.scoreText : match.time,
                        style: TextStyle(
                          fontSize: showScore ? 28 : 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        showScore ? match.time : 'بتوقيت القاهرة',
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
                        TeamLogo(
                          url: match.awayLogo,
                          name: match.awayTeam,
                          size: 56,
                        ),
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
                ],
              ),
              const SizedBox(height: 10),
              if (match.hasStream)
                GradientButton(
                  label: 'شاهد الآن',
                  icon: Icons.play_arrow,
                  onPressed: onWatch ?? onTap,
                )
              else
                const MutedLabel(text: 'البث غير متاح بعد'),
            ],
          ),
        ),
      ),
    );
  }
}
