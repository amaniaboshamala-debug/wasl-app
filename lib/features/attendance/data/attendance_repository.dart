import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasl/features/attendance/domain/volunteer_record.dart';

/// خطأ برسالة عربية جاهزة للعرض.
class AttendanceException implements Exception {
  final String message;
  const AttendanceException(this.message);
  @override
  String toString() => message;
}

/// الحضور والساعات والشهادات. كل الكتابة بدوال على السيرفر بتفحص الصلاحيات.
class AttendanceRepository {
  final SupabaseClient _client;
  AttendanceRepository(this._client);

  static String arabicError(Object e) {
    final m = e is PostgrestException ? e.message : e.toString();
    if (m.contains('not_your_opportunity')) return 'هاد المتطوع مش على وحدة من فرصك.';
    if (m.contains('not_accepted')) return 'الطلب لسا مش مقبول.';
    if (m.contains('application_not_found')) return 'الكود مش معروف.';
    if (m.contains('just_checked_in')) return 'سجّل دخول هلّق، استني شوي قبل الخروج.';
    if (m.contains('invalid_hours')) return 'عدد الساعات لازم يكون بين 0.5 و 24.';
    if (m.contains('no_certificate_offered')) return 'هاي الفرصة ما فيها شهادة.';
    if (m.contains('no_hours_yet')) return 'سجّلي ساعات أول، بعدين بتطلع الشهادة.';
    if (e is PostgrestException) return 'صار خطأ، حاولي مرة تانية.';
    return 'لا يوجد اتصال بالإنترنت';
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (e) {
      throw AttendanceException(arabicError(e));
    }
  }

  Future<ScanResult> scan(String applicationId) => _guard(() async {
        final res = await _client.rpc('scan_attendance', params: {'p_application_id': applicationId});
        return ScanResult.fromJson(Map<String, dynamic>.from(res as Map));
      });

  Future<void> recordHours(String applicationId, double hours) => _guard(
      () => _client.rpc('record_hours', params: {'p_application_id': applicationId, 'p_hours': hours}));

  /// بيرجّع كود الشهادة
  Future<String> issueCertificate(String applicationId) => _guard(() async {
        final code = await _client.rpc('issue_certificate', params: {'p_application_id': applicationId});
        return code as String;
      });

  Future<VolunteerRecord> myRecord() => _guard(() async {
        final uid = _client.auth.currentUser!.id;
        final apps = await _client
            .from('applications')
            .select('id, opportunity_id, opportunities(title, type, date, organizations(name)), attendance(hours, approved)')
            .eq('volunteer_id', uid)
            .eq('status', 'accepted');
        final certs = await _client
            .from('certificates')
            .select()
            .eq('volunteer_id', uid)
            .order('issued_at', ascending: false);
        return VolunteerRecord.fromRows(List<Map<String, dynamic>>.from(apps), List<Map<String, dynamic>>.from(certs));
      });

  /// null = الكود مش موجود
  Future<Map<String, dynamic>?> verify(String code) => _guard(() async {
        final res = await _client.rpc('verify_certificate', params: {'p_code': code});
        return res == null ? null : Map<String, dynamic>.from(res as Map);
      });
}
