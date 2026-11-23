import 'package:wasl/features/initiatives/domain/entities/initiative.dart';

/// تحويل سطر من جدول initiatives (مع اسم المؤسسة) لـ Initiative.
class InitiativeModel {
  static Initiative fromJson(Map<String, dynamic> j) {
    final org = (j['organizations'] as Map?) ?? const {};
    return Initiative(
      id: j['id'] as String,
      title: (j['title'] as String?) ?? '',
      description: (j['description'] as String?) ?? '',
      category: (j['category'] as String?) ?? 'أخرى',
      organizationId: (j['organization_id'] as String?) ?? '',
      organizationName: (org['name'] as String?) ?? '',
      organizationVerified: (org['is_verified'] as bool?) ?? false,
      region: (j['region'] as String?) ?? '',
      startDate: DateTime.tryParse((j['start_date'] as String?) ?? ''),
      endDate: DateTime.tryParse((j['end_date'] as String?) ?? ''),
      volunteersNeeded: (j['volunteers_needed'] as num?)?.toInt() ?? 0,
      skills: ((j['skills'] as List?) ?? const []).map((e) => e.toString()).toList(),
      imageUrl: j['image_url'] as String?,
      offersCertificate: (j['offers_certificate'] as bool?) ?? false,
      certificateIssuer: j['certificate_issuer'] as String?,
      status: InitiativeStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => InitiativeStatus.published,
      ),
    );
  }
}
