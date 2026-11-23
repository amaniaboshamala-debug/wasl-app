import 'package:equatable/equatable.dart';

/// admin = فريق وَصْل (بيتعيّن من لوحة Supabase بس، مش من التطبيق)
enum UserRole { user, volunteer, organization, admin }

/// طرق الدخول الخارجية
enum SocialProvider { google, facebook }

/// أحداث الدخول اللي بتهمنا من Supabase
enum AuthEvent { signedIn, signedOut, passwordRecovery, other }

class AppUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole? role; // null = لسا ما اختار دوره

  const AppUser({required this.id, required this.email, required this.name, this.role});

  bool get isOrganization => role == UserRole.organization;
  bool get isAdmin => role == UserRole.admin;

  String get roleLabel => switch (role) {
        UserRole.user => 'مستخدم',
        UserRole.volunteer => 'متطوع',
        UserRole.organization => 'مؤسسة أو فريق',
        UserRole.admin => 'إدارة وَصْل',
        null => 'لم يُحدَّد',
      };

  @override
  List<Object?> get props => [id, email, name, role];
}
