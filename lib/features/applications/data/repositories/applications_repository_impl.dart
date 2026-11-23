import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/applications/data/datasources/applications_remote_data_source.dart';
import 'package:wasl/features/applications/data/models/application_model.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/domain/repositories/applications_repository.dart';

class ApplicationsRepositoryImpl implements ApplicationsRepository {
  final ApplicationsRemoteDataSource _remote;
  ApplicationsRepositoryImpl(this._remote);

  @override
  Future<Result<CachedList<VolunteerApplication>>> getMine() => fetchWithCache(
        // كل حساب إله نسخة محفوظة لحاله، عشان ما تبين طلبات حدا تاني على نفس الجوال
        cacheKey: 'my_applications_${_remote.currentUserId ?? 'guest'}',
        remote: _remote.fetchMine,
        parse: ApplicationModel.fromJson,
      );

  @override
  Future<Failure?> apply({
    required String opportunityId,
    String? bio,
    List<String> availableDays = const [],
    List<String> skills = const [],
    String? phone,
  }) =>
      _try(() => _remote.apply(
            opportunityId: opportunityId,
            bio: bio,
            availableDays: availableDays,
            skills: skills,
            phone: phone,
          ));

  @override
  Future<Failure?> withdraw(String applicationId) => _try(() => _remote.withdraw(applicationId));

  Future<Failure?> _try(Future<void> Function() call) async {
    try {
      await call();
      return null;
    } on PostgrestException catch (e) {
      return Failure(arabicApplicationError(e.message));
    } catch (_) {
      return Failure.network;
    }
  }
}

/// رسائل الأخطاء اللي بترجع من دوال السيرفر، بالعربي.
String arabicApplicationError(String msg) {
  if (msg.contains('only_volunteers')) return 'التقديم على الفرص للمتطوعين بس.';
  if (msg.contains('opportunity_closed')) return 'الفرصة سكّرت أو اكتمل عددها.';
  if (msg.contains('opportunity_not_found')) return 'ما لقينا هاي الفرصة، ممكن تكون انحذفت.';
  if (msg.contains('already_applied')) return 'قدّمتِ على هاي الفرصة قبل.';
  if (msg.contains('cannot_withdraw')) return 'ما بنقدر نسحب هاد الطلب.';
  if (msg.contains('not_signed_in')) return 'لازم تسجّلي دخول أول.';
  return 'صار خطأ، حاولي مرة تانية.';
}
