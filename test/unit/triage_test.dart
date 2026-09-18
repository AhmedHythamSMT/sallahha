import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/features/requests/domain/triage.dart';

void main() {
  group('rules-v1 category', () {
    test('Arabic cooling phrase', () {
      final s = suggestTriage('التكييف ما بيبردش وطالع هواء سخن');
      expect(s.category, 'cooling');
      expect(s.modelId, 'rules-v1');
      expect(s.reasons, isNotEmpty);
    });
    test('English cooling phrase', () {
      expect(
        suggestTriage('AC blows warm air, no cooling').category,
        'cooling',
      );
    });
    test('electrical phrase', () {
      expect(
        suggestTriage('القاطع بيفصل وفي ريحة شياط خفيفة').category,
        'electrical',
      );
    });
    test('leak phrase', () {
      expect(suggestTriage('في تسريب مية من الوحدة الداخلية').category, 'leak');
    });
    test('noise phrase', () {
      expect(suggestTriage('صوت زنة عالي واهتزاز').category, 'noise');
    });
    test('no-power phrase', () {
      expect(suggestTriage('التكييف مش شغال خالص').category, 'no_power');
    });
    test('cleaning phrase', () {
      expect(
        suggestTriage('محتاج تنظيف الفلاتر وصيانة دورية').category,
        'cleaning',
      );
    });
    test('vague text stays uncertain with low confidence', () {
      final s = suggestTriage('عايز حد يبص عليه بكرة');
      expect(s.category, 'uncertain');
      expect(s.confidence, lessThan(0.5));
    });
  });

  group('rules-v1 priority + safety', () {
    test('spark triggers urgent + safety warning', () {
      const text = 'في شرر طالع من الوحدة';
      expect(needsSafetyWarning(text), isTrue);
      expect(suggestTriage(text).priority, 'urgent');
    });
    test('burning smell (EN) triggers safety path', () {
      expect(needsSafetyWarning('burning smell near unit'), isTrue);
    });
    test('no-power suggests high', () {
      expect(suggestTriage('not working at all, dead unit').priority, 'high');
    });
    test('plain cleaning stays normal', () {
      expect(suggestTriage('تنظيف فلتر عادي').priority, 'normal');
    });
    test('human confirm is always representable (reasons logged)', () {
      final s = suggestTriage('noise and rattle from outdoor unit');
      expect(s.reasons.join(','), contains('keyword'));
    });
  });

  group('technician scoring', () {
    test('skilled + available + local wins over loaded tech', () {
      final a = matchTechnicianScore(
        techSkills: ['ac-repair'],
        serviceType: 'ac-repair',
        available: true,
        sameGovernorate: true,
        activeJobs: 1,
      );
      final b = matchTechnicianScore(
        techSkills: ['ac-install'],
        serviceType: 'ac-repair',
        available: true,
        sameGovernorate: true,
        activeJobs: 0,
      );
      expect(a, greaterThan(b));
    });
    test('load penalizes score', () {
      final fresh = matchTechnicianScore(
        techSkills: ['ac-repair'],
        serviceType: 'ac-repair',
        available: true,
        sameGovernorate: false,
        activeJobs: 0,
      );
      final loaded = matchTechnicianScore(
        techSkills: ['ac-repair'],
        serviceType: 'ac-repair',
        available: true,
        sameGovernorate: false,
        activeJobs: 5,
      );
      expect(fresh, greaterThan(loaded));
    });
  });
}
