import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/initiatives/data/datasources/initiatives_remote_data_source.dart';
import 'package:wasl/features/initiatives/data/models/initiative_model.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/initiatives/domain/repositories/initiatives_repository.dart';

class InitiativesRepositoryImpl implements InitiativesRepository {
  final InitiativesRemoteDataSource _remote;
  InitiativesRepositoryImpl(this._remote);

  @override
  Future<Result<CachedList<Initiative>>> getOpen() => fetchWithCache(
        cacheKey: 'initiatives_open',
        remote: _remote.fetchOpen,
        parse: InitiativeModel.fromJson,
      );
}
