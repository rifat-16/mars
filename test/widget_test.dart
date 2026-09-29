import 'package:flutter_test/flutter_test.dart';

import 'package:mars/core/state/async_state.dart';
import 'package:mars/models/domain/app_user.dart';

void main() {
  test('AppUser serialization roundtrip keeps key identity fields', () {
    const user = AppUser(
      uid: 'u1',
      email: 'a@b.com',
      firstName: 'John',
      lastName: 'Doe',
      phone: '01700000000',
      position: 'Owner',
      address: 'Dhaka',
    );

    final json = user.toJson();
    final parsed = AppUser.fromJson(json);

    expect(parsed.uid, user.uid);
    expect(parsed.email, user.email);
    expect(parsed.firstName, user.firstName);
    expect(parsed.position, user.position);
  });

  test('AsyncState helpers reflect status correctly', () {
    const loading = AsyncState<void>.loading();
    const success = AsyncState<int>.success(10);

    expect(loading.isLoading, isTrue);
    expect(success.isSuccess, isTrue);
    expect(success.data, 10);
  });
}
