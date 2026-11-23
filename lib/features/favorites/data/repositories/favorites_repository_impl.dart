import 'package:wasl/core/storage/local_cache.dart';
import 'package:wasl/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDataSource _remote;
  FavoritesRepositoryImpl(this._remote);

  String get _key => 'favorites_${_remote.currentUserId ?? 'guest'}';

  @override
  Future<Set<String>> getKeys() async {
    try {
      final rows = await _remote.fetchMine();
      final keys = {for (final r in rows) '${r['item_type']}:${r['item_id']}'};
      await LocalCache.cache.put(_key, keys.toList());
      return keys;
    } catch (_) {
      final cached = LocalCache.cache.get(_key);
      return cached is List ? cached.map((e) => e.toString()).toSet() : <String>{};
    }
  }

  @override
  Future<bool> add(FavoriteType type, String id) => _ok(() => _remote.add(type.name, id));

  @override
  Future<bool> remove(FavoriteType type, String id) => _ok(() => _remote.remove(type.name, id));

  Future<bool> _ok(Future<void> Function() call) async {
    try {
      await call();
      return true;
    } catch (_) {
      return false;
    }
  }
}
