import 'package:supabase_flutter/supabase_flutter.dart';

/// بلاغ من الناس على منشور.
class AdminReport {
  final String id;
  final String itemType;
  final String itemId;
  final String reason;
  final String reporterName;
  final DateTime createdAt;
  const AdminReport({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.reason,
    required this.reporterName,
    required this.createdAt,
  });

  String get itemTypeLabel => switch (itemType) {
        'initiative' => 'مبادرة',
        'service' => 'خدمة',
        'opportunity' => 'فرصة',
        'need' => 'احتياج',
        _ => itemType,
      };
}

/// لوحة الإدارة: توثيق المؤسسات، مراجعة المبادرات، والبلاغات.
/// كل العمليات بدوال على السيرفر بتفحص إنك admin.
class AdminRepository {
  final SupabaseClient _client;
  AdminRepository(this._client);

  /// المؤسسات (غير الموثّقة أول).
  Future<List<Map<String, dynamic>>> organizations() async => List<Map<String, dynamic>>.from(await _client
      .from('organizations')
      .select('id, name, bio, region, contact, is_verified, created_at')
      .order('is_verified', ascending: true)
      .order('created_at', ascending: false));

  Future<List<Map<String, dynamic>>> pendingInitiatives() async => List<Map<String, dynamic>>.from(await _client
      .from('initiatives')
      .select('*, organizations(name, is_verified)')
      .eq('status', 'pending')
      .order('created_at', ascending: true));

  Future<List<AdminReport>> openReports() async {
    final rows = await _client
        .from('reports')
        .select('*, profiles(full_name)')
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return [
      for (final r in rows)
        AdminReport(
          id: r['id'] as String,
          itemType: (r['item_type'] as String?) ?? '',
          itemId: (r['item_id'] as String?) ?? '',
          reason: (r['reason'] as String?) ?? '',
          reporterName: ((r['profiles'] as Map?)?['full_name'] as String?) ?? '',
          createdAt: DateTime.tryParse((r['created_at'] as String?) ?? '')?.toLocal() ?? DateTime.now(),
        ),
    ];
  }

  Future<void> verifyOrg(String id, bool verified) =>
      _client.rpc('admin_verify_org', params: {'p_org_id': id, 'p_verified': verified});

  Future<void> setInitiativeStatus(String id, String status) =>
      _client.rpc('admin_set_initiative_status', params: {'p_initiative_id': id, 'p_status': status});

  Future<void> resolveReport(String id) => _client.from('reports').update({'status': 'resolved'}).eq('id', id);
}
