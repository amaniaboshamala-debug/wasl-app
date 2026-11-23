import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';

abstract class OpportunitiesRepository {
  /// الفرص الظاهرة (من النت، أو من الكاش لما ما في نت).
  Future<Result<CachedList<Opportunity>>> getVisible();
}
