import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/utils/result.dart';
import 'package:wasl/features/organization/domain/entities/organization.dart';
import 'package:wasl/features/organization/domain/repositories/org_repository.dart';

sealed class MyOrgState extends Equatable {
  const MyOrgState();
  @override
  List<Object?> get props => [];
}

class MyOrgLoading extends MyOrgState {
  const MyOrgLoading();
}

/// حساب المؤسسة لسا ما عمل مؤسسته، فبنورجيه نموذج الإعداد.
class MyOrgMissing extends MyOrgState {
  final String? error;
  final bool saving;
  const MyOrgMissing({this.error, this.saving = false});
  @override
  List<Object?> get props => [error, saving];
}

class MyOrgReady extends MyOrgState {
  final Organization org;
  const MyOrgReady(this.org);
  @override
  List<Object?> get props => [org];
}

class MyOrgError extends MyOrgState {
  final String message;
  const MyOrgError(this.message);
  @override
  List<Object?> get props => [message];
}

/// مؤسستي: بنجيبها، وإذا مش موجودة بنعملها.
class MyOrgCubit extends Cubit<MyOrgState> {
  final OrgRepository _repo;
  MyOrgCubit(this._repo) : super(const MyOrgLoading());

  Organization? get org => switch (state) {
        MyOrgReady(:final org) => org,
        _ => null,
      };

  Future<void> load() async {
    if (state is! MyOrgReady) emit(const MyOrgLoading());
    final r = await _repo.getMyOrg();
    switch (r) {
      case Ok(:final data):
        emit(data == null ? const MyOrgMissing() : MyOrgReady(data));
      case Err(:final failure):
        emit(MyOrgError(failure.message));
    }
  }

  Future<void> create({required String name, String bio = '', String region = '', String contact = ''}) async {
    emit(const MyOrgMissing(saving: true));
    final r = await _repo.createOrg(name: name, bio: bio, region: region, contact: contact);
    switch (r) {
      case Ok(:final data):
        emit(MyOrgReady(data));
      case Err(:final failure):
        emit(MyOrgMissing(error: failure.message));
    }
  }

  /// بيرجّع رسالة الخطأ، أو null إذا انحفظ.
  Future<String?> update({required String name, String bio = '', String region = '', String contact = ''}) async {
    final r = await _repo.updateOrg(name: name, bio: bio, region: region, contact: contact);
    switch (r) {
      case Ok(:final data):
        emit(MyOrgReady(data));
        return null;
      case Err(:final failure):
        return failure.message;
    }
  }

  void reset() => emit(const MyOrgLoading());
}
