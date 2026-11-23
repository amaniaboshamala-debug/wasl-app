import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';

abstract class ServicesRepository {
  /// الخدمات المتاحة (من النت، أو من الكاش لما ما في نت).
  Future<Result<CachedList<CommunityService>>> getActive();
}
