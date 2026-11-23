/// مناطق قطاع غزة اللي بنستخدمها بالتصفية.
class Regions {
  static const all = [
    'شمال غزة',
    'مدينة غزة',
    'الوسطى',
    'دير البلح',
    'خانيونس',
    'رفح',
  ];

  /// "*" يعني بيطلع بكل المناطق (مثلاً فرصة عن بُعد).
  static const everywhere = '*';

  /// بنعتبر "دير البلح" جزء من "الوسطى" عشان النتائج ما تضيع.
  static bool matches(String? itemRegion, String? selected) {
    if (selected == null || itemRegion == everywhere) return true;
    if (itemRegion == null || itemRegion.isEmpty) return false;
    if (itemRegion == selected) return true;
    const middle = {'الوسطى', 'دير البلح'};
    return middle.contains(itemRegion) && middle.contains(selected);
  }
}
