import 'dart:async';

import 'package:flutter/material.dart';

import '../models/match_model.dart';

/// Shared professional UI pieces for the Yalla Shoot app.
/// Brand: site red #931800, dark theme, Arabic RTL.

class AppColors {
  AppColors._();

  static const Color red = Color(0xFF931800);
  static const Color redBright = Color(0xFFC81E05);
  static const Color redDark = Color(0xFF4A0C00);
  static const Color background = Color(0xFF0E0E13);
  static const Color card = Color(0xFF1B1B24);
  static const Color gold = Color(0xFFFFC107);
  static const Color liveRed = Color(0xFFE53935);
  static const Color green = Color(0xFF2E9E5B);

  static const LinearGradient redGradient = LinearGradient(
    colors: [Color(0xFFC81E05), Color(0xFF931800)],
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
  );

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [Color(0xFFC81E05), Color(0xFF931800), Color(0xFF4A0C00)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFC81E05), Color(0xFF931800), Color(0xFF4A0C00)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// Human-readable status text / colour for a match, shared by every screen.
class MatchStatusLabel {
  MatchStatusLabel._();

  static String label(YallaMatch match) {
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

  static Color color(YallaMatch match) {
    switch (match.status) {
      case MatchStatus.live:
        return AppColors.liveRed;
      case MatchStatus.finished:
        return Colors.grey;
      case MatchStatus.upcoming:
        return AppColors.green;
      case MatchStatus.unknown:
        return Colors.grey;
    }
  }
}

/// A red dot that gently fades in and out, used for live matches.
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({
    super.key,
    this.color = AppColors.liveRed,
    this.size = 8,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.3).animate(_controller),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Rounded status pill, with a pulsing dot for live matches.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isLive;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.isLive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive) ...[
            const PulsingDot(),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Team logo on a clean white circular chip, with a letter fallback.
class TeamLogo extends StatelessWidget {
  final String url;
  final String name;
  final double size;

  const TeamLogo({
    super.key,
    required this.url,
    required this.name,
    this.size = 56,
  });

  Widget _fallback() {
    return Center(
      child: Text(
        name.isNotEmpty ? name.characters.first : '?',
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
          color: AppColors.red,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: url.isEmpty
            ? _fallback()
            : Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
      ),
    );
  }
}

/// Full-width red gradient call-to-action button.
class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.redGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.red.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Muted full-width label used when no stream is available yet.
/// It is a label, not a button, so it can never look like a dead button.
class MutedLabel extends StatelessWidget {
  final String text;

  const MutedLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, size: 19, color: Colors.white38),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _skeletonBar(double width, double height) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

/// Grey placeholder card shown while matches are loading.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _skeletonBar(90, 12),
              const Spacer(),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              _skeletonBar(64, 20),
              const Spacer(),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _skeletonBar(double.infinity, 12),
        ],
      ),
    );
  }
}

/// Format a countdown as HH:MM:SS, prefixed with days when 24h or more
/// away, e.g. "04:12:33" or "1d 04:12:33".
String formatCountdown(Duration remaining) {
  if (remaining.isNegative) remaining = Duration.zero;
  final totalSeconds = remaining.inSeconds;
  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  final hms = '${two(hours)}:${two(minutes)}:${two(seconds)}';
  return days > 0 ? '${days}d $hms' : hms;
}

/// Live ticking countdown to kickoff, updating every second.
/// Only this small text rebuilds each tick — never the whole list.
/// When kickoff passes the timer stops and the widget disappears,
/// so the match status takes its place.
class KickoffCountdown extends StatefulWidget {
  final DateTime kickoffLocal;
  final TextStyle? style;

  const KickoffCountdown({
    super.key,
    required this.kickoffLocal,
    this.style,
  });

  @override
  State<KickoffCountdown> createState() => _KickoffCountdownState();
}

class _KickoffCountdownState extends State<KickoffCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  @override
  void didUpdateWidget(KickoffCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kickoffLocal != widget.kickoffLocal) {
      _timer?.cancel();
      _update();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
    }
  }

  void _update() {
    final remaining = widget.kickoffLocal.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      _timer = null;
      if (mounted) setState(() => _remaining = Duration.zero);
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= Duration.zero) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_outlined, size: 19, color: AppColors.gold),
        const SizedBox(width: 5),
        Text(
          formatCountdown(_remaining),
          style: widget.style ??
              const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
        ),
      ],
    );
  }
}
