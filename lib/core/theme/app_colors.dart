import 'package:flutter/material.dart';

/// ثيم "ناعم وراقي": أخضر مريمية + خوخي على كريمي، ولمسة ذهبية للشهادات والإنجازات.
class AppColors {
  static const primary = Color(0xFF3E6B5A); // أخضر مريمية غامق
  static const primaryDark = Color(0xFF2E5345);
  static const primarySoft = Color(0xFFDCE8E0);

  static const ink = Color(0xFF2B3531);
  static const muted = Color(0xFF66716C);
  static const background = Color(0xFFFAF7F2); // كريمي
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFEAE4D8);

  static const orange = Color(0xFFB0543A); // تيراكوتا ناعم
  static const orangeSoft = Color(0xFFF6E6DE);
  static const peach = Color(0xFFF6DDD0);
  static const blue = Color(0xFF2F6276);
  static const blueSoft = Color(0xFFE3EEF2);
  static const red = Color(0xFFB42318);
  static const redSoft = Color(0xFFFBECEA);

  // اللمسة الذهبية: الشهادات والشارات بس
  static const gold = Color(0xFFC9A35B);
  static const goldDark = Color(0xFF7A5A1E);
  static const goldSoft = Color(0xFFF7EBD3);

  /// ظل خفيف للكروت
  static const shadow = [BoxShadow(color: Color(0x143E6B5A), blurRadius: 24, offset: Offset(0, 8))];
}
