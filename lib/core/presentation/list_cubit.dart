import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/data/cached_list.dart';
import 'package:wasl/core/utils/result.dart';

/// حالة أي قائمة: بتحمّل · جاهزة · خطأ.
sealed class ListState<T> extends Equatable {
  const ListState();
  @override
  List<Object?> get props => [];
}

class ListLoading<T> extends ListState<T> {
  const ListLoading();
}

class ListLoaded<T> extends ListState<T> {
  final List<T> items;
  final bool fromCache; // true = ما في نت، وهاي آخر نسخة محفوظة
  final DateTime? savedAt;
  const ListLoaded(this.items, {this.fromCache = false, this.savedAt});
  @override
  List<Object?> get props => [items, fromCache, savedAt];
}

class ListError<T> extends ListState<T> {
  final String message;
  const ListError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Cubit عام لأي قائمة (مبادرات، خدمات، احتياجات...).
/// كل feature بتعطيه الدالة اللي بتجيب البيانات من الـ Repository تبعها.
class ListCubit<T> extends Cubit<ListState<T>> {
  final Future<Result<CachedList<T>>> Function() _load;
  ListCubit(this._load) : super(ListLoading<T>());

  bool _started = false;

  /// بتحمّل مرة وحدة بس (أول ما تنفتح الشاشة).
  Future<void> ensureLoaded() async {
    if (_started) return;
    _started = true;
    await refresh();
  }

  /// سحب للتحديث، أو زر "حاولي مرة تانية".
  Future<void> refresh() async {
    if (state is! ListLoaded<T>) emit(ListLoading<T>());
    final result = await _load();
    switch (result) {
      case Ok(:final data):
        emit(ListLoaded<T>(data.items, fromCache: data.fromCache, savedAt: data.savedAt));
      case Err(:final failure):
        emit(ListError<T>(failure.message));
    }
  }

  /// بنفضّي القائمة (مثلاً بعد تسجيل الخروج)، والمرة الجاية بتحمّل من جديد.
  void reset() {
    _started = false;
    emit(ListLoading<T>());
  }

  List<T> get items => switch (state) {
        ListLoaded<T>(:final items) => items,
        _ => <T>[],
      };
}
