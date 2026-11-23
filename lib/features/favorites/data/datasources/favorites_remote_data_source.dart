import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع جدول favorites (مفضلتي بس).
class FavoritesRemoteDataSource {
  final SupabaseClient _client;
  FavoritesRemoteDataSource(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _client.from('favorites').select('item_type, item_id').eq('user_id', uid);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> add(String type, String id) =>
      _client.from('favorites').upsert({'user_id': currentUserId, 'item_type': type, 'item_id': id});

  Future<void> remove(String type, String id) => _client
      .from('favorites')
      .delete()
      .eq('user_id', currentUserId!)
      .eq('item_type', type)
      .eq('item_id', id);
}
