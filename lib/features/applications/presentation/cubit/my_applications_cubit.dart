import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/applications/domain/repositories/applications_repository.dart';

/// طلباتي + التقديم والانسحاب. بعد أي تغيير بنحدّث القائمة.
class MyApplicationsCubit extends ListCubit<VolunteerApplication> {
  final ApplicationsRepository _repo;
  MyApplicationsCubit(this._repo) : super(_repo.getMine);

  /// بيرجّع رسالة الخطأ، أو null إذا انبعت.
  Future<String?> apply({
    required String opportunityId,
    String? bio,
    List<String> availableDays = const [],
    List<String> skills = const [],
    String? phone,
  }) async {
    final failure = await _repo.apply(
      opportunityId: opportunityId,
      bio: bio,
      availableDays: availableDays,
      skills: skills,
      phone: phone,
    );
    if (failure == null) await refresh();
    return failure?.message;
  }

  Future<String?> withdraw(String applicationId) async {
    final failure = await _repo.withdraw(applicationId);
    if (failure == null) await refresh();
    return failure?.message;
  }

  /// طلبي على فرصة معيّنة (إذا في)، بنستخدمه لزر "قدّمي" بصفحة الفرصة.
  VolunteerApplication? forOpportunity(String opportunityId) {
    for (final a in items) {
      if (a.opportunityId == opportunityId) return a;
    }
    return null;
  }
}
