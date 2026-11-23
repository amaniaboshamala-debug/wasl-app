import 'package:supabase_flutter/supabase_flutter.dart';

/// البلاغات: أي حدا بيقدر يبلّغ عن منشور، والإدارة بتشوفها.
class ReportsRepository {
  final SupabaseClient _client;
  ReportsRepository(this._client);

  static const reasons = [
    'طلب فلوس أو تبرعات مالية',
    'معلومات غلط أو مضلّلة',
    'مؤسسة أو جهة مش حقيقية',
    'محتوى مسيء',
    'شي تاني',
  ];

  /// null = انبعت.
  Future<String?> report({required String itemType, required String itemId, required String reason}) async {
    try {
      await _client.from('reports').insert({
        'reporter_id': _client.auth.currentUser!.id,
        'item_type': itemType,
        'item_id': itemId,
        'reason': reason,
      });
      return null;
    } catch (_) {
      return 'ما قدرنا نبعت البلاغ، حاولي مرة تانية.';
    }
  }
}
