import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'search_history';
  static const _max = 5;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<List<String>> add(String query) async {
    if (query.trim().isEmpty) return load();
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(query);
    list.insert(0, query);
    final trimmed = list.take(_max).toList();
    await prefs.setStringList(_key, trimmed);
    return trimmed;
  }

  static Future<List<String>> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    list.remove(query);
    await prefs.setStringList(_key, list);
    return list;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
