import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasl/core/storage/local_cache.dart';
import 'package:wasl/features/auth/data/models/app_user_model.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';

/// الكلام المباشر مع Supabase (Auth + جدول profiles).
class AuthRemoteDataSource {
  final SupabaseClient _client;
  AuthRemoteDataSource(this._client);

  /// الرابط اللي بيرجّع المستخدم على التطبيق بعد رسالة الإيميل أو Google.
  /// على الجوال: رابط خاص بالتطبيق (مسجّل بـ AndroidManifest و Info.plist).
  /// على الويب: نفس عنوان الصفحة.
  static const mobileRedirect = 'com.amani.wasl://login-callback';
  String get _redirectUrl => kIsWeb ? Uri.base.origin : mobileRedirect;

  Future<AppUser> login(String email, String password) async {
    final res = await _client.auth.signInWithPassword(email: email, password: password);
    return _loadProfile(res.user!);
  }

  /// لما يكون تأكيد الإيميل شغّال، Supabase ما بيرجّع session
  /// لحد ما المستخدم يضغط على الرابط اللي وصله.
  Future<AppUser> signUp(String name, String email, String password) async {
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
      emailRedirectTo: _redirectUrl,
    );
    if (res.session == null) throw EmailConfirmationRequired(email);
    return _loadProfile(res.user!);
  }

  Future<void> resendConfirmation(String email) =>
      _client.auth.resend(type: OtpType.signup, email: email, emailRedirectTo: _redirectUrl);

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email, redirectTo: _redirectUrl);

  Future<AppUser> updatePassword(String newPassword) async {
    final res = await _client.auth.updateUser(UserAttributes(password: newPassword));
    return _loadProfile(res.user!);
  }

  /// بيبلّغ كل ما تتغير حالة الدخول (رجوع من رابط الإيميل، Google، خروج...).
  Stream<AuthEvent> get onAuthChange => _client.auth.onAuthStateChange.map(
        (e) => switch (e.event) {
          AuthChangeEvent.signedIn => AuthEvent.signedIn,
          AuthChangeEvent.signedOut => AuthEvent.signedOut,
          AuthChangeEvent.passwordRecovery => AuthEvent.passwordRecovery,
          _ => AuthEvent.other,
        },
      );

  /// بيوديه على صفحة Google، وبعد الموافقة بيرجع على التطبيق
  /// والجلسة بتوصل عن طريق onAuthChange.
  Future<void> signInWith(SocialProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider == SocialProvider.google ? OAuthProvider.google : OAuthProvider.facebook,
      redirectTo: _redirectUrl,
    );
  }

  Future<AppUser> setRole(UserRole role) async {
    final user = _client.auth.currentUser!;
    await _client.from('profiles').update({'role': role.name}).eq('id', user.id);
    return _loadProfile(user);
  }

  /// عند فتح التطبيق: Supabase حافظ جلسة الدخول (التوكن) عالجوال لحاله.
  /// إذا ما في نت، بنستعمل آخر نسخة محفوظة من الـ profile، عشان المستخدم يضل داخل.
  Future<AppUser?> currentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _loadProfile(user);
    } catch (_) {
      final cached = LocalCache.cache.get(_profileKey(user.id));
      if (cached is Map) return AppUserModel.fromProfile(Map<String, dynamic>.from(cached), user.email ?? '');
      rethrow;
    }
  }

  Future<void> logout() async {
    final id = _client.auth.currentUser?.id;
    await _client.auth.signOut();
    if (id != null) await LocalCache.cache.delete(_profileKey(id));
  }

  static String _profileKey(String userId) => 'auth_profile_$userId';

  /// بيجيب الـ profile، وإذا مش موجود (حساب قديم) بيعمله.
  Future<AppUser> _loadProfile(User user) async {
    var row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row == null) {
      final meta = user.userMetadata ?? {};
      final name = (meta['full_name'] ?? meta['name'] ?? '') as String;
      row = await _client.from('profiles').insert({'id': user.id, 'full_name': name}).select().single();
    }
    await LocalCache.cache.put(_profileKey(user.id), row); // نسخة للفتح بدون نت
    return AppUserModel.fromProfile(row, user.email ?? '');
  }
}

/// الحساب انعمل، بس لازم يأكد إيميله قبل ما يدخل.
class EmailConfirmationRequired implements Exception {
  final String email;
  const EmailConfirmationRequired(this.email);
}
