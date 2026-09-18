import 'package:sallahha/core/storage/request_store.dart';
import 'package:sallahha/features/requests/domain/entities.dart';

/// Payment abstraction. Mock gateway is the default demo (zero cost, zero
/// keys); a Paymob/Fawry adapter implements this interface post-MVP.
/// No card data is ever stored — only amount + gateway reference.
abstract class PaymentService {
  Future<PaymentRecord> collect({
    required String requestId,
    required int amountEgp,
    required String method, // cash | test_card
  });
  Future<List<PaymentRecord>> history(String requestId);
}

class MockPaymentGateway implements PaymentService {
  final LocalRequestStore? local;
  int _seq = 0;

  /// [local] null = pure memory (tests). Device passes the drift store.
  MockPaymentGateway({this.local});

  @override
  Future<PaymentRecord> collect({
    required String requestId,
    required int amountEgp,
    required String method,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final state = amountEgp <= 0 ? 'failed' : 'succeeded';
    final record = PaymentRecord(
      id: 'pay-${DateTime.now().microsecondsSinceEpoch}-${_seq++}',
      amountEgp: amountEgp,
      state: state,
      gatewayRef: method == 'cash' ? null : 'mock-${method}_$_seq',
      createdAt: DateTime.now(),
    );
    await local?.recordPayment(
      id: record.id,
      requestId: requestId,
      amountEgp: amountEgp,
      state: state,
      gatewayRef: record.gatewayRef,
    );
    return record;
  }

  @override
  Future<List<PaymentRecord>> history(String requestId) async =>
      local?.paymentsFor(requestId) ?? const [];
}
