import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع جدول opportunities.
class OpportunitiesRemoteDataSource {
  final SupabaseClient _client;
  OpportunitiesRemoteDataSource(this._client);

  /// الفرص المفتوحة والمكتملة، الأقرب موعد تقديم أول.
  Future<List<Map<String, dynamic>>> fetchVisible() async {
    final rows = await _client
        .from('opportunities')
        .select('*, organizations(name, is_verified)')
        .inFilter('status', ['open', 'full'])
        .order('apply_deadline', ascending: true)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }
}
