import 'dart:async';

import 'package:flutter/material.dart';

import '../models/match_model.dart';
import '../services/favorites_service.dart';
import '../services/yalla_api.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final List<String> _days = ['today', 'tomorrow', 'yesterday'];
  final Map<String, List<YallaMatch>> _cache = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _error = {};
  Set<String> _favorites = {};
  String _query = '';
  String _leagueFilter = 'الكل';
  bool _favoritesOnly = false;
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

  Widget _dayView(String day) {
    final loading = _loading[day] == true && (_cache[day]?.isEmpty ?? true);
    final matches = _visible(day);
    final leagues = <String>{
      'الكل',
      ...(_cache[day] ?? []).map((m) => m.league).where((l) => l.isNotEmpty)
    }.toList();

    if (loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF931800)));
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
                  backgroundColor: const Color(0xFF931800)),
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
              : 'لا توجد مباريات في هذا اليوم',
          style: TextStyle(color: Colors.white.withOpacity(0.6)),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF931800),
      onRefresh: () => _load(day),
      child: ListView(
        children: [
          if (leagues.length > 2)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: leagues.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final league = leagues[i];
                  final selected = _leagueFilter == league;
                  return ChoiceChip(
                    label: Text(league,
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 12)),
                    selected: selected,
                    selectedColor: const Color(0xFF931800),
                    backgroundColor: const Color(0xFF1B1B24),
                    onSelected: (_) =>
                        setState(() => _leagueFilter = league),
                  );
                },
              ),
            ),
          ...matches.map(
            (m) => MatchCard(
              match: m,
              isFavorite: _favorites.contains(m.id),
              onTap: () => _openDetail(m),
              onFavorite: () => _toggleFavorite(m),
            ),
          ),
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
      backgroundColor: const Color(0xFF0E0E13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF931800),
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
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('⚽',
                          style: TextStyle(fontSize: 18)),
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
                color: _favoritesOnly
                    ? const Color(0xFFFFC107)
                    : Colors.white),
            onPressed: () =>
                setState(() => _favoritesOnly = !_favoritesOnly),
            tooltip: 'المفضلة',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFFFFC107),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'مباريات اليوم'),
            Tab(text: 'مباريات الغد'),
            Tab(text: 'مباريات الأمس'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: _days.map(_dayView).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF931800),
        foregroundColor: Colors.white,
        onPressed: () => _load(day),
        tooltip: 'تحديث',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
