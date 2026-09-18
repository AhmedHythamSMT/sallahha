import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/core/sync/backoff.dart';

void main() {
  test('exponential growth with 5-minute cap', () {
    expect(backoffForAttempt(0), const Duration(seconds: 1));
    expect(backoffForAttempt(1), const Duration(seconds: 2));
    expect(backoffForAttempt(2), const Duration(seconds: 4));
    expect(backoffForAttempt(3), const Duration(seconds: 8));
    expect(backoffForAttempt(8), const Duration(seconds: 256));
    expect(backoffForAttempt(9), const Duration(seconds: 300));
  });
}
