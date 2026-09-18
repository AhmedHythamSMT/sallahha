import 'package:flutter_test/flutter_test.dart';
import 'package:sallahha/core/analytics/analytics_service.dart';
import 'package:sallahha/features/notifications/notification_service.dart';
import 'package:sallahha/features/payments/payment_service.dart';
import 'package:sallahha/features/requests/domain/ai_service.dart';

void main() {
  group('notifications (memory)', () {
    test('notify → inbox → markRead', () async {
      final svc = MemoryNotificationService();
      await svc.notify(
        userId: 'u-tech-1',
        kind: 'assignment',
        title: 'طلب جديد مُسند',
        body: '#req-1',
      );
      var inbox = await svc.inbox('u-tech-1');
      expect(inbox, hasLength(1));
      expect(inbox.single.read, isFalse);
      await svc.markRead(inbox.single.id);
      inbox = await svc.inbox('u-tech-1');
      expect(inbox.single.read, isTrue);
      // other users unaffected
      expect(await svc.inbox('u-customer-1'), isEmpty);
    });
  });

  group('mock payments', () {
    test('cash succeeds, zero amount fails, no card stored', () async {
      final gw = MockPaymentGateway();
      final ok = await gw.collect(
        requestId: 'req-1',
        amountEgp: 450,
        method: 'cash',
      );
      expect(ok.state, 'succeeded');
      expect(ok.gatewayRef, isNull); // cash: nothing stored
      final bad = await gw.collect(
        requestId: 'req-1',
        amountEgp: 0,
        method: 'test_card',
      );
      expect(bad.state, 'failed');
    });
  });

  group('analytics (memory, non-PII)', () {
    test('logs events with params, caps buffer', () {
      final a = MemoryAnalyticsService();
      a.log('request_created', {'id': 'req-1'});
      expect(a.events.single.name, 'request_created');
      for (var i = 0; i < 250; i++) {
        a.log('e$i');
      }
      expect(a.events.length, 200);
    });
  });

  group('AI service seam', () {
    test('rule-based adapter delegates to rules-v1', () {
      final ai = RuleBasedTriageService();
      final s = ai.suggest('التكييف ما بيبردش');
      expect(s.category, 'cooling');
      expect(s.modelId, 'rules-v1');
      expect(
        ai.matchScore(
          techSkills: const ['ac-repair'],
          serviceType: 'ac-repair',
          available: true,
          sameGovernorate: true,
          activeJobs: 0,
        ),
        greaterThan(0),
      );
    });

    test('fake is deterministic for UI tests', () {
      final ai = FakeAIService();
      expect(ai.suggest('anything').modelId, 'fake');
    });
  });
}
