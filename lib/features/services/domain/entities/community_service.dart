import 'package:equatable/equatable.dart';

enum ServiceStatus { available, limited, paused, ended }

/// اسمها CommunityService عشان ما تتلخبط مع كلمة Service بالكود.
class CommunityService extends Equatable {
  final String id;
  final String name;
  final String provider;
  final bool providerVerified;
  final String category;
  final String description;
  final String beneficiaries;
  final String region;
  final String schedule;
  final String howToBenefit;
  final ServiceStatus status;
  final DateTime lastConfirmedAt; // آخر مرة أكدت المؤسسة إنها متاحة

  const CommunityService({
    required this.id,
    required this.name,
    required this.provider,
    this.providerVerified = false,
    required this.category,
    required this.description,
    required this.beneficiaries,
    required this.region,
    required this.schedule,
    required this.howToBenefit,
    required this.status,
    required this.lastConfirmedAt,
  });

  String get statusLabel => switch (status) {
        ServiceStatus.available => 'متاحة',
        ServiceStatus.limited => 'محدودة',
        ServiceStatus.paused => 'متوقفة مؤقتاً',
        ServiceStatus.ended => 'انتهت',
      };

  /// إذا عدّى أسبوع بدون تأكيد، بننبّه الناس قبل ما يروحوا.
  bool get needsConfirmation => DateTime.now().difference(lastConfirmedAt).inDays >= 7;

  @override
  List<Object?> get props => [id, status, lastConfirmedAt];
}
