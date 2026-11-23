import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/features/needs/domain/entities/need.dart';
import 'package:wasl/features/needs/domain/repositories/needs_repository.dart';

/// قائمة الاحتياجات. وحدة بس بكل التطبيق، فالرئيسية واستكشف وتفاصيل المبادرة بيشاركوا نفس البيانات.
class NeedsCubit extends ListCubit<Need> {
  NeedsCubit(NeedsRepository repo) : super(repo.getOpen);
}
