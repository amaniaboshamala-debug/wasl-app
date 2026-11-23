import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<Result<UserProfile?>> getMine();
  Future<Result<UserProfile>> update({
    required String name,
    required String region,
    required List<String> skills,
    required String phone,
    required String bio,
  });
}
