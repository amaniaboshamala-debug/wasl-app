import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع جدول services.
class ServicesRemoteDataSource {
  final SupabaseClient _client;
  ServicesRemoteDataSource(this._client);

  /// كل الخدمات اللي لسا ما انتهت، والمؤكَّدة حديثاً أول.
  Future<List<Map<String, dynamic>>> fetchActive() async {
    final rows = await _client
        .from('services')
        .select('*, organizations(name, is_verified)')
        .neq('status', 'ended')
        .order('last_confirmed_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }
}
