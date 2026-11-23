import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع جدول needs.
class NeedsRemoteDataSource {
  final SupabaseClient _client;
  NeedsRemoteDataSource(this._client);

  /// الاحتياجات اللي لسا مش مغلقة، مع اسم المبادرة ومنطقتها والمؤسسة.
  Future<List<Map<String, dynamic>>> fetchOpen() async {
    final rows = await _client
        .from('needs')
        .select('*, initiatives(id, title, region, organizations(name))')
        .neq('status', 'closed')
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }
}
