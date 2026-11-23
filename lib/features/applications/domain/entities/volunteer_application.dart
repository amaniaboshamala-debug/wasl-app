import 'package:equatable/equatable.dart';

enum ApplicationStatus { pending, accepted, rejected, withdrawn }

/// طلب تطوع قدّمه المتطوع على فرصة.
class VolunteerApplication extends Equatable {
  final String id;
  final String opportunityId;
  final String opportunityTitle;
  final String organizationName;
  final String place;
  final DateTime? date; // موعد الفرصة
  final String bio; // ليش حابب يتطوع (اختياري)
  final List<String> availableDays;
  final List<String> skills;
  final ApplicationStatus status;
  final DateTime createdAt;

  const VolunteerApplication({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    this.organizationName = '',
    this.place = '',
    this.date,
    this.bio = '',
    this.availableDays = const [],
    this.skills = const [],
    required this.status,
    required this.createdAt,
  });

  String get statusLabel => switch (status) {
        ApplicationStatus.pending => 'قيد المراجعة',
        ApplicationStatus.accepted => 'مقبول',
        ApplicationStatus.rejected => 'لم يُقبل',
        ApplicationStatus.withdrawn => 'انسحبتِ',
      };

  /// الطلب "شغّال" إذا لسا قيد المراجعة أو مقبول.
  bool get isActive => status == ApplicationStatus.pending || status == ApplicationStatus.accepted;

  bool get canWithdraw => isActive;

  @override
  List<Object?> get props => [id, status, createdAt];
}
