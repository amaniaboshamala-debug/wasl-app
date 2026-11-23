import 'package:equatable/equatable.dart';

/// فرصة تطوّع فيها المتطوع (طلب مقبول) مع ساعاتها.
class RecordEntry extends Equatable {
  final String applicationId;
  final String opportunityId;
  final String title;
  final String orgName;
  final String type; // volunteer · paid · volunteer_allowance
  final DateTime? date;
  final double hours;

  const RecordEntry({
    required this.applicationId,
    required this.opportunityId,
    required this.title,
    this.orgName = '',
    this.type = 'volunteer',
    this.date,
    this.hours = 0,
  });

  bool get done => hours > 0;

  @override
  List<Object?> get props => [applicationId, hours];
}

/// شهادة تطوع مصدّقة من مؤسسة.
class VolunteerCertificate extends Equatable {
  final String code;
  final String title;
  final String orgName;
  final String issuer;
  final String volunteerName;
  final double hours;
  final DateTime issuedAt;

  const VolunteerCertificate({
    required this.code,
    required this.title,
    required this.orgName,
    this.issuer = '',
    this.volunteerName = '',
    required this.hours,
    required this.issuedAt,
  });

  /// الجهة اللي بتصدّق: إذا المؤسسة حددت جهة (جامعة مثلاً) وإلا المؤسسة نفسها
  String get issuedBy => issuer.isNotEmpty ? issuer : orgName;

  @override
  List<Object?> get props => [code, hours];
}

/// شارة: بتنكسب لحالها مع التقدّم.
class AchievementBadge extends Equatable {
  final String emoji;
  final String title;
  final String hint; // كيف بتنكسب
  final bool earned;
  final double progress; // 0..1

  const AchievementBadge(this.emoji, this.title, this.hint, {required this.earned, required this.progress});

  @override
  List<Object?> get props => [title, earned];
}

/// سجل التطوع: كل الفرص والساعات والشهادات والشارات.
class VolunteerRecord extends Equatable {
  final List<RecordEntry> entries;
  final List<VolunteerCertificate> certificates;

  const VolunteerRecord({this.entries = const [], this.certificates = const []});

  double get totalHours => entries.fold(0.0, (s, e) => s + e.hours);
  List<RecordEntry> get done => entries.where((e) => e.done).toList();
  int get orgCount => done.map((e) => e.orgName).where((n) => n.isNotEmpty).toSet().length;

  static String formatHours(double h) => h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1);

  List<AchievementBadge> get badges {
    final h = totalHours;
    final n = done.length;
    double p(num v, num goal) => (v / goal).clamp(0, 1).toDouble();
    return [
      AchievementBadge('🌱', 'أول خطوة', 'أول فرصة تطوع بساعات مسجّلة', earned: n >= 1, progress: p(n, 1)),
      AchievementBadge('⏱️', '10 ساعات', 'وصّلي 10 ساعات تطوع', earned: h >= 10, progress: p(h, 10)),
      AchievementBadge('💪', '50 ساعة', 'وصّلي 50 ساعة تطوع', earned: h >= 50, progress: p(h, 50)),
      AchievementBadge('🏅', '100 ساعة', 'وصّلي 100 ساعة تطوع', earned: h >= 100, progress: p(h, 100)),
      AchievementBadge('🤝', 'إيد بإيد', 'تطوّعي بـ 5 فرص', earned: n >= 5, progress: p(n, 5)),
      AchievementBadge('🏢', 'صديقة المؤسسات', 'تطوّعي مع 3 مؤسسات مختلفة', earned: orgCount >= 3, progress: p(orgCount, 3)),
      AchievementBadge('📜', 'موثّقة', 'احصلي على أول شهادة مصدّقة',
          earned: certificates.isNotEmpty, progress: certificates.isEmpty ? 0 : 1),
    ];
  }

  int get earnedCount => badges.where((b) => b.earned).length;

  /// من نتيجة Supabase: الطلبات المقبولة (مع الفرصة والحضور) + الشهادات
  factory VolunteerRecord.fromRows(List<Map<String, dynamic>> apps, List<Map<String, dynamic>> certs) {
    double num0(Object? v) => (v as num?)?.toDouble() ?? 0;
    final entries = <RecordEntry>[
      for (final a in apps)
        () {
          final opp = (a['opportunities'] as Map?) ?? const {};
          final org = (opp['organizations'] as Map?) ?? const {};
          final att = ((a['attendance'] as List?) ?? const []).cast<Map>();
          return RecordEntry(
            applicationId: a['id'] as String,
            opportunityId: (a['opportunity_id'] as String?) ?? '',
            title: (opp['title'] as String?) ?? '',
            orgName: (org['name'] as String?) ?? '',
            type: (opp['type'] as String?) ?? 'volunteer',
            date: DateTime.tryParse((opp['date'] as String?) ?? '')?.toLocal(),
            hours: att.where((t) => t['approved'] == true).fold(0.0, (s, t) => s + num0(t['hours'])),
          );
        }(),
    ]..sort((x, y) => (y.date ?? DateTime(2000)).compareTo(x.date ?? DateTime(2000)));
    return VolunteerRecord(
      entries: entries,
      certificates: [
        for (final c in certs)
          VolunteerCertificate(
            code: (c['code'] as String?) ?? '',
            title: (c['title'] as String?) ?? '',
            orgName: (c['org_name'] as String?) ?? '',
            issuer: (c['issuer'] as String?) ?? '',
            volunteerName: (c['volunteer_name'] as String?) ?? '',
            hours: num0(c['hours']),
            issuedAt: DateTime.tryParse((c['issued_at'] as String?) ?? '')?.toLocal() ?? DateTime.now(),
          ),
      ],
    );
  }

  @override
  List<Object?> get props => [entries, certificates];
}

/// نتيجة مسح QR الحضور.
class ScanResult {
  final bool checkedIn; // true = دخول، false = خروج
  final String name;
  final String opportunity;
  final double hours;
  const ScanResult({required this.checkedIn, required this.name, required this.opportunity, this.hours = 0});

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        checkedIn: j['action'] == 'in',
        name: (j['name'] as String?) ?? '',
        opportunity: (j['opportunity'] as String?) ?? '',
        hours: (j['hours'] as num?)?.toDouble() ?? 0,
      );
}

/// شو مكتوب جوّا الـ QR: wasl-att:<رقم الطلب>
class AttendanceQr {
  static const prefix = 'wasl-att:';
  static String encode(String applicationId) => '$prefix$applicationId';

  /// بيرجّع رقم الطلب، أو null إذا الكود مش من وَصْل
  static String? decode(String? raw) {
    if (raw == null || !raw.startsWith(prefix)) return null;
    final id = raw.substring(prefix.length).trim();
    return RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(id) ? id : null;
  }
}
