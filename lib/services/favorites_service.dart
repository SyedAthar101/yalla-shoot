import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const _key = 'yalla_favorite_match_ids';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key)?.toSet() ?? <String>{};
  }

  static Future<void> toggle(String matchId, bool isFav) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key)?.toSet() ?? <String>{};
    if (isFav) {
      current.add(matchId);
    } else {
      current.remove(matchId);
    }
    await prefs.setStringList(_key, current.toList());
  }
}
