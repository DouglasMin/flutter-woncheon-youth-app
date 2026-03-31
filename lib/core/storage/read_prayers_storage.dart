import 'package:shared_preferences/shared_preferences.dart';

class ReadPrayersStorage {
  static const _key = 'read_prayer_ids';

  Future<Set<String>> getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.toSet();
  }

  Future<void> markAsRead(String prayerId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final set = list.toSet()..add(prayerId);
    await prefs.setStringList(_key, set.toList());
  }

  Future<bool> isRead(String prayerId) async {
    final ids = await getReadIds();
    return ids.contains(prayerId);
  }
}
