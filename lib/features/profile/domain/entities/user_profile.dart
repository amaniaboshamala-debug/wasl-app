import 'package:equatable/equatable.dart';

/// الملف الشخصي (من جدول profiles).
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String region;
  final List<String> skills;
  final String phone;
  final String bio;

  const UserProfile({
    required this.id,
    this.name = '',
    this.region = '',
    this.skills = const [],
    this.phone = '',
    this.bio = '',
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: (j['full_name'] as String?) ?? '',
        region: (j['region'] as String?) ?? '',
        skills: ((j['skills'] as List?) ?? const []).map((e) => e.toString()).toList(),
        phone: (j['phone'] as String?) ?? '',
        bio: (j['bio'] as String?) ?? '',
      );

  /// كم خانة معبّاة من 5 (للشريط "كمّلي ملفك")
  int get completeness => [name, region, phone, bio].where((s) => s.trim().isNotEmpty).length + (skills.isEmpty ? 0 : 1);

  @override
  List<Object?> get props => [id, name, region, skills, phone, bio];
}
