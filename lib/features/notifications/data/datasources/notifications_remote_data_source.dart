import 'package:supabase_flutter/supabase_flutter.dart';

/// الكلام المباشر مع جدول notifications (إشعاراتي بس، والحماية بتضمن هاد).
class NotificationsRemoteDataSource {
  final SupabaseClient _client;
  NotificationsRemoteDataSource(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchMine() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final rows = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markRead(String id) => _client.from('notifications').update({'is_read': true}).eq('id', id);

  Future<void> markAllRead() =>
      _client.from('notifications').update({'is_read': true}).eq('user_id', currentUserId!).eq('is_read', false);
}
