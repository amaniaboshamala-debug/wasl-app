import 'package:equatable/equatable.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Unauthenticated extends AuthState {
  final String? error;
  const Unauthenticated({this.error});
  @override
  List<Object?> get props => [error];
}

/// الحساب انعمل، وبنستنى المستخدم يضغط رابط التأكيد اللي وصله.
class AwaitingEmailConfirmation extends AuthState {
  final String email;
  const AwaitingEmailConfirmation(this.email);
  @override
  List<Object?> get props => [email];
}

/// فتح رابط "نسيت كلمة السر"، ولازم يكتب كلمة سر جديدة.
class PasswordRecovery extends AuthState {
  final String? error;
  final bool saving;
  const PasswordRecovery({this.error, this.saving = false});
  @override
  List<Object?> get props => [error, saving];
}

class Authenticated extends AuthState {
  final AppUser user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}
