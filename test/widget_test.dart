import 'package:flutter_test/flutter_test.dart';
import 'package:wasl/features/auth/domain/entities/app_user.dart';

void main() {
  test('حساب المؤسسة بيتعرّف صح', () {
    const org = AppUser(id: '1', email: 'a@b.com', name: 'نور', role: UserRole.organization);
    const volunteer = AppUser(id: '2', email: 'c@d.com', name: 'سارة', role: UserRole.volunteer);

    expect(org.isOrganization, isTrue);
    expect(volunteer.isOrganization, isFalse);
  });
}
