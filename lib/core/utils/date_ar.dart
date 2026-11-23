import 'package:intl/intl.dart';

/// تنسيق التواريخ بالعربي.
class DateAr {
  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  static String month(DateTime d) => _months[d.month - 1];

  /// "24 نوفمبر"
  static String day(DateTime d) => '${d.day} ${month(d)}';

  /// "24 – 26 نوفمبر" أو "28 نوفمبر – 3 ديسمبر"
  static String range(DateTime? start, DateTime? end) {
    if (start == null) return 'الموعد بيتحدد قريباً';
    if (end == null || _sameDay(start, end)) return day(start);
    if (start.month == end.month && start.year == end.year) {
      return '${start.day} – ${end.day} ${month(end)}';
    }
    return '${day(start)} – ${day(end)}';
  }

  /// "قبل ساعتين"، "أمس"، "قبل 3 أيام"
  static String ago(DateTime d) {
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1) return 'هلأ';
    if (diff.inMinutes < 60) return 'قبل ${_count(diff.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق')}';
    if (diff.inHours < 24) return 'قبل ${_count(diff.inHours, 'ساعة', 'ساعتين', 'ساعات')}';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 30) return 'قبل ${_count(diff.inDays, 'يوم', 'يومين', 'أيام')}';
    return 'بـ ${DateFormat('d/M/yyyy').format(d.toLocal())}';
  }

  static String _count(int n, String one, String two, String few) {
    if (n == 1) return one;
    if (n == 2) return two;
    if (n <= 10) return '$n $few';
    return '$n $one';
  }

  static bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
