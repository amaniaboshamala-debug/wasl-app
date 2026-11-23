import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/presentation/list_cubit.dart';
import 'package:wasl/features/organization/domain/entities/org_initiative.dart';
import 'package:wasl/features/organization/domain/entities/org_opportunity.dart';
import 'package:wasl/features/organization/domain/entities/org_request.dart';
import 'package:wasl/features/organization/domain/repositories/org_repository.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';

/// فرص المؤسسة + النشر والتسكير.
class OrgOpportunitiesCubit extends ListCubit<OrgOpportunity> {
  final OrgRepository _repo;
  OrgOpportunitiesCubit(this._repo) : super(_repo.getOpportunities);

  /// بيرجّع رسالة الخطأ، أو null إذا نجح.
  Future<String?> create(NewOpportunityInput input) async {
    final f = await _repo.createOpportunity(input);
    if (f == null) await refresh();
    return f?.message;
  }

  Future<String?> setOpen(String id, bool open) async {
    final f = await _repo.setOpportunityOpen(id, open);
    if (f == null) await refresh();
    return f?.message;
  }
}

/// الطلبات على فرص المؤسسة + القبول والرفض.
class OrgRequestsCubit extends ListCubit<OrgRequest> {
  final OrgRepository _repo;
  OrgRequestsCubit(this._repo) : super(_repo.getRequests);

  int get pendingCount => items.where((r) => r.isPending).length;

  Future<String?> decide(String applicationId, {required bool accept}) async {
    final f = await _repo.decide(applicationId, accept: accept);
    if (f == null) await refresh();
    return f?.message;
  }
}

/// مبادرات المؤسسة واحتياجاتها وعروض المساعدة عليها.
class OrgInitiativesCubit extends ListCubit<OrgInitiative> {
  final OrgRepository _repo;
  OrgInitiativesCubit(this._repo) : super(_repo.getInitiatives);

  int get pendingOffers => items.fold(0, (sum, i) => sum + i.pendingOffers);

  Future<String?> _after(Future<Failure?> call) async {
    final f = await call;
    if (f == null) await refresh();
    return f?.message;
  }

  Future<String?> create(NewInitiativeInput input) => _after(_repo.createInitiative(input));
  Future<String?> setStatus(String id, String status) => _after(_repo.setInitiativeStatus(id, status));
  Future<String?> addNeed({required String initiativeId, required String type, String description = '', required int quantity}) =>
      _after(_repo.addNeed(initiativeId: initiativeId, type: type, description: description, quantity: quantity));
  Future<String?> closeNeed(String needId) => _after(_repo.closeNeed(needId));
  Future<String?> decideOffer(String offerId, {required bool received}) =>
      _after(_repo.decideOffer(offerId, received: received));
}

/// خدمات المؤسسة: نشر، تأكيد إنها لسا متاحة، وتغيير الحالة.
class OrgServicesCubit extends ListCubit<CommunityService> {
  final OrgRepository _repo;
  OrgServicesCubit(this._repo) : super(_repo.getServices);

  Future<String?> _after(Future<Failure?> call) async {
    final f = await call;
    if (f == null) await refresh();
    return f?.message;
  }

  Future<String?> create(NewServiceInput input) => _after(_repo.createService(input));
  Future<String?> confirm(String id) => _after(_repo.confirmService(id));
  Future<String?> setStatus(String id, ServiceStatus status) => _after(_repo.setServiceStatus(id, status));
}
