import 'package:equatable/equatable.dart';

/// تطوع بدون مقابل · عمل مؤقت بأجر · تطوع مع بدل (مواصلات مثلاً)
/// الدفع (إذا في) بيتفق عليه مع المؤسسة برّا التطبيق، ووَصْل ما بيستقبل ولا بيحوّل أموال.
enum OpportunityType { volunteer, paid, volunteerAllowance }

enum OpportunityStatus { open, full, expired, closed }

class Opportunity extends Equatable {
  final String id;
  final String title;
  final String tasks;
  final String organizationId;
  final String organizationName;
  final bool organizationVerified;
  final String? initiativeId;
  final String location; // المكان بالتفصيل: "مدرسة الرمال"
  final String region; // المنطقة: "مدينة غزة"
  final DateTime? date;
  final String duration;
  final DateTime? applyDeadline;
  final int volunteersNeeded;
  final int acceptedCount;
  final List<String> skills;
  final OpportunityType type;
  final String? compensation; // "50 ₪ يومياً"، "بدل مواصلات"
  final bool isRemote;
  final OpportunityStatus status;
  final bool offersCertificate; // بياخد المتطوع شهادة تطوع مصدّقة؟
  final String? certificateIssuer; // مين بيصدّقها (اختياري)

  const Opportunity({
    required this.id,
    required this.title,
    required this.tasks,
    required this.organizationId,
    required this.organizationName,
    this.organizationVerified = false,
    this.initiativeId,
    required this.location,
    required this.region,
    this.date,
    required this.duration,
    this.applyDeadline,
    required this.volunteersNeeded,
    this.acceptedCount = 0,
    required this.skills,
    this.type = OpportunityType.volunteer,
    this.compensation,
    this.isRemote = false,
    this.status = OpportunityStatus.open,
    this.offersCertificate = false,
    this.certificateIssuer,
  });

  /// "شهادة تطوع مصدّقة" أو "شهادة مصدّقة من وزارة التنمية"
  String get certificateLabel => certificateIssuer?.trim().isNotEmpty == true
      ? 'شهادة مصدّقة من ${certificateIssuer!.trim()}'
      : 'شهادة تطوع مصدّقة';

  int get seatsLeft => (volunteersNeeded - acceptedCount).clamp(0, volunteersNeeded);

  bool get isOpen => status == OpportunityStatus.open && seatsLeft > 0;

  bool get isPaid => type != OpportunityType.volunteer;

  /// "تطوع بدون مقابل"، "عمل بأجر · 50 ₪ يومياً"، "تطوع + بدل مواصلات"
  String get typeLabel => switch (type) {
        OpportunityType.volunteer => 'تطوع بدون مقابل',
        OpportunityType.paid => compensation?.isNotEmpty == true ? 'عمل بأجر · $compensation' : 'عمل بأجر',
        OpportunityType.volunteerAllowance =>
          compensation?.isNotEmpty == true ? 'تطوع + $compensation' : 'تطوع مع بدل',
      };

  /// "باقي مقعد واحد"، "باقي مقعدان"، "باقي 4 مقاعد"، "اكتمل العدد"
  String get seatsLabel {
    if (status == OpportunityStatus.expired) return 'انتهى التقديم';
    if (status == OpportunityStatus.closed) return 'مغلقة';
    final n = seatsLeft;
    if (n == 0) return 'اكتمل العدد';
    if (n == 1) return 'باقي مقعد واحد';
    if (n == 2) return 'باقي مقعدان';
    if (n <= 10) return 'باقي $n مقاعد';
    return 'باقي $n مقعد';
  }

  String get placeLabel => isRemote ? 'عن بُعد' : (region.isNotEmpty ? region : location);

  @override
  List<Object?> get props => [id, status, acceptedCount];
}
