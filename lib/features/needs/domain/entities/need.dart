import 'package:equatable/equatable.dart';

enum NeedStatus { open, partiallyCovered, fullyCovered, closed }

class Need extends Equatable {
  final String id;
  final String initiativeId;
  final String initiativeTitle;
  final String type; // أدوات، أجهزة، متطوعين...
  final String description;
  final int quantityNeeded;
  final int quantityProvided;
  final String region;
  final String organizationName;
  final NeedStatus status;

  const Need({
    required this.id,
    required this.initiativeId,
    required this.initiativeTitle,
    required this.type,
    required this.description,
    required this.quantityNeeded,
    required this.quantityProvided,
    required this.region,
    required this.organizationName,
    required this.status,
  });

  double get progress => quantityNeeded == 0 ? 0 : quantityProvided / quantityNeeded;

  /// الاحتياج عاجل إذا لسا أقل من نصه متوفّر.
  bool get isUrgent => status == NeedStatus.open || (status == NeedStatus.partiallyCovered && progress < 0.5);

  String get statusLabel => switch (status) {
        NeedStatus.open => 'مطلوب',
        NeedStatus.partiallyCovered => 'متوفّر جزئياً',
        NeedStatus.fullyCovered => 'اكتمل',
        NeedStatus.closed => 'مغلق',
      };

  @override
  List<Object?> get props => [id, quantityProvided, status];
}
