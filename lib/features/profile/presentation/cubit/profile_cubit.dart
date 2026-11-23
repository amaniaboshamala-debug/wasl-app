import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/profile/domain/entities/user_profile.dart';
import 'package:wasl/features/profile/domain/repositories/profile_repository.dart';

class ProfileState extends Equatable {
  final UserProfile? profile;
  final bool loading;
  final bool saving;
  final String? error;
  const ProfileState({this.profile, this.loading = false, this.saving = false, this.error});

  @override
  List<Object?> get props => [profile, loading, saving, error];
}

/// ملفي الشخصي: تحميل وتعديل.
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository _repo;
  ProfileCubit(this._repo) : super(const ProfileState());

  UserProfile? get profile => state.profile;

  Future<void> load() async {
    emit(ProfileState(profile: state.profile, loading: true));
    final r = await _repo.getMine();
    switch (r) {
      case Ok(:final data):
        emit(ProfileState(profile: data));
      case Err(:final failure):
        emit(ProfileState(profile: state.profile, error: failure.message));
    }
  }

  /// بيرجّع رسالة الخطأ، أو null إذا انحفظ.
  Future<String?> save({
    required String name,
    required String region,
    required List<String> skills,
    required String phone,
    required String bio,
  }) async {
    emit(ProfileState(profile: state.profile, saving: true));
    final r = await _repo.update(name: name, region: region, skills: skills, phone: phone, bio: bio);
    switch (r) {
      case Ok(:final data):
        emit(ProfileState(profile: data));
        return null;
      case Err(:final failure):
        emit(ProfileState(profile: state.profile, error: failure.message));
        return failure.message;
    }
  }

  void reset() => emit(const ProfileState());
}
