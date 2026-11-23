import 'package:hive_flutter/hive_flutter.dart';

/// تخزين محلي للبيانات (للعمل مع النت الضعيف) وللمفضلة.
class LocalCache {
  static const _cacheBox = 'cache';
  static const _favoritesBox = 'favorites';

  static Future<void> init() async {
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_favoritesBox);
  }

  static Box get cache => Hive.box(_cacheBox);
  static Box get favorites => Hive.box(_favoritesBox);

  /// بنحفظ القائمة مع وقت آخر تحديث عشان نعرضه للمستخدم.
  static Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    await cache.put(key, {'items': items, 'savedAt': DateTime.now().toIso8601String()});
  }

  static List<Map<String, dynamic>> readList(String key) {
    final data = cache.get(key);
    if (data == null) return [];
    return (data['items'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static DateTime? savedAt(String key) {
    final data = cache.get(key);
    return data == null ? null : DateTime.tryParse(data['savedAt']);
  }
}
