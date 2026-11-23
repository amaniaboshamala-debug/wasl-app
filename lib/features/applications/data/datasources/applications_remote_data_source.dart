import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع جدول applications.
/// التقديم والانسحاب بيمرّوا من دوال على السيرفر (RPC) عشان القواعد تنفحص هناك.
class ApplicationsRemoteDataSource {
  final SupabaseClient _client;
  ApplicationsRemoteDataSource(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _client
        .from('applications')
        .select('*, opportunities(title, location, region, is_remote, date, organizations(name))')
        .eq('volunteer_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> apply({
    required String opportunityId,
    String? bio,
    List<String> availableDays = const [],
    List<String> skills = const [],
    String? phone,
  }) =>
      _client.rpc('apply_to_opportunity', params: {
        'p_opportunity_id': opportunityId,
        'p_bio': (bio?.trim().isEmpty ?? true) ? null : bio!.trim(),
        'p_available_days': availableDays,
        'p_skills': skills,
        'p_phone': phone?.trim(),
      });

  Future<void> withdraw(String applicationId) =>
      _client.rpc('withdraw_application', params: {'p_application_id': applicationId});
}
