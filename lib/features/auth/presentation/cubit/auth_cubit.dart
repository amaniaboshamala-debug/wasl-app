import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';
import 'package:wasl/features/auth/domain/repositories/auth_repository.dart';
import 'package:wasl/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  StreamSubscription<AuthEvent>? _authSub;

  AuthCubit(this._repo) : super(AuthInitial()) {
    _authSub = _repo.onAuthChange.listen(_onAuthEvent);
  }

  /// بنسمع لأحداث Supabase: رجوع من رابط الإيميل، Google، أو انتهاء الجلسة.
  void _onAuthEvent(AuthEvent event) {
    switch (event) {
      case AuthEvent.passwordRecovery:
        emit(const PasswordRecovery());
      case AuthEvent.signedIn:
        if (state is! Authenticated && state is! AuthLoading && state is! PasswordRecovery) checkSession();
      case AuthEvent.signedOut:
        if (state is Authenticated || state is PasswordRecovery) emit(const Unauthenticated());
      case AuthEvent.other:
        break;
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }

  Future<void> checkSession() async {
    final user = await _repo.currentUser();
    if (state is PasswordRecovery) return; // ما نقطع شاشة كلمة السر الجديدة
    emit(user == null ? const Unauthenticated() : Authenticated(user));
  }

  Future<void> login(String email, String password) =>
      _run(() => _repo.login(email: email, password: password));

  Future<void> signUp(String name, String email, String password) =>
      _run(() => _repo.signUp(name: name, email: email, password: password));

  Future<void> signInWith(SocialProvider provider) async {
    final failure = await _repo.signInWith(provider);
    if (failure != null) emit(Unauthenticated(error: failure.message));
  }

  Future<void> chooseRole(UserRole role) => _run(() => _repo.setRole(role));

  /// بيرجع null إذا الرسالة انبعتت، أو رسالة الخطأ.
  Future<String?> sendPasswordReset(String email) async => (await _repo.sendPasswordReset(email))?.message;

  Future<String?> resendConfirmation(String email) async => (await _repo.resendConfirmation(email))?.message;

  Future<void> updatePassword(String newPassword) async {
    emit(const PasswordRecovery(saving: true));
    switch (await _repo.updatePassword(newPassword)) {
      case Ok(:final data):
        emit(Authenticated(data));
      case Err(:final failure):
        emit(PasswordRecovery(error: failure.message));
    }
  }

  /// من شاشة "تفقدي إيميلك": رجوع لتسجيل الدخول.
  void backToLogin() => emit(const Unauthenticated());

  Future<void> logout() async {
    await _repo.logout();
    emit(const Unauthenticated());
  }

  Future<void> _run(Future<Result<AppUser>> Function() call) async {
    final previous = state;
    emit(AuthLoading());
    switch (await call()) {
      case Ok(:final data):
        emit(Authenticated(data));
      case Err(failure: ConfirmEmailFailure(:final email)):
        emit(AwaitingEmailConfirmation(email));
      case Err(:final failure):
        emit(previous is Authenticated ? previous : Unauthenticated(error: failure.message));
    }
  }
}
