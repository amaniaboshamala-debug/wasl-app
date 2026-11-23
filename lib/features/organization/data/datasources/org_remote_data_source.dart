import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع Supabase للوحة المؤسسة.
class OrgRemoteDataSource {
  final SupabaseClient _client;
  OrgRemoteDataSource(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  /// مؤسستي (أول وحدة بملكها الحساب)، أو null إذا لسا ما انعملت.
  Future<Map<String, dynamic>?> fetchMyOrg() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return _client
        .from('organizations')
        .select()
        .eq('owner_id', uid)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> createOrg({
    required String name,
    required String bio,
    required String region,
    required String contact,
  }) =>
      _client
          .from('organizations')
          .insert({'owner_id': currentUserId, 'name': name, 'bio': bio, 'region': region, 'contact': contact})
          .select()
          .single();

  Future<Map<String, dynamic>> updateOrg(String id, Map<String, dynamic> values) =>
      _client.from('organizations').update(values).eq('id', id).select().single();

  /// فرص المؤسسة كلها (مفتوحة ومسكّرة)، مع حالة الطلبات عليها.
  Future<List<Map<String, dynamic>>> fetchOrgOpportunities(String orgId) async {
    final rows = await _client
        .from('opportunities')
        .select('*, organizations(name, is_verified), applications(status)')
        .eq('organization_id', orgId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createOpportunity(Map<String, dynamic> row) => _client.from('opportunities').insert(row);

  Future<void> setOpportunityStatus(String id, String status) =>
      _client.from('opportunities').update({'status': status}).eq('id', id);

  /// الطلبات على فرص المؤسسة. الحماية (RLS) أصلاً ما بتورجي غير طلبات فرصك.
  Future<List<Map<String, dynamic>>> fetchRequests(String orgId) async {
    final rows = await _client
        .from('applications')
        .select('*, profiles(full_name, region, skills), opportunities!inner(title, organization_id, offers_certificate), '
            'attendance(hours, approved, check_in_at, check_out_at), certificates(code)')
        .eq('opportunities.organization_id', orgId)
        .neq('status', 'withdrawn')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ===== المبادرات والاحتياجات =====
  Future<List<Map<String, dynamic>>> fetchOrgInitiatives(String orgId) async {
    final rows = await _client
        .from('initiatives')
        .select('*, organizations(name, is_verified), needs(*, need_offers(*, profiles(full_name, region)))')
        .eq('organization_id', orgId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createInitiative(Map<String, dynamic> row) => _client.from('initiatives').insert(row);

  Future<void> setInitiativeStatus(String id, String status) =>
      _client.from('initiatives').update({'status': status}).eq('id', id);

  Future<void> createNeed(Map<String, dynamic> row) => _client.from('needs').insert(row);

  Future<void> closeNeed(String id) => _client.from('needs').update({'status': 'closed'}).eq('id', id);

  Future<void> decideOffer(String offerId, bool received) =>
      _client.rpc('decide_need_offer', params: {'p_offer_id': offerId, 'p_received': received});

  // ===== الخدمات =====
  Future<List<Map<String, dynamic>>> fetchOrgServices(String orgId) async {
    final rows = await _client
        .from('services')
        .select('*, organizations(name, is_verified)')
        .eq('organization_id', orgId)
        .order('last_confirmed_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createService(Map<String, dynamic> row) => _client.from('services').insert(row);

  Future<void> updateService(String id, Map<String, dynamic> values) =>
      _client.from('services').update(values).eq('id', id);

  Future<void> decide(String applicationId, bool accept) =>
      _client.rpc('decide_application', params: {'p_application_id': applicationId, 'p_accept': accept});
}
