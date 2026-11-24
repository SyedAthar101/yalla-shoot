import 'dart:async';

import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/favorites_service.dart';
import '../services/yalla_api.dart';
import '../widgets/match_card.dart';
import '../widgets/ui_kit.dart';
import 'match_detail_screen.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final List<String> _days = ['today', 'tomorrow', 'yesterday'];
  final List<String> _dayLabels = [
    'مباريات اليوم',
    'مباريات الغد',
    'مباريات الأمس',
  ];
  final Map<String, List<YallaMatch>> _cache = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _error = {};
  Set<String> _favorites = {};
  String _query = '';
  String _leagueFilter = 'الكل';
  bool _favoritesOnly = false;
  bool _liveOnly = false;
  bool _searching = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      _load(_days[_tabs.index]);
      setState(() {});
    });
    FavoritesService.load().then((v) => setState(() => _favorites = v));
    _load('today');
    // Auto-refresh live scores every 60 seconds.
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _load(_days[_tabs.index], silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load(String day, {bool silent = false}) async {
    if (!silent) setState(() => _loading[day] = true);
    _error[day] = null;
    try {
      final matches = await YallaApi.fetchMatches(day);
      if (!mounted) return;
      setState(() {
        _cache[day] = matches;
        _loading[day] = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading[day] = false;
        _error[day] = 'تعذر تحميل المباريات — اسحب للتحديث';
      });
    }
  }

  List<YallaMatch> _visible(String day) {
    var list = _cache[day] ?? [];
    if (_favoritesOnly) {
      list = list.where((m) => _favorites.contains(m.id)).toList();
    }
    if (_liveOnly) {
      list = list.where((m) => m.status == MatchStatus.live).toList();
    }
    if (_leagueFilter != 'الكل') {
      list = list.where((m) => m.league == _leagueFilter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim();
      list = list
          .where((m) =>
              m.homeTeam.contains(q) ||
              m.awayTeam.contains(q) ||
              m.league.contains(q) ||
              m.channel.contains(q))
          .toList();
    }
    // Live first, then by time.
    list = List.of(list);
    list.sort((a, b) {
      final aLive = a.status == MatchStatus.live ? 0 : 1;
      final bLive = b.status == MatchStatus.live ? 0 : 1;
      if (aLive != bLive) return aLive.compareTo(bLive);
      return a.time.compareTo(b.time);
    });
    return list;
  }

  Future<void> _toggleFavorite(YallaMatch m) async {
    final isFav = !_favorites.contains(m.id);
    setState(() {
      if (isFav) {
        _favorites.add(m.id);
      } else {
        _favorites.remove(m.id);
      }
    });
    await FavoritesService.toggle(m.id, isFav);
  }

  void _openDetail(YallaMatch m) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchDetailScreen(
          match: m,
          isFavorite: _favorites.contains(m.id),
          onFavorite: () => _toggleFavorite(m),
        ),
      ),
    );
  }

  void _openPlayer(YallaMatch m) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(match: m),
      ),
    );
  }

  Widget _loadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      itemCount: 5,
      itemBuilder: (_, __) => const SkeletonCard(),
    );
  }

  Widget _pillTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final selected = _tabs.index == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => _tabs.animateTo(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.redGradient : null,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _dayLabels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          selected ? Colors.white : Colors.white60,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _filterRow(List<String> leagues) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _liveOnly
                        ? Colors.white
                        : AppColors.liveRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'مباشر فقط',
                  style: TextStyle(
                    color: _liveOnly ? Colors.white : Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            selected: _liveOnly,
            selectedColor: AppColors.red,
            backgroundColor: AppColors.card,
            onSelected: (_) => setState(() => _liveOnly = !_liveOnly),
          ),
          const SizedBox(width: 8),
          ...leagues.map(
            (league) {
              final selected = _leagueFilter == league;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(league,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 12)),
                  selected: selected,
                  selectedColor: AppColors.red,
                  backgroundColor: AppColors.card,
                  onSelected: (_) =>
                      setState(() => _leagueFilter = league),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _liveFeatured(List<YallaMatch> live) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const PulsingDot(size: 10),
              const SizedBox(width: 8),
              const Text(
                'مباشر الآن',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${live.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 216,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: live.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = live[i];
              return _LiveFeaturedCard(
                match: m,
                onTap: () => _openDetail(m),
                onWatch: () => _openPlayer(m),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _leagueGroups(List<YallaMatch> matches) {
    final groups = <String, List<YallaMatch>>{};
    for (final m in matches) {
      final key = m.league.isEmpty ? 'بطولات أخرى' : m.league;
      groups.putIfAbsent(key, () => []).add(m);
    }
    final out = <Widget>[];
    for (final entry in groups.entries) {
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.value.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      out.addAll(
        entry.value.map(
          (m) => MatchCard(
            match: m,
            isFavorite: _favorites.contains(m.id),
            onTap: () => _openDetail(m),
            onFavorite: () => _toggleFavorite(m),
            onWatch: () => _openPlayer(m),
          ),
        ),
      );
    }
    return out;
  }

  Widget _dayView(String day) {
    final loading = _loading[day] == true && (_cache[day]?.isEmpty ?? true);
    final matches = _visible(day);
    final leagues = <String>{
      'الكل',
      ...(_cache[day] ?? []).map((m) => m.league).where((l) => l.isNotEmpty)
    }.toList();
    final liveMatches =
        matches.where((m) => m.status == MatchStatus.live).toList();

    if (loading) {
      return _loadingSkeleton();
    }
    if (_error[day] != null && (_cache[day]?.isEmpty ?? true)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Colors.white38),
            const SizedBox(height: 10),
            Text(_error[day]!,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _load(day),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red),
              child: const Text('إعادة المحاولة',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (matches.isEmpty) {
      return Center(
        child: Text(
          _favoritesOnly
              ? 'لا توجد مباريات مفضلة هنا بعد'
              : _liveOnly
                  ? 'لا توجد مباريات مباشرة الآن'
                  : 'لا توجد مباريات في هذا اليوم',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.red,
      onRefresh: () => _load(day),
      child: ListView(
        children: [
          if (liveMatches.isNotEmpty) _liveFeatured(liveMatches),
          _filterRow(leagues),
          ..._leagueGroups(matches),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'المصدر: yallah.media — يتم التحديث تلقائياً كل دقيقة',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 11),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = _days[_tabs.index];
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
        title: _searching
            ? TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن فريق أو بطولة...',
                  hintStyle: TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('يلا شوت',
                          style: TextStyle(
                              fontSize: 19, fontWeight: FontWeight.bold)),
                      Text('Yalla Shoot — مباريات اليوم بث مباشر',
                          style: TextStyle(
                              fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _query = '';
            }),
          ),
          IconButton(
            icon: Icon(_favoritesOnly ? Icons.star : Icons.star_border,
                color:
                    _favoritesOnly ? AppColors.gold : Colors.white),
            onPressed: () =>
                setState(() => _favoritesOnly = !_favoritesOnly),
            tooltip: 'المفضلة',
          ),
        ],
      ),
      body: Column(
        children: [
          _pillTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: _days.map(_dayView).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        onPressed: () => _load(day),
        tooltip: 'تحديث',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

/// Horizontal featured card for a live match.
class _LiveFeaturedCard extends StatelessWidget {
  final YallaMatch match;
  final VoidCallback onTap;
  final VoidCallback onWatch;

  const _LiveFeaturedCard({
    required this.match,
    required this.onTap,
    required this.onWatch,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.red.withOpacity(0.7),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: MatchStatusLabel.label(match),
                      color: MatchStatusLabel.color(match),
                      isLive: true,
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
                            size: 52,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            match.homeTeam,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          match.scoreText,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          match.time,
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
                            size: 52,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            match.awayTeam,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (match.hasStream)
                  GradientButton(
                    label: 'شاهد الآن',
                    icon: Icons.play_arrow,
                    onPressed: onWatch,
                    height: 40,
                  )
                else
                  const MutedLabel(text: 'البث غير متاح بعد'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
