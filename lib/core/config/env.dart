/// القيم بتيجي من env.json وقت التشغيل:
/// flutter run --dart-define-from-file=env.json
class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static void check() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'مفاتيح Supabase ناقصة. شغّلي التطبيق بـ: flutter run --dart-define-from-file=env.json',
      );
    }
  }
}
