/// نوع العنصر المحفوظ بالمفضلة.
enum FavoriteType { initiative, service, need, opportunity }

/// مفتاح العنصر بالمفضلة: "opportunity:123"
String favoriteKey(FavoriteType type, String id) => '${type.name}:$id';

abstract class FavoritesRepository {
  /// المفاتيح المحفوظة (من النت، أو من الكاش لما ما في نت).
  Future<Set<String>> getKeys();
  Future<bool> add(FavoriteType type, String id);
  Future<bool> remove(FavoriteType type, String id);
}
