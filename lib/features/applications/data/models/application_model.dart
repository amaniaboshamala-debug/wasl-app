import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';

/// تحويل سطر من جدول applications (مع الفرصة والمؤسسة) لـ VolunteerApplication.
class ApplicationModel {
  static VolunteerApplication fromJson(Map<String, dynamic> j) {
    final opp = (j['opportunities'] as Map?) ?? const {};
    final org = (opp['organizations'] as Map?) ?? const {};
    final isRemote = (opp['is_remote'] as bool?) ?? false;
    final region = (opp['region'] as String?) ?? '';
    final location = (opp['location'] as String?) ?? '';
    return VolunteerApplication(
      id: j['id'] as String,
      opportunityId: (j['opportunity_id'] as String?) ?? '',
      opportunityTitle: (opp['title'] as String?) ?? '',
      organizationName: (org['name'] as String?) ?? '',
      place: isRemote ? 'عن بُعد' : (region.isNotEmpty ? region : location),
      date: DateTime.tryParse((opp['date'] as String?) ?? '')?.toLocal(),
      bio: (j['bio'] as String?) ?? '',
      availableDays: ((j['available_days'] as List?) ?? const []).map((e) => e.toString()).toList(),
      skills: ((j['skills'] as List?) ?? const []).map((e) => e.toString()).toList(),
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == j['status'],
        orElse: () => ApplicationStatus.pending,
      ),
      createdAt: DateTime.tryParse((j['created_at'] as String?) ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
