import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';
import 'package:wasl/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  AuthRepositoryImpl(this._remote);

  @override
  Future<Result<AppUser>> login({required String email, required String password}) async {
    final result = await _guard(() => _remote.login(email, password));
    // لو ما أكّد إيميله، بنوديه على شاشة "تفقدي إيميلك" وفيها زر إعادة الإرسال
    if (result case Err(:final failure) when failure.message == _notConfirmed) {
      return Err(ConfirmEmailFailure(email));
    }
    return result;
  }

  static const _notConfirmed = 'لازم تأكدي إيميلك أول. شوفي الرسالة اللي وصلتك.';

  @override
  Future<Result<AppUser>> signUp({required String name, required String email, required String password}) =>
      _guard(() => _remote.signUp(name, email, password));

  @override
  Future<Result<AppUser>> setRole(UserRole role) => _guard(() => _remote.setRole(role));

  @override
  Future<Result<AppUser>> updatePassword(String newPassword) => _guard(() => _remote.updatePassword(newPassword));

  @override
  Future<Failure?> signInWith(SocialProvider provider) =>
      _try(() => _remote.signInWith(provider), 'ما قدرنا نفتح صفحة الدخول، جربي مرة تانية.');

  @override
  Future<Failure?> sendPasswordReset(String email) =>
      _try(() => _remote.sendPasswordReset(email), 'ما قدرنا نبعت الرسالة، جربي مرة تانية.');

  @override
  Future<Failure?> resendConfirmation(String email) =>
      _try(() => _remote.resendConfirmation(email), 'ما قدرنا نبعت الرسالة، جربي مرة تانية.');

  @override
  Future<AppUser?> currentUser() async {
    try {
      return await _remote.currentUser();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() => _remote.logout();

  @override
  Stream<AuthEvent> get onAuthChange => _remote.onAuthChange;

  /// بيحوّل أي Exception لرسالة عربية مفهومة.
  Future<Result<AppUser>> _guard(Future<AppUser> Function() call) async {
    try {
      return Ok(await call());
    } on EmailConfirmationRequired catch (e) {
      return Err(ConfirmEmailFailure(e.email));
    } on AuthException catch (e) {
      return Err(Failure(_arabic(e.message)));
    } on PostgrestException catch (e) {
      return Err(Failure(_arabic(e.message)));
    } catch (_) {
      return const Err(Failure.unknown);
    }
  }

  Future<Failure?> _try(Future<void> Function() call, String fallback) async {
    try {
      await call();
      return null;
    } on AuthException catch (e) {
      return Failure(_arabic(e.message));
    } catch (_) {
      return Failure(fallback);
    }
  }

  String _arabic(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login')) return 'الإيميل أو كلمة السر غير صحيحة';
    if (m.contains('email not confirmed')) return _notConfirmed;
    if (m.contains('already registered')) return 'هاد الإيميل عنده حساب، جربي تسجّلي دخول.';
    if (m.contains('rate limit') || m.contains('security purposes')) {
      return 'محاولات كتير، استني شوي وجربي مرة تانية.';
    }
    if (m.contains('not authorized')) return 'ما قدرنا نبعت رسالة لهاد الإيميل حالياً.';
    if (m.contains('different from the old')) return 'كلمة السر الجديدة لازم تكون غير القديمة.';
    if (m.contains('password should be')) return 'كلمة السر لازم تكون 6 أحرف على الأقل.';
    if (m.contains('socketexception') || m.contains('failed host lookup')) return Failure.network.message;
    if (m.contains('role_change_not_allowed')) return 'ما بنقدر نغيّر الدور لهاد الخيار.';
    return msg;
  }
}
