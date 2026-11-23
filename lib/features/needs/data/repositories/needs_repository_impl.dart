import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/needs/data/datasources/needs_remote_data_source.dart';
import 'package:wasl/features/needs/data/models/need_model.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';
import 'package:wasl/features/needs/domain/repositories/needs_repository.dart';

class NeedsRepositoryImpl implements NeedsRepository {
  final NeedsRemoteDataSource _remote;
  NeedsRepositoryImpl(this._remote);

  @override
  Future<Result<CachedList<Need>>> getOpen() async {
    final result = await fetchWithCache(
      cacheKey: 'needs_open',
      remote: _remote.fetchOpen,
      parse: NeedModel.fromJson,
    );
    // العاجل أول، وبعدين الأقل تغطية
    if (result case Ok(:final data)) {
      final sorted = [...data.items]..sort((a, b) {
          if (a.isUrgent != b.isUrgent) return a.isUrgent ? -1 : 1;
          return a.progress.compareTo(b.progress);
        });
      return Ok(CachedList(sorted, fromCache: data.fromCache, savedAt: data.savedAt));
    }
    return result;
  }
}
