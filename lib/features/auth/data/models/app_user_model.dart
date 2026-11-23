import 'package:wasl/features/auth/domain/entities/app_user.dart';

/// بيحوّل بيانات جدول profiles لـ AppUser.
class AppUserModel {
  static AppUser fromProfile(Map<String, dynamic> json, String email) {
    return AppUser(
      id: json['id'] as String,
      email: email,
      name: (json['full_name'] ?? '') as String,
      role: _role(json['role'] as String?),
    );
  }

  static UserRole? _role(String? value) => switch (value) {
        'user' => UserRole.user,
        'volunteer' => UserRole.volunteer,
        'organization' => UserRole.organization,
        'admin' => UserRole.admin,
        _ => null,
      };
}
