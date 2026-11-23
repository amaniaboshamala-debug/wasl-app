import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/features/favorites/domain/repositories/favorites_repository.dart';

/// المفضلة: مجموعة مفاتيح "نوع:رقم". الضغط على القلب بيغيّر فوراً، وإذا فشل السيرفر بنرجّعه.
class FavoritesCubit extends Cubit<Set<String>> {
  final FavoritesRepository _repo;
  FavoritesCubit(this._repo) : super(const <String>{});

  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    emit(await _repo.getKeys());
  }

  bool isFavorite(FavoriteType type, String id) => state.contains(favoriteKey(type, id));

  /// بيرجّع false إذا ما انحفظ التغيير (مثلاً ما في نت).
  Future<bool> toggle(FavoriteType type, String id) async {
    final key = favoriteKey(type, id);
    final adding = !state.contains(key);
    emit(adding ? {...state, key} : ({...state}..remove(key)));
    final ok = adding ? await _repo.add(type, id) : await _repo.remove(type, id);
    if (!ok) emit(adding ? ({...state}..remove(key)) : {...state, key});
    return ok;
  }

  /// أرقام العناصر المحفوظة من نوع معيّن.
  Set<String> idsOf(FavoriteType type) =>
      {for (final k in state) if (k.startsWith('${type.name}:')) k.substring(type.name.length + 1)};

  void reset() {
    _loaded = false;
    emit(const <String>{});
  }
}
