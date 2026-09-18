import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/features/jobs/domain/job_status.dart';

void main() {
  group('job status machine', () {
    test('happy path transitions are legal', () {
      expect(canTransition('new', 'assigned'), isTrue);
      expect(canTransition('assigned', 'accepted'), isTrue);
      expect(canTransition('accepted', 'on_the_way'), isTrue);
      expect(canTransition('on_the_way', 'arrived'), isTrue);
      expect(canTransition('arrived', 'in_progress'), isTrue);
      expect(canTransition('in_progress', 'waiting_for_parts'), isTrue);
      expect(canTransition('waiting_for_parts', 'in_progress'), isTrue);
      expect(canTransition('in_progress', 'completed'), isTrue);
    });

    test('illegal skips are rejected (new cannot jump to completed)', () {
      expect(canTransition('new', 'completed'), isFalse);
      expect(canTransition('assigned', 'completed'), isFalse);
      expect(nextStates('new'), containsAll(['assigned', 'cancelled']));
    });

    test('terminal states have no exits', () {
      expect(nextStates('completed'), isEmpty);
      expect(nextStates('cancelled'), isEmpty);
    });

    test('cancel allowed only from new/assigned/accepted', () {
      expect(canTransition('new', 'cancelled'), isTrue);
      expect(canTransition('in_progress', 'cancelled'), isFalse);
    });
  });
}
