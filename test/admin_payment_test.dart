import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/features/admin/payments/admin_payments_page.dart';
import 'package:mb_engkelqq_mobile/models/booking.dart';
import 'package:mb_engkelqq_mobile/models/payment.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
import 'package:mb_engkelqq_mobile/providers/booking_provider.dart';
import 'package:mb_engkelqq_mobile/providers/payment_provider.dart';
import 'package:mb_engkelqq_mobile/providers/service_order_provider.dart';
import 'package:mb_engkelqq_mobile/services/booking_service.dart';
import 'package:mb_engkelqq_mobile/services/payment_service.dart';
import 'package:mb_engkelqq_mobile/services/service_order_service.dart';
import 'package:provider/provider.dart';

class FakePaymentService extends PaymentService {
  bool verifyCalled = false;
  bool rejectCalled = false;
  int? lastId;
  String? lastReason;

  @override
  Future<Payment> getPayment(int paymentId) async {
    return Payment(
      id: paymentId,
      serviceOrderId: 101,
      amount: 150000,
      method: 'transfer',
      status: 'waiting_verification',
      hasProof: true,
      notes: 'Transfer via BCA',
    );
  }

  @override
  Future<Payment> verifyPayment(int id) async {
    verifyCalled = true;
    lastId = id;
    return Payment(
      id: id,
      serviceOrderId: 101,
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
      serviceOrderId: 101,
      amount: 150000,
      status: 'rejected',
      notes: reason,
    );
  }
}

class FakeBookingService extends BookingService {
  @override
  Future<List<Booking>> getBookings() async {
    return [
      const Booking(
        id: 42,
        vehicleId: 1,
        nomorBooking: 'MC202610010001',
        status: 'waiting_payment',
        tanggal: '2026-10-09',
        waktu: '10:00',
        jenisLayanan: 'Servis Ringan',
      ),
      const Booking(
        id: 43,
        vehicleId: 1,
        nomorBooking: 'MC202610010002',
        status: 'paid',
        tanggal: '2026-10-08',
        waktu: '14:00',
        jenisLayanan: 'Ganti Ban',
      ),
    ];
  }
}

class FakeServiceOrderService extends ServiceOrderService {
  @override
  Future<List<ServiceOrder>> getServiceOrders() async {
    return [
      const ServiceOrder(
        id: 101,
        bookingId: 42,
        status: 'completed',
        grandTotal: 150000,
        diagnosis: 'Ganti oli dan busi',
      ),
      const ServiceOrder(
        id: 102,
        bookingId: 43,
        status: 'completed',
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

    final verifySuccess = await provider.verifyPayment(7);
    expect(verifySuccess, isTrue);
    expect(fakeService.verifyCalled, isTrue);
    expect(fakeService.lastId, 7);
    expect(provider.selectedPayment?.status, 'verified');

    final rejectSuccess = await provider.rejectPayment(
      7,
      reason: 'Bukti buram',
    );
    expect(rejectSuccess, isTrue);
    expect(fakeService.rejectCalled, isTrue);
    expect(fakeService.lastReason, 'Bukti buram');
    expect(provider.selectedPayment?.status, 'rejected');
  });

  testWidgets(
    'AdminPaymentsPage displays bookings waiting for payment and triggers verify with genuine Payment ID',
    (tester) async {
      final fakePaymentService = FakePaymentService();
      final fakeBookingService = FakeBookingService();
      final fakeOrderService = FakeServiceOrderService();

      final paymentProvider = PaymentProvider(
        paymentService: fakePaymentService,
      );
      final bookingProvider = BookingProvider(
        bookingService: fakeBookingService,
      );
      final orderProvider = ServiceOrderProvider(
        serviceOrderService: fakeOrderService,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PaymentProvider>.value(
              value: paymentProvider,
            ),
            ChangeNotifierProvider<BookingProvider>.value(
              value: bookingProvider,
            ),
            ChangeNotifierProvider<ServiceOrderProvider>.value(
              value: orderProvider,
            ),
          ],
          child: const MaterialApp(home: AdminPaymentsPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Memverifikasi tampilan UI daftar pembayaran berbasis resource Booking
      expect(find.text('Kelola Pembayaran'), findsOneWidget);
      expect(find.text('Booking #MC202610010001'), findsOneWidget);
      expect(find.text('Service Order #101'), findsOneWidget);
      expect(find.text('Rp 150.000'), findsOneWidget);
      expect(find.text('Verifikasi Pembayaran'), findsOneWidget);

      // Menekan tombol verifikasi pembayaran
      await tester.tap(find.text('Verifikasi Pembayaran'));
      await tester.pumpAndSettle();

      // Dialog verifikasi muncul meminta input ID Pembayaran resmi
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('ID Pembayaran (Payment ID)'), findsOneWidget);

      // Memasukkan Payment ID = 7 (berbeda dari order.id 101 dan booking.id 42)
      await tester.enterText(find.byType(TextField), '7');
      await tester.pumpAndSettle();

      // Menekan tombol Verifikasi di dalam dialog
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.widgetWithText(FilledButton, 'Verifikasi'),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan endpoint dipanggil dengan Payment ID = 7, bukan ID resource lain
      expect(fakePaymentService.verifyCalled, isTrue);
      expect(fakePaymentService.lastId, 7);
    },
  );

  testWidgets(
    'AdminPaymentsPage filter tabs switch between waiting and verified bookings',
    (tester) async {
      final fakePaymentService = FakePaymentService();
      final fakeBookingService = FakeBookingService();
      final fakeOrderService = FakeServiceOrderService();

      final paymentProvider = PaymentProvider(
        paymentService: fakePaymentService,
      );
      final bookingProvider = BookingProvider(
        bookingService: fakeBookingService,
      );
      final orderProvider = ServiceOrderProvider(
        serviceOrderService: fakeOrderService,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PaymentProvider>.value(
              value: paymentProvider,
            ),
            ChangeNotifierProvider<BookingProvider>.value(
              value: bookingProvider,
            ),
            ChangeNotifierProvider<ServiceOrderProvider>.value(
              value: orderProvider,
            ),
          ],
          child: const MaterialApp(home: AdminPaymentsPage()),
        ),
      );

      await tester.pumpAndSettle();

      // Tab default adalah 'Menunggu'
      expect(find.text('Booking #MC202610010001'), findsOneWidget);
      expect(find.text('Booking #MC202610010002'), findsNothing);

      // Beralih ke tab 'Terverifikasi'
      await tester.tap(find.text('Terverifikasi'));
      await tester.pumpAndSettle();

      // Menampilkan booking berstatus 'paid'
      expect(find.text('Booking #MC202610010001'), findsNothing);
      expect(find.text('Booking #MC202610010002'), findsOneWidget);
      expect(find.text('Pembayaran Terverifikasi'), findsOneWidget);
    },
  );
}
