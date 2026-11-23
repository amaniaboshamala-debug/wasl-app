import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/storage/local_cache.dart';
import 'package:wasl/core/utils/result.dart';

/// قائمة جاية يا من النت، يا من الكاش (لما ما في نت).
class CachedList<T> {
  final List<T> items;
  final bool fromCache;
  final DateTime? savedAt;
  const CachedList(this.items, {this.fromCache = false, this.savedAt});
}

/// بنجيب من Supabase ونحفظ نسخة عالجوال.
/// إذا فشل النت، بنرجّع آخر نسخة محفوظة بدل ما نطلّع خطأ.
Future<Result<CachedList<T>>> fetchWithCache<T>({
  required String cacheKey,
  required Future<List<Map<String, dynamic>>> Function() remote,
  required T Function(Map<String, dynamic>) parse,
}) async {
  try {
    final rows = await remote();
    await LocalCache.saveList(cacheKey, rows);
    return Ok(CachedList(rows.map(parse).toList()));
  } catch (e) {
    final cached = LocalCache.readList(cacheKey);
    if (cached.isNotEmpty) {
      return Ok(CachedList(cached.map(parse).toList(), fromCache: true, savedAt: LocalCache.savedAt(cacheKey)));
    }
    if (e is PostgrestException) return Err(Failure('ما قدرنا نجيب البيانات: ${e.message}'));
    return const Err(Failure.network);
  }
}
