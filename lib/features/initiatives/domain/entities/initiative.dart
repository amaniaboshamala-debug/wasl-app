import 'package:equatable/equatable.dart';

enum InitiativeStatus { pending, published, active, completed, cancelled }

class Initiative extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category; // تعليمية، صحية، بيئية...
  final String organizationId;
  final String organizationName;
  final bool organizationVerified;
  final String region;
  final DateTime? startDate;
  final DateTime? endDate;
  final int volunteersNeeded;
  final List<String> skills;
  final String? imageUrl;
  final InitiativeStatus status;
  final bool offersCertificate;
  final String? certificateIssuer;

  const Initiative({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.organizationId,
    required this.organizationName,
    this.organizationVerified = false,
    required this.region,
    this.startDate,
    this.endDate,
    required this.volunteersNeeded,
    required this.skills,
    this.imageUrl,
    required this.status,
    this.offersCertificate = false,
    this.certificateIssuer,
  });

  String get certificateLabel => certificateIssuer?.trim().isNotEmpty == true
      ? 'شهادة مصدّقة من ${certificateIssuer!.trim()}'
      : 'شهادة تطوع مصدّقة';

  /// "التسجيل مفتوح" لما تكون منشورة ولسا ما بلّشت، أو شغّالة.
  String get statusLabel => switch (status) {
        InitiativeStatus.published => 'التسجيل مفتوح',
        InitiativeStatus.active => 'جارية الآن',
        InitiativeStatus.completed => 'انتهت',
        InitiativeStatus.cancelled => 'ملغاة',
        InitiativeStatus.pending => 'قيد المراجعة',
      };

  @override
  List<Object?> get props => [id, status, title];
}
