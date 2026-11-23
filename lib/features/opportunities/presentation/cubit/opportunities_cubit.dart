import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';
import 'package:wasl/features/opportunities/domain/repositories/opportunities_repository.dart';

/// قائمة الفرص. وحدة بس بكل التطبيق.
class OpportunitiesCubit extends ListCubit<Opportunity> {
  OpportunitiesCubit(OpportunitiesRepository repo) : super(repo.getVisible);
}
