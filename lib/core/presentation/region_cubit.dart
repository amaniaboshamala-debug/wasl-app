import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasl/core/storage/local_cache.dart';

/// المنطقة اللي اختارها المستخدم (null = كل المناطق).
/// بتنحفظ عالجوال، فبتضل نفسها لما يسكّر التطبيق ويرجع.
class RegionCubit extends Cubit<String?> {
  static const _key = 'selected_region';
  RegionCubit() : super(LocalCache.cache.get(_key) as String?);

  Future<void> select(String? region) async {
    if (region == null) {
      await LocalCache.cache.delete(_key);
    } else {
      await LocalCache.cache.put(_key, region);
    }
    emit(region);
  }
}
