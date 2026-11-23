import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/storage/local_cache.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/organization/data/datasources/org_remote_data_source.dart';
import 'package:wasl/features/organization/data/models/org_models.dart';
import 'package:wasl/features/organization/domain/entities/org_initiative.dart';
import 'package:wasl/features/organization/domain/entities/org_opportunity.dart';
import 'package:wasl/features/services/data/models/community_service_model.dart';
import 'package:wasl/features/services/domain/entities/community_service.dart';
import 'package:wasl/features/organization/domain/entities/org_request.dart';
import 'package:wasl/features/organization/domain/entities/organization.dart';
import 'package:wasl/features/organization/domain/repositories/org_repository.dart';

class OrgRepositoryImpl implements OrgRepository {
  final OrgRemoteDataSource _remote;
  OrgRepositoryImpl(this._remote);

  String get _uid => _remote.currentUserId ?? 'guest';
  String get _orgKey => 'my_org_$_uid';

  @override
  Future<Result<Organization?>> getMyOrg() async {
    try {
      final row = await _remote.fetchMyOrg();
      if (row == null) {
        await LocalCache.cache.delete(_orgKey);
        return const Ok(null);
      }
      await LocalCache.cache.put(_orgKey, row);
      return Ok(OrgModels.organization(row));
    } catch (e) {
      // بدون نت: آخر نسخة محفوظة
      final cached = LocalCache.cache.get(_orgKey);
      if (cached is Map) return Ok(OrgModels.organization(Map<String, dynamic>.from(cached)));
      return Err(_failure(e));
    }
  }

  @override
  Future<Result<Organization>> createOrg({
    required String name,
    String bio = '',
    String region = '',
    String contact = '',
  }) async {
    try {
      final row = await _remote.createOrg(name: name.trim(), bio: bio.trim(), region: region, contact: contact.trim());
      await LocalCache.cache.put(_orgKey, row);
      return Ok(OrgModels.organization(row));
    } catch (e) {
      return Err(_failure(e));
    }
  }

  @override
  Future<Result<Organization>> updateOrg({
    required String name,
    String bio = '',
    String region = '',
    String contact = '',
  }) async {
    final id = await _orgId();
    if (id == null) return const Err(Failure('ما لقينا مؤسستك.'));
    try {
      final row = await _remote.updateOrg(id, {
        'name': name.trim(),
        'bio': bio.trim(),
        'region': region,
        'contact': contact.trim(),
      });
      await LocalCache.cache.put(_orgKey, row);
      return Ok(OrgModels.organization(row));
    } catch (e) {
      return Err(_failure(e));
    }
  }

  /// رقم المؤسسة (من الكاش أو من النت).
  Future<String?> _orgId() async {
    final cached = LocalCache.cache.get(_orgKey);
    if (cached is Map && cached['id'] is String) return cached['id'] as String;
    final r = await getMyOrg();
    return r is Ok<Organization?> ? r.data?.id : null;
  }

  @override
  Future<Result<CachedList<OrgOpportunity>>> getOpportunities() async {
    final orgId = await _orgId();
    if (orgId == null) return const Ok(CachedList([]));
    return fetchWithCache(
      cacheKey: 'org_opportunities_$orgId',
      remote: () => _remote.fetchOrgOpportunities(orgId),
      parse: OrgModels.opportunity,
    );
  }

  @override
  Future<Failure?> createOpportunity(NewOpportunityInput i) async {
    final orgId = await _orgId();
    if (orgId == null) return const Failure('لازم تعملي مؤسستك أول.');
    final day = DateFormat('yyyy-MM-dd');
    return _try(() => _remote.createOpportunity({
          'organization_id': orgId,
          'title': i.title.trim(),
          'tasks': i.tasks.trim(),
          'type': i.type,
          'compensation': i.type == 'volunteer' ? null : i.compensation?.trim(),
          'is_remote': i.isRemote,
          'region': i.isRemote ? null : i.region,
          'location': i.isRemote ? 'عن بُعد' : i.location.trim(),
          'date': i.date?.toUtc().toIso8601String(),
          'duration': i.duration.trim(),
          'apply_deadline': i.applyDeadline == null ? null : day.format(i.applyDeadline!),
          'volunteers_needed': i.volunteersNeeded,
          'skills': i.skills,
          'offers_certificate': i.offersCertificate,
          'certificate_issuer': i.offersCertificate && (i.certificateIssuer?.trim().isNotEmpty ?? false)
              ? i.certificateIssuer!.trim()
              : null,
          'status': 'open',
        }));
  }

  @override
  Future<Failure?> setOpportunityOpen(String id, bool open) =>
      _try(() => _remote.setOpportunityStatus(id, open ? 'open' : 'closed'));

  // ===== المبادرات والاحتياجات =====
  @override
  Future<Result<CachedList<OrgInitiative>>> getInitiatives() async {
    final orgId = await _orgId();
    if (orgId == null) return const Ok(CachedList([]));
    return fetchWithCache(
      cacheKey: 'org_initiatives_$orgId',
      remote: () => _remote.fetchOrgInitiatives(orgId),
      parse: OrgModels.initiative,
    );
  }

  @override
  Future<Failure?> createInitiative(NewInitiativeInput i) async {
    final orgId = await _orgId();
    if (orgId == null) return const Failure('لازم تعملي مؤسستك أول.');
    final day = DateFormat('yyyy-MM-dd');
    return _try(() => _remote.createInitiative({
          'organization_id': orgId,
          'title': i.title.trim(),
          'description': i.description.trim(),
          'category': i.category,
          'region': i.region,
          'start_date': i.startDate == null ? null : day.format(i.startDate!),
          'end_date': i.endDate == null ? null : day.format(i.endDate!),
          'volunteers_needed': i.volunteersNeeded,
          'skills': i.skills,
          'offers_certificate': i.offersCertificate,
          'certificate_issuer': i.offersCertificate && (i.certificateIssuer?.trim().isNotEmpty ?? false)
              ? i.certificateIssuer!.trim()
              : null,
        }));
  }

  @override
  Future<Failure?> setInitiativeStatus(String id, String status) => _try(() => _remote.setInitiativeStatus(id, status));

  @override
  Future<Failure?> addNeed({
    required String initiativeId,
    required String type,
    String description = '',
    required int quantity,
  }) =>
      _try(() => _remote.createNeed({
            'initiative_id': initiativeId,
            'type': type.trim(),
            'description': description.trim(),
            'quantity_needed': quantity,
            'quantity_provided': 0,
            'status': 'open',
          }));

  @override
  Future<Failure?> closeNeed(String needId) => _try(() => _remote.closeNeed(needId));

  @override
  Future<Failure?> decideOffer(String offerId, {required bool received}) =>
      _try(() => _remote.decideOffer(offerId, received));

  // ===== الخدمات =====
  @override
  Future<Result<CachedList<CommunityService>>> getServices() async {
    final orgId = await _orgId();
    if (orgId == null) return const Ok(CachedList([]));
    return fetchWithCache(
      cacheKey: 'org_services_$orgId',
      remote: () => _remote.fetchOrgServices(orgId),
      parse: CommunityServiceModel.fromJson,
    );
  }

  @override
  Future<Failure?> createService(NewServiceInput i) async {
    final orgId = await _orgId();
    if (orgId == null) return const Failure('لازم تعملي مؤسستك أول.');
    return _try(() => _remote.createService({
          'organization_id': orgId,
          'name': i.name.trim(),
          'category': i.category,
          'description': i.description.trim(),
          'beneficiaries': i.beneficiaries.trim(),
          'region': i.region,
          'schedule': i.schedule.trim(),
          'how_to_benefit': i.howToBenefit.trim(),
          'status': 'available',
          'last_confirmed_at': DateTime.now().toUtc().toIso8601String(),
        }));
  }

  @override
  Future<Failure?> confirmService(String id) =>
      _try(() => _remote.updateService(id, {'last_confirmed_at': DateTime.now().toUtc().toIso8601String()}));

  @override
  Future<Failure?> setServiceStatus(String id, ServiceStatus status) => _try(() => _remote.updateService(id, {
        'status': status.name,
        'last_confirmed_at': DateTime.now().toUtc().toIso8601String(),
      }));

  @override
  Future<Result<CachedList<OrgRequest>>> getRequests() async {
    final orgId = await _orgId();
    if (orgId == null) return const Ok(CachedList([]));
    return fetchWithCache(
      cacheKey: 'org_requests_$orgId',
      remote: () => _remote.fetchRequests(orgId),
      parse: OrgModels.request,
    );
  }

  @override
  Future<Failure?> decide(String applicationId, {required bool accept}) =>
      _try(() => _remote.decide(applicationId, accept));

  Future<Failure?> _try(Future<void> Function() call) async {
    try {
      await call();
      return null;
    } catch (e) {
      return _failure(e);
    }
  }

  Failure _failure(Object e) {
    if (e is PostgrestException) return Failure(arabicOrgError(e.message));
    return Failure.network;
  }
}

/// رسائل أخطاء لوحة المؤسسة بالعربي.
String arabicOrgError(String msg) {
  if (msg.contains('opportunity_full')) return 'اكتمل عدد المتطوعين على هاي الفرصة.';
  if (msg.contains('volunteer_withdrew')) return 'المتطوع انسحب من هاد الطلب.';
  if (msg.contains('not_your_opportunity')) return 'هاي الفرصة مش تبعت مؤسستك.';
  if (msg.contains('application_not_found')) return 'ما لقينا هاد الطلب.';
  if (msg.contains('row-level security')) return 'ما عندك صلاحية تعملي هاد.';
  if (msg.contains('initiative_needs_review')) return 'المبادرة لسا عند فريق وَصْل للمراجعة.';
  if (msg.contains('not_your_need')) return 'هاد الاحتياج مش تبع مؤسستك.';
  return 'صار خطأ، حاولي مرة تانية.';
}
