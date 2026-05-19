import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedService {
  static const _key = 'recently_viewed';
  static const _max = 10;

  static Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).map(int.parse).toList();
  }

  static Future<void> add(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = (prefs.getStringList(_key) ?? []).map(int.parse).toList();
    list.remove(productId);
    list.insert(0, productId);
    if (list.length > _max) list.removeLast();
    await prefs.setStringList(_key, list.map((e) => e.toString()).toList());
  }
}
