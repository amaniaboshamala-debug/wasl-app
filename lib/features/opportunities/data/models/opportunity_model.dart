import 'package:wasl/features/opportunities/domain/entities/opportunity.dart';

/// تحويل سطر من جدول opportunities (مع اسم المؤسسة) لـ Opportunity.
class OpportunityModel {
  static const _types = {
    'volunteer': OpportunityType.volunteer,
    'paid': OpportunityType.paid,
    'volunteer_allowance': OpportunityType.volunteerAllowance,
  };

  static Opportunity fromJson(Map<String, dynamic> j) {
    final org = (j['organizations'] as Map?) ?? const {};
    return Opportunity(
      id: j['id'] as String,
      title: (j['title'] as String?) ?? '',
      tasks: (j['tasks'] as String?) ?? '',
      organizationId: (j['organization_id'] as String?) ?? '',
      organizationName: (org['name'] as String?) ?? '',
      organizationVerified: (org['is_verified'] as bool?) ?? false,
      initiativeId: j['initiative_id'] as String?,
      location: (j['location'] as String?) ?? '',
      region: (j['region'] as String?) ?? '',
      date: DateTime.tryParse((j['date'] as String?) ?? '')?.toLocal(),
      duration: (j['duration'] as String?) ?? '',
      applyDeadline: DateTime.tryParse((j['apply_deadline'] as String?) ?? ''),
      volunteersNeeded: (j['volunteers_needed'] as num?)?.toInt() ?? 1,
      acceptedCount: (j['accepted_count'] as num?)?.toInt() ?? 0,
      skills: ((j['skills'] as List?) ?? const []).map((e) => e.toString()).toList(),
      type: _types[j['type']] ?? OpportunityType.volunteer,
      compensation: j['compensation'] as String?,
      isRemote: (j['is_remote'] as bool?) ?? false,
      offersCertificate: (j['offers_certificate'] as bool?) ?? false,
      certificateIssuer: j['certificate_issuer'] as String?,
      status: OpportunityStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => OpportunityStatus.open,
      ),
    );
  }
}
