import 'package:supabase_flutter/supabase_flutter.dart';

/// "بقدر أوفّر هاد": بيبعت عرض مساعدة عينية على احتياج (عن طريق دالة على السيرفر).
class NeedOffersRepository {
  final SupabaseClient _client;
  NeedOffersRepository(this._client);

  /// null = انبعت، وإلا رسالة الخطأ.
  Future<String?> offer({required String needId, required int quantity, String? note, String? phone}) async {
    try {
      await _client.rpc('offer_need', params: {
        'p_need_id': needId,
        'p_quantity': quantity,
        'p_note': (note?.trim().isEmpty ?? true) ? null : note!.trim(),
        'p_phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.message.contains('need_closed')) return 'هاد الاحتياج اكتمل أو سكّر، شكراً إلك 🤍';
      return 'صار خطأ، حاولي مرة تانية.';
    } catch (_) {
      return 'لا يوجد اتصال بالإنترنت';
    }
  }
}
