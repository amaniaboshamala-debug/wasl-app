import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';

abstract class InitiativesRepository {
  /// المبادرات المفتوحة (من النت، أو من الكاش لما ما في نت).
  Future<Result<CachedList<Initiative>>> getOpen();
}
