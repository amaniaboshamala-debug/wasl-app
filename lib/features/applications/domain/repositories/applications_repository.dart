import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';

abstract class ApplicationsRepository {
  /// طلباتي (من النت، أو من الكاش لما ما في نت).
  Future<Result<CachedList<VolunteerApplication>>> getMine();

  /// null = انبعت الطلب تمام.
  Future<Failure?> apply({
    required String opportunityId,
    String? bio,
    List<String> availableDays,
    List<String> skills,
    String? phone,
  });

  /// null = انسحب تمام.
  Future<Failure?> withdraw(String applicationId);
}
