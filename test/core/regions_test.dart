import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/core/utils/regions.dart';

void main() {
  group('Regions.matches', () {
    test('بدون منطقة مختارة، كل شي بيطلع', () {
      expect(Regions.matches('خانيونس', null), isTrue);
      expect(Regions.matches(null, null), isTrue);
    });

    test('نفس المنطقة بتطلع، والمنطقة التانية لأ', () {
      expect(Regions.matches('خانيونس', 'خانيونس'), isTrue);
      expect(Regions.matches('رفح', 'خانيونس'), isFalse);
    });

    test('دير البلح جزء من الوسطى، وبالعكس', () {
      expect(Regions.matches('دير البلح', 'الوسطى'), isTrue);
      expect(Regions.matches('الوسطى', 'دير البلح'), isTrue);
    });

    test('"*" (عن بُعد) بيطلع بكل المناطق', () {
      expect(Regions.matches(Regions.everywhere, 'رفح'), isTrue);
    });

    test('العنصر اللي ما إله منطقة ما بيطلع لما نختار منطقة', () {
      expect(Regions.matches('', 'رفح'), isFalse);
      expect(Regions.matches(null, 'رفح'), isFalse);
    });
  });
}
