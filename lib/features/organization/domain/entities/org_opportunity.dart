import 'package:equatable/equatable.dart';
import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';

/// فرصة من فرص المؤسسة، مع عدد الطلبات اللي لسا بتستنى مراجعة.
class OrgOpportunity extends Equatable {
  final Opportunity opportunity;
  final int pendingCount;
  const OrgOpportunity(this.opportunity, {this.pendingCount = 0});

  @override
  List<Object?> get props => [opportunity, pendingCount];
}
