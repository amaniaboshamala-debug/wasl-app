import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع جدول profiles (الملف الشخصي تبعي بس).
class ProfileRemoteDataSource {
  final SupabaseClient _client;
  ProfileRemoteDataSource(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>?> fetchMine() async {
    final uid = currentUserId;
    if (uid == null) return null;
    return _client
        .from('profiles')
        .select('id, full_name, region, skills, phone, bio')
        .eq('id', uid)
        .maybeSingle();
  }

  Future<Map<String, dynamic>> update(Map<String, dynamic> values) => _client
      .from('profiles')
      .update(values)
      .eq('id', currentUserId!)
      .select('id, full_name, region, skills, phone, bio')
      .single();
}
