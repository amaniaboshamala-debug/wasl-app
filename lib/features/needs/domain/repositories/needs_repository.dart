import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';

abstract class NeedsRepository {
  /// الاحتياجات المفتوحة (من النت، أو من الكاش لما ما في نت).
  Future<Result<CachedList<Need>>> getOpen();
}
