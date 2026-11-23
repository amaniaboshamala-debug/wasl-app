import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/features/initiatives/domain/entities/initiative.dart';
import 'package:wasl/features/initiatives/domain/repositories/initiatives_repository.dart';

/// قائمة المبادرات. وحدة بس بكل التطبيق، فالرئيسية واستكشف بيشاركوا نفس البيانات.
class InitiativesCubit extends ListCubit<Initiative> {
  InitiativesCubit(InitiativesRepository repo) : super(repo.getOpen);
}
