import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع جدول initiatives.
class InitiativesRemoteDataSource {
  final SupabaseClient _client;
  InitiativesRemoteDataSource(this._client);

  /// المبادرات المفتوحة والجارية، الأقرب موعداً أول.
  Future<List<Map<String, dynamic>>> fetchOpen() async {
    final rows = await _client
        .from('initiatives')
        .select('*, organizations(name, is_verified)')
        .inFilter('status', ['published', 'active'])
        .order('start_date', ascending: true)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }
}
