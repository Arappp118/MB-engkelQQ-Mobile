import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/features/admin/payments/admin_payments_page.dart';
import 'package:mb_engkelqq_mobile/models/payment.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
import 'package:mb_engkelqq_mobile/providers/payment_provider.dart';
import 'package:mb_engkelqq_mobile/providers/service_order_provider.dart';
import 'package:mb_engkelqq_mobile/services/payment_service.dart';
import 'package:mb_engkelqq_mobile/services/service_order_service.dart';
import 'package:provider/provider.dart';

class FakePaymentService extends PaymentService {
  bool verifyCalled = false;
  bool rejectCalled = false;
  int? lastId;
  String? lastReason;

  @override
  Future<Payment> verifyPayment(int id) async {
    verifyCalled = true;
    lastId = id;
    return Payment(
      id: id,
      serviceOrderId: id,
      amount: 150000,
      status: 'verified',
    );
  }

  @override
  Future<Payment> rejectPayment(int id, {String? reason}) async {
    rejectCalled = true;
    lastId = id;
    lastReason = reason;
    return Payment(
      id: id,
      serviceOrderId: id,
      amount: 150000,
      status: 'rejected',
      notes: reason,
    );
  }
}

class FakeServiceOrderService extends ServiceOrderService {
  @override
  Future<List<ServiceOrder>> getServiceOrders() async {
    return [
      const ServiceOrder(
        id: 101,
        bookingId: 42,
        status: 'waiting_payment',
        grandTotal: 150000,
        diagnosis: 'Ganti oli dan busi',
      ),
      const ServiceOrder(
        id: 102,
        bookingId: 43,
        status: 'paid',
        grandTotal: 200000,
        diagnosis: 'Tune up',
      ),
    ];
  }
}

void main() {
  test('Payment model parsing and helper getters', () {
    final payment = Payment.fromJson({
      'id': 1,
      'service_order_id': 101,
      'payment_method': 'transfer',
      'amount': 150000,
      'status': 'waiting_verification',
      'has_proof': true,
      'paid_at': '2026-10-08 10:00:00',
    });

    expect(payment.id, 1);
    expect(payment.serviceOrderId, 101);
    expect(payment.method, 'transfer');
    expect(payment.methodLabel, 'Transfer Bank');
    expect(payment.status, 'waiting_verification');
    expect(payment.statusLabel, 'Menunggu Verifikasi');
    expect(payment.hasProof, isTrue);
  });

  test('PaymentProvider verifyPayment and rejectPayment methods', () async {
    final fakeService = FakePaymentService();
    final provider = PaymentProvider(paymentService: fakeService);

    final verifySuccess = await provider.verifyPayment(101);
    expect(verifySuccess, isTrue);
    expect(fakeService.verifyCalled, isTrue);
    expect(fakeService.lastId, 101);
    expect(provider.selectedPayment?.status, 'verified');

    final rejectSuccess = await provider.rejectPayment(
      101,
      reason: 'Bukti buram',
    );
    expect(rejectSuccess, isTrue);
    expect(fakeService.rejectCalled, isTrue);
    expect(fakeService.lastReason, 'Bukti buram');
    expect(provider.selectedPayment?.status, 'rejected');
  });

  testWidgets('AdminPaymentsPage displays waiting orders and triggers verify', (
    tester,
  ) async {
    final fakePaymentService = FakePaymentService();
    final fakeOrderService = FakeServiceOrderService();

    final paymentProvider = PaymentProvider(paymentService: fakePaymentService);
    final orderProvider = ServiceOrderProvider(
      serviceOrderService: fakeOrderService,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<PaymentProvider>.value(value: paymentProvider),
          ChangeNotifierProvider<ServiceOrderProvider>.value(
            value: orderProvider,
          ),
        ],
        child: const MaterialApp(home: AdminPaymentsPage()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify UI shows payment card
    expect(find.text('Kelola Pembayaran'), findsOneWidget);
    expect(find.text('Order #101'), findsOneWidget);
    expect(find.text('Verifikasi'), findsOneWidget);
    expect(find.text('Tolak'), findsOneWidget);

    // Tap verify button
    await tester.tap(find.text('Verifikasi'));
    await tester.pumpAndSettle();

    // Dialog appears
    // Tap verify inside dialog
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Verifikasi'),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakePaymentService.verifyCalled, isTrue);
    expect(fakePaymentService.lastId, 101);
  });
}
