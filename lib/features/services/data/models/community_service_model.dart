import 'package:wasl/features/services/domain/entities/community_service.dart';

/// تحويل سطر من جدول services (مع اسم المؤسسة) لـ CommunityService.
class CommunityServiceModel {
  static CommunityService fromJson(Map<String, dynamic> j) {
    final org = (j['organizations'] as Map?) ?? const {};
    return CommunityService(
      id: j['id'] as String,
      name: (j['name'] as String?) ?? '',
      provider: (org['name'] as String?) ?? '',
      providerVerified: (org['is_verified'] as bool?) ?? false,
      category: (j['category'] as String?) ?? 'أخرى',
      description: (j['description'] as String?) ?? '',
      beneficiaries: (j['beneficiaries'] as String?) ?? '',
      region: (j['region'] as String?) ?? '',
      schedule: (j['schedule'] as String?) ?? '',
      howToBenefit: (j['how_to_benefit'] as String?) ?? '',
      status: ServiceStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => ServiceStatus.available,
      ),
      lastConfirmedAt: DateTime.tryParse((j['last_confirmed_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}
