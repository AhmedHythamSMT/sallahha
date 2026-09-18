import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/features/requests/domain/rules.dart';

void main() {
  group('SLA', () {
    test('overdue only for open requests past due', () {
      final due = DateTime(2026, 9, 10);
      final now = DateTime(2026, 9, 17);
      expect(isOverdue(due, 'new', now), isTrue);
      expect(isOverdue(due, 'in_progress', now), isTrue);
      expect(isOverdue(due, 'completed', now), isFalse);
      expect(isOverdue(due, 'cancelled', now), isFalse);
      expect(isOverdue(now.add(const Duration(hours: 1)), 'new', now), isFalse);
    });

    test('default SLA adds service hours', () {
      final created = DateTime(2026, 9, 17, 10);
      expect(defaultSlaDue(created, 24), DateTime(2026, 9, 18, 10));
    });
  });

  group('phone + draft validation', () {
    test('Egyptian mobiles accepted, others rejected', () {
      expect(isValidEgyptPhone('01001234567'), isTrue);
      expect(isValidEgyptPhone(' 01001234567 '), isTrue);
      expect(isValidEgyptPhone('0212345678'), isFalse);
      expect(isValidEgyptPhone('0100123456'), isFalse);
      expect(isValidEgyptPhone(''), isFalse);
    });

    test('draft flags first bad field', () {
      expect(
        validateDraft(
          description: 'short',
          address: '12 شارع مصدق، الدقي',
          governorate: 'الجيزة',
          phone: '01001234567',
        ),
        'description',
      );
      expect(
        validateDraft(
          description: 'التكييف ما بيبردش خالص يا جماعة',
          address: '12 شارع مصدق، الدقي',
          governorate: 'الجيزة',
          phone: 'bad',
        ),
        'phone',
      );
      expect(
        validateDraft(
          description: 'التكييف ما بيبردش خالص يا جماعة',
          address: '12 شارع مصدق، الدقي',
          governorate: 'الجيزة',
          phone: '01001234567',
        ),
        isNull,
      );
    });
  });

  group('transition guard', () {
    test('legal passes, illegal returns typed error', () {
      expect(checkTransition('new', 'assigned'), isNull);
      final err = checkTransition('new', 'completed');
      expect(err, isNotNull);
      expect(err.toString(), contains('IllegalTransition'));
    });
  });
}
