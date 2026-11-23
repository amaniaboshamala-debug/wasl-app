import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/opportunities/data/datasources/opportunities_remote_data_source.dart';
import 'package:wasl/features/opportunities/data/models/opportunity_model.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/opportunities/domain/repositories/opportunities_repository.dart';

class OpportunitiesRepositoryImpl implements OpportunitiesRepository {
  final OpportunitiesRemoteDataSource _remote;
  OpportunitiesRepositoryImpl(this._remote);

  @override
  Future<Result<CachedList<Opportunity>>> getVisible() => fetchWithCache(
        cacheKey: 'opportunities_visible',
        remote: _remote.fetchVisible,
        parse: OpportunityModel.fromJson,
      );
}
