import 'package:equatable/equatable.dart';
import 'package:wasl/features/applications/domain/entities/volunteer_application.dart';

/// طلب تطوع وصل للمؤسسة على وحدة من فرصها.
class OrgRequest extends Equatable {
  final String id;
  final String opportunityId;
  final String opportunityTitle;
  final String volunteerName;
  final String volunteerRegion;
  final List<String> skills; // المهارات اللي اختارها بالتقديم (أو من ملفه)
  final List<String> availableDays;
  final String bio;
  final String phone;
  final ApplicationStatus status;
  final DateTime createdAt;
  // الحضور والشهادة (للطلبات المقبولة)
  final double hours;
  final bool checkedIn; // سجّل دخول وما سجّل خروج
  final bool offersCertificate;
  final String? certificateCode;

  const OrgRequest({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.volunteerName,
    this.volunteerRegion = '',
    this.skills = const [],
    this.availableDays = const [],
    this.bio = '',
    this.phone = '',
    required this.status,
    required this.createdAt,
    this.hours = 0,
    this.checkedIn = false,
    this.offersCertificate = false,
    this.certificateCode,
  });

  bool get isPending => status == ApplicationStatus.pending;

  /// "سارة م." بدل الاسم الكامل بالقوائم
  String get shortName {
    final parts = volunteerName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'متطوع';
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${String.fromCharCode(parts[1].runes.first)}.';
  }

  @override
  List<Object?> get props => [id, status, hours, checkedIn, certificateCode];
}
