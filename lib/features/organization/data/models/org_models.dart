import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';
import 'package:wasl/features/initiatives/data/models/initiative_model.dart';
import 'package:wasl/features/needs/data/models/need_model.dart';
import 'package:wasl/features/opportunities/data/models/opportunity_model.dart';
import 'package:wasl/features/organization/domain/entities/org_initiative.dart';
import 'package:wasl/features/organization/domain/entities/org_opportunity.dart';
import 'package:wasl/features/organization/domain/entities/org_request.dart';
import 'package:wasl/features/organization/domain/entities/organization.dart';

/// تحويل البيانات اللي جاية من Supabase لكلاسات لوحة المؤسسة.
class OrgModels {
  static Organization organization(Map<String, dynamic> j) => Organization(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        bio: (j['bio'] as String?) ?? '',
        region: (j['region'] as String?) ?? '',
        contact: (j['contact'] as String?) ?? '',
        isVerified: (j['is_verified'] as bool?) ?? false,
      );

  /// فرصة مع applications(status) المضمّنة، بنعدّ منها اللي قيد المراجعة.
  static OrgOpportunity opportunity(Map<String, dynamic> j) {
    final apps = (j['applications'] as List?) ?? const [];
    final pending = apps.where((a) => a is Map && a['status'] == 'pending').length;
    return OrgOpportunity(OpportunityModel.fromJson(j), pendingCount: pending);
  }

  /// مبادرة مع needs(*, need_offers(*, profiles(...))) المضمّنة.
  static OrgInitiative initiative(Map<String, dynamic> j) {
    final initiative = InitiativeModel.fromJson(j);
    final needs = ((j['needs'] as List?) ?? const []).whereType<Map>().map((raw) {
      final n = Map<String, dynamic>.from(raw);
      // NeedModel بيستنى اسم المبادرة ومنطقتها تحت 'initiatives'
      final need = NeedModel.fromJson({
        ...n,
        'initiatives': {'id': initiative.id, 'title': initiative.title, 'region': initiative.region},
      });
      final offers = ((n['need_offers'] as List?) ?? const []).whereType<Map>().map((o) => needOffer(Map<String, dynamic>.from(o))).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return OrgNeed(need, offers: offers);
    }).toList();
    return OrgInitiative(initiative, needs: needs);
  }

  static NeedOffer needOffer(Map<String, dynamic> j) {
    final p = (j['profiles'] as Map?) ?? const {};
    return NeedOffer(
      id: j['id'] as String,
      userName: (p['full_name'] as String?) ?? '',
      userRegion: (p['region'] as String?) ?? '',
      quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      note: (j['note'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      status: NeedOfferStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => NeedOfferStatus.pending),
      createdAt: DateTime.tryParse((j['created_at'] as String?) ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  static OrgRequest request(Map<String, dynamic> j) {
    final profile = (j['profiles'] as Map?) ?? const {};
    final opp = (j['opportunities'] as Map?) ?? const {};
    List<String> list(Object? v) => ((v as List?) ?? const []).map((e) => e.toString()).toList();
    final chosen = list(j['skills']);
    final attendance = ((j['attendance'] as List?) ?? const []).cast<Map>();
    final certs = ((j['certificates'] as List?) ?? const []).cast<Map>();
    return OrgRequest(
      id: j['id'] as String,
      opportunityId: (j['opportunity_id'] as String?) ?? '',
      opportunityTitle: (opp['title'] as String?) ?? '',
      volunteerName: (profile['full_name'] as String?) ?? '',
      volunteerRegion: (profile['region'] as String?) ?? '',
      skills: chosen.isNotEmpty ? chosen : list(profile['skills']),
      availableDays: list(j['available_days']),
      bio: (j['bio'] as String?) ?? '',
      phone: (j['phone'] as String?) ?? '',
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      createdAt: DateTime.tryParse((j['created_at'] as String?) ?? '')?.toLocal() ?? DateTime.now(),
      hours: attendance
          .where((a) => a['approved'] == true)
          .fold(0.0, (s, a) => s + ((a['hours'] as num?)?.toDouble() ?? 0)),
      checkedIn: attendance.any((a) => a['check_in_at'] != null && a['check_out_at'] == null),
      offersCertificate: (opp['offers_certificate'] as bool?) ?? false,
      certificateCode: certs.isEmpty ? null : certs.first['code'] as String?,
    );
  }
}
