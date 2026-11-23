import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';

/// العقد: شو بيقدر يعمل الـ Auth، بدون ما يهمنا كيف (Supabase أو غيره).
abstract class AuthRepository {
  Future<Result<AppUser>> login({required String email, required String password});
  Future<Result<AppUser>> signUp({required String name, required String email, required String password});
  Future<Result<AppUser>> setRole(UserRole role);

  /// بيفتح صفحة Google، وبيرجع null إذا انفتحت تمام.
  Future<Failure?> signInWith(SocialProvider provider);

  /// بيبعت رابط تغيير كلمة السر على الإيميل. null = انبعت تمام.
  Future<Failure?> sendPasswordReset(String email);

  /// بيعيد إرسال رابط تأكيد الحساب. null = انبعت تمام.
  Future<Failure?> resendConfirmation(String email);

  /// كلمة سر جديدة (بعد ما يفتح رابط "نسيت كلمة السر").
  Future<Result<AppUser>> updatePassword(String newPassword);

  Future<AppUser?> currentUser();
  Future<void> logout();
  Stream<AuthEvent> get onAuthChange;
}
