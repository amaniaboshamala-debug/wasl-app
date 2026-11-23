import 'package:equatable/equatable.dart';

/// المؤسسة أو الفريق اللي بيملكه حساب المؤسسة.
class Organization extends Equatable {
  final String id;
  final String name;
  final String bio;
  final String region;
  final String contact;
  final bool isVerified; // التوثيق بيصير من إدارة وَصْل، مش من التطبيق

  const Organization({
    required this.id,
    required this.name,
    this.bio = '',
    this.region = '',
    this.contact = '',
    this.isVerified = false,
  });

  /// أول حرف من الاسم للصورة الدائرية
  String get initial => name.trim().isEmpty ? '؟' : String.fromCharCode(name.trim().runes.first);

  @override
  List<Object?> get props => [id, name, bio, region, contact, isVerified];
}
