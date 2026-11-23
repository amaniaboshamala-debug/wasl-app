import 'package:wasl/core/errors/failure.dart';
import 'package:wasl/core/storage/local_cache.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:wasl/features/profile/domain/entities/user_profile.dart';
import 'package:wasl/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  ProfileRepositoryImpl(this._remote);

  String get _key => 'my_profile_${_remote.currentUserId ?? 'guest'}';

  @override
  Future<Result<UserProfile?>> getMine() async {
    try {
      final row = await _remote.fetchMine();
      if (row == null) return const Ok(null);
      await LocalCache.cache.put(_key, row);
      return Ok(UserProfile.fromJson(row));
    } catch (_) {
      final cached = LocalCache.cache.get(_key);
      if (cached is Map) return Ok(UserProfile.fromJson(Map<String, dynamic>.from(cached)));
      return const Err(Failure.network);
    }
  }

  @override
  Future<Result<UserProfile>> update({
    required String name,
    required String region,
    required List<String> skills,
    required String phone,
    required String bio,
  }) async {
    try {
      final row = await _remote.update({
        'full_name': name.trim(),
        'region': region.isEmpty ? null : region,
        'skills': skills,
        'phone': phone.trim().isEmpty ? null : phone.trim(),
        'bio': bio.trim().isEmpty ? null : bio.trim(),
      });
      await LocalCache.cache.put(_key, row);
      return Ok(UserProfile.fromJson(row));
    } catch (_) {
      return const Err(Failure('ما قدرنا نحفظ التعديلات، تأكدي من النت وجربي مرة تانية.'));
    }
  }
}
