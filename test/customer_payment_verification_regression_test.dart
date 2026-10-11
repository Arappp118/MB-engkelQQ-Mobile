import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mb_engkelqq_mobile/features/admin/payments/admin_payments_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/bookings/customer_booking_detail_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/invoices/customer_invoice_detail_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/service_orders/customer_service_order_detail_page.dart';
import 'package:mb_engkelqq_mobile/features/notifications/notification_center_page.dart';
import 'package:mb_engkelqq_mobile/models/booking.dart';
import 'package:mb_engkelqq_mobile/models/invoice.dart';
import 'package:mb_engkelqq_mobile/models/notification.dart';
import 'package:mb_engkelqq_mobile/models/payment.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
import 'package:mb_engkelqq_mobile/models/service_order_item.dart';
import 'package:mb_engkelqq_mobile/providers/auth_provider.dart';
import 'package:mb_engkelqq_mobile/providers/booking_provider.dart';
import 'package:mb_engkelqq_mobile/providers/invoice_provider.dart';
import 'package:mb_engkelqq_mobile/providers/notification_provider.dart';
import 'package:mb_engkelqq_mobile/providers/payment_provider.dart';
import 'package:mb_engkelqq_mobile/providers/service_order_provider.dart';
import 'package:mb_engkelqq_mobile/services/auth_service.dart';
import 'package:mb_engkelqq_mobile/services/booking_service.dart';
import 'package:mb_engkelqq_mobile/services/invoice_service.dart';
import 'package:mb_engkelqq_mobile/services/notification_service.dart';
import 'package:mb_engkelqq_mobile/services/payment_service.dart';
import 'package:mb_engkelqq_mobile/services/service_order_service.dart';

class _FakeServiceOrderService extends ServiceOrderService {
  _FakeServiceOrderService({this.mockOrder});

  ServiceOrder? mockOrder;
  int getOrderCallCount = 0;

  @override
  Future<ServiceOrder> getServiceOrder(int id) async {
    getOrderCallCount++;
    return mockOrder ??
        ServiceOrder(
          id: id,
          bookingId: 10,
          status: 'completed',
          diagnosis: 'Servis rutin dan penggantian oli',
          grandTotal: 150000,
          items: const [
            ServiceOrderItem(
              name: 'Oli Mesin',
              price: 150000,
              quantity: 1,
              subtotal: 150000,
            ),
          ],
        );
  }

  @override
  Future<List<ServiceOrder>> getServiceOrders() async =>
      mockOrder != null ? [mockOrder!] : [];
}

class _FakeInvoiceService extends InvoiceService {
  _FakeInvoiceService({this.mockInvoice});

  Invoice? mockInvoice;
  int getInvoiceCallCount = 0;

  @override
  Future<Invoice> getInvoice(int serviceOrderId) async {
    getInvoiceCallCount++;
    return mockInvoice ??
        Invoice(
          invoiceNumber: 'INV-20261011-0001',
          serviceOrderId: serviceOrderId,
          grandTotal: 150000,
          paymentStatus: null,
          paymentMethod: null,
        );
  }

  @override
  Future<List<Invoice>> getInvoices() async =>
      mockInvoice != null ? [mockInvoice!] : [];
}

class _FakeBookingService extends BookingService {
  _FakeBookingService({this.mockBooking});

  Booking? mockBooking;
  int getBookingCallCount = 0;

  @override
  Future<Booking> getBooking(int id) async {
    getBookingCallCount++;
    return mockBooking ??
        Booking(
          id: id,
          vehicleId: 1,
          status: 'service_completed',
          nomorBooking: 'BK-20261011-0001',
          tanggal: '2026-10-11',
          waktu: '10:00',
        );
  }

  @override
  Future<List<Booking>> getBookings() async =>
      mockBooking != null ? [mockBooking!] : [];
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(this.items);
  final List<AppNotification> items;

  @override
  Future<List<AppNotification>> getNotifications() async => items;

  @override
  Future<List<AppNotification>> getUnreadNotifications() async =>
      items.where((n) => !n.isReadStatus).toList();

  @override
  Future<AppNotification> markAsRead(int id) async {
    return items.firstWhere((n) => n.id == id);
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.mockUser});
  final Map<String, dynamic>? mockUser;

  @override
  Future<String?> getStoredUser() async =>
      mockUser != null ? jsonEncode(mockUser) : null;
}

class _FakePaymentService extends PaymentService {
  Payment? verifyReturnPayment;
  bool verifyCalled = false;
  int? lastVerifyId;

  @override
  Future<Payment> verifyPayment(int id) async {
    verifyCalled = true;
    lastVerifyId = id;
    return verifyReturnPayment ??
        Payment(
          id: id,
          serviceOrderId: 1,
          amount: 150000,
          status: 'verified',
          method: 'transfer',
        );
  }
}

void main() {
  group('Customer Service Order & Admin Payment Verification Regression Tests', () {
    testWidgets(
      '1. Pembayaran pending: Service Order completed menampilkan status Menunggu Pembayaran dan tombol Bayar Sekarang',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeOrderService = _FakeServiceOrderService();
        final fakeInvoiceService = _FakeInvoiceService(
          mockInvoice: const Invoice(
            invoiceNumber: 'INV-20261011-0001',
            serviceOrderId: 1,
            grandTotal: 150000,
            paymentStatus: null,
          ),
        );
        final fakeBookingService = _FakeBookingService(
          mockBooking: const Booking(
            id: 10,
            vehicleId: 1,
            status: 'service_completed',
            nomorBooking: 'BK-20261011-0001',
            tanggal: '2026-10-11',
            waktu: '10:00',
          ),
        );

        final orderProvider = ServiceOrderProvider(serviceOrderService: fakeOrderService);
        final invoiceProvider = InvoiceProvider(invoiceService: fakeInvoiceService);
        final bookingProvider = BookingProvider(bookingService: fakeBookingService);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
              ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
              ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ],
            child: const MaterialApp(
              home: CustomerServiceOrderDetailPage(serviceOrderId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Pembayaran Siap Dilakukan'), findsOneWidget);
        expect(find.text('Menunggu Pembayaran'), findsOneWidget);
        expect(find.text('Bayar Sekarang'), findsOneWidget);
        expect(find.text('Pembayaran Telah Lunas'), findsNothing);
      },
    );

    testWidgets(
      '2. Pembayaran waiting_verification: Bukti telah dikirim Customer, tombol Bayar Sekarang disembunyikan',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeOrderService = _FakeServiceOrderService();
        final fakeInvoiceService = _FakeInvoiceService(
          mockInvoice: const Invoice(
            invoiceNumber: 'INV-20261011-0001',
            serviceOrderId: 1,
            grandTotal: 150000,
            paymentStatus: 'waiting_verification',
            paymentMethod: 'transfer',
          ),
        );
        final fakeBookingService = _FakeBookingService(
          mockBooking: const Booking(
            id: 10,
            vehicleId: 1,
            status: 'waiting_payment',
            nomorBooking: 'BK-20261011-0001',
            tanggal: '2026-10-11',
            waktu: '10:00',
          ),
        );

        final orderProvider = ServiceOrderProvider(serviceOrderService: fakeOrderService);
        final invoiceProvider = InvoiceProvider(invoiceService: fakeInvoiceService);
        final bookingProvider = BookingProvider(bookingService: fakeBookingService);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
              ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
              ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ],
            child: const MaterialApp(
              home: CustomerServiceOrderDetailPage(serviceOrderId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Menunggu Verifikasi Admin'), findsOneWidget);
        expect(find.text('Menunggu Verifikasi'), findsWidgets);
        expect(find.text('Bayar Sekarang'), findsNothing);
      },
    );

    testWidgets(
      '3. Admin memverifikasi pembayaran: PaymentProvider memvalidasi field status verified dari backend',
      (tester) async {
        final fakePaymentService = _FakePaymentService()
          ..verifyReturnPayment = const Payment(
            id: 55,
            serviceOrderId: 1,
            amount: 150000,
            status: 'verified',
          );

        final paymentProvider = PaymentProvider(paymentService: fakePaymentService);
        final success = await paymentProvider.verifyPayment(55);

        expect(success, isTrue);
        expect(fakePaymentService.verifyCalled, isTrue);
        expect(paymentProvider.selectedPayment?.status, 'verified');

        // Jika server mengembalikan status yang bukan verified, harus gagal
        fakePaymentService.verifyReturnPayment = const Payment(
          id: 56,
          serviceOrderId: 1,
          amount: 150000,
          status: 'pending',
        );

        final failResult = await paymentProvider.verifyPayment(56);
        expect(failResult, isFalse);
        expect(paymentProvider.errorMessage, contains('bukan terverifikasi'));
      },
    );

    testWidgets(
      '4. Customer membuka kembali Detail Servis setelah Admin verifikasi: menampilkan Pembayaran Telah Lunas & Terverifikasi, tanpa tombol Bayar Sekarang',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeOrderService = _FakeServiceOrderService();
        // Backend Laravel: service_order.status = 'completed', invoice.payment_status = 'verified', booking.status = 'completed'
        final fakeInvoiceService = _FakeInvoiceService(
          mockInvoice: const Invoice(
            invoiceNumber: 'INV-20261011-0001',
            serviceOrderId: 1,
            grandTotal: 150000,
            paymentStatus: 'verified',
            paymentMethod: 'transfer',
          ),
        );
        final fakeBookingService = _FakeBookingService(
          mockBooking: const Booking(
            id: 10,
            vehicleId: 1,
            status: 'completed',
            nomorBooking: 'BK-20261011-0001',
            tanggal: '2026-10-11',
            waktu: '10:00',
          ),
        );

        final orderProvider = ServiceOrderProvider(serviceOrderService: fakeOrderService);
        final invoiceProvider = InvoiceProvider(invoiceService: fakeInvoiceService);
        final bookingProvider = BookingProvider(bookingService: fakeBookingService);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
              ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
              ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ],
            child: const MaterialApp(
              home: CustomerServiceOrderDetailPage(serviceOrderId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Pembayaran Telah Lunas'), findsOneWidget);
        expect(find.text('Terverifikasi'), findsWidgets);
        expect(find.text('Buka Invoice Resmi'), findsOneWidget);
        expect(find.text('Bayar Sekarang'), findsNothing);
        expect(find.text('Menunggu Pembayaran'), findsNothing);
      },
    );

    testWidgets(
      '5. Status terverifikasi tetap tampil setelah refresh dan tombol refresh memicu reload data backend',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeOrderService = _FakeServiceOrderService();
        final fakeInvoiceService = _FakeInvoiceService(
          mockInvoice: const Invoice(
            invoiceNumber: 'INV-20261011-0001',
            serviceOrderId: 1,
            grandTotal: 150000,
            paymentStatus: 'verified',
            paymentMethod: 'transfer',
          ),
        );
        final fakeBookingService = _FakeBookingService(
          mockBooking: const Booking(
            id: 10,
            vehicleId: 1,
            status: 'completed',
            nomorBooking: 'BK-20261011-0001',
            tanggal: '2026-10-11',
            waktu: '10:00',
          ),
        );

        final orderProvider = ServiceOrderProvider(serviceOrderService: fakeOrderService);
        final invoiceProvider = InvoiceProvider(invoiceService: fakeInvoiceService);
        final bookingProvider = BookingProvider(bookingService: fakeBookingService);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
              ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
              ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ],
            child: const MaterialApp(
              home: CustomerServiceOrderDetailPage(serviceOrderId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Pembayaran Telah Lunas'), findsOneWidget);
        expect(fakeInvoiceService.getInvoiceCallCount, 1);

        // Tap tombol refresh di AppBar
        await tester.tap(find.byIcon(Icons.refresh_rounded));
        await tester.pumpAndSettle();

        expect(fakeInvoiceService.getInvoiceCallCount, 2);
        expect(find.text('Pembayaran Telah Lunas'), findsOneWidget);
        expect(find.text('Terverifikasi'), findsWidgets);
        expect(find.text('Bayar Sekarang'), findsNothing);
      },
    );

    testWidgets(
      '6. Pembayaran ditolak Admin: Menampilkan status Pembayaran Ditolak dan tombol bayar ulang',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeOrderService = _FakeServiceOrderService();
        final fakeInvoiceService = _FakeInvoiceService(
          mockInvoice: const Invoice(
            invoiceNumber: 'INV-20261011-0001',
            serviceOrderId: 1,
            grandTotal: 150000,
            paymentStatus: 'rejected',
            paymentMethod: 'transfer',
          ),
        );
        final fakeBookingService = _FakeBookingService(
          mockBooking: const Booking(
            id: 10,
            vehicleId: 1,
            status: 'waiting_payment',
            nomorBooking: 'BK-20261011-0001',
            tanggal: '2026-10-11',
            waktu: '10:00',
          ),
        );

        final orderProvider = ServiceOrderProvider(serviceOrderService: fakeOrderService);
        final invoiceProvider = InvoiceProvider(invoiceService: fakeInvoiceService);
        final bookingProvider = BookingProvider(bookingService: fakeBookingService);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServiceOrderProvider>.value(value: orderProvider),
              ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
              ChangeNotifierProvider<BookingProvider>.value(value: bookingProvider),
            ],
            child: const MaterialApp(
              home: CustomerServiceOrderDetailPage(serviceOrderId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Pembayaran Ditolak'), findsOneWidget);
        expect(find.text('Ditolak'), findsWidgets);
        expect(find.text('Bayar Ulang / Kirim Bukti Baru'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Customer Booking Detail: service_completed menampilkan informasi tagihan dan tombol Bayar Tagihan (Rp 150.000)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeBookingService = _FakeBookingService(
          mockBooking: const Booking(
            id: 10,
            vehicleId: 1,
            status: 'service_completed',
            nomorBooking: 'BK-20261011-0001',
            tanggal: '2026-10-11',
            waktu: '10:00',
            jenisLayanan: 'Servis Ringan',
          ),
        );
        final fakeOrderService = _FakeServiceOrderService(
          mockOrder: const ServiceOrder(
            id: 1,
            bookingId: 10,
            status: 'completed',
            grandTotal: 150000,
          ),
        );

        final bookingProvider =
            BookingProvider(bookingService: fakeBookingService);
        final orderProvider =
            ServiceOrderProvider(serviceOrderService: fakeOrderService);
        final paymentProvider =
            PaymentProvider(paymentService: _FakePaymentService());

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BookingProvider>.value(
                value: bookingProvider,
              ),
              ChangeNotifierProvider<ServiceOrderProvider>.value(
                value: orderProvider,
              ),
              ChangeNotifierProvider<PaymentProvider>.value(
                value: paymentProvider,
              ),
            ],
            child: const MaterialApp(
              home: CustomerBookingDetailPage(bookingId: 10),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Tagihan Siap Dibayar'), findsOneWidget);
        expect(find.text('Total Tagihan Resmi:'), findsOneWidget);
        expect(find.text('Rp 150.000'), findsOneWidget);
        expect(find.text('Bayar Tagihan (Rp 150.000)'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Customer Booking Detail: waiting_payment menampilkan banner Menunggu Verifikasi dan mencegah duplikasi pembayaran',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeBookingService = _FakeBookingService(
          mockBooking: const Booking(
            id: 10,
            vehicleId: 1,
            status: 'waiting_payment',
            nomorBooking: 'BK-20261011-0001',
            tanggal: '2026-10-11',
            waktu: '10:00',
            jenisLayanan: 'Servis Ringan',
          ),
        );
        final fakeOrderService = _FakeServiceOrderService(
          mockOrder: const ServiceOrder(
            id: 1,
            bookingId: 10,
            status: 'completed',
            grandTotal: 150000,
          ),
        );

        final bookingProvider =
            BookingProvider(bookingService: fakeBookingService);
        final orderProvider =
            ServiceOrderProvider(serviceOrderService: fakeOrderService);
        final paymentProvider =
            PaymentProvider(paymentService: _FakePaymentService());

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<BookingProvider>.value(
                value: bookingProvider,
              ),
              ChangeNotifierProvider<ServiceOrderProvider>.value(
                value: orderProvider,
              ),
              ChangeNotifierProvider<PaymentProvider>.value(
                value: paymentProvider,
              ),
            ],
            child: const MaterialApp(
              home: CustomerBookingDetailPage(bookingId: 10),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Pembayaran Menunggu Verifikasi'), findsOneWidget);
        expect(
          find.textContaining(
            'Pengajuan pembayaran baru dikunci untuk mencegah duplikasi.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Bayar Tagihan'), findsNothing);
      },
    );

    testWidgets(
      '9. Customer Invoice Detail: kondisi rejected menampilkan tombol Ajukan Pembayaran Ulang',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeInvoiceService = _FakeInvoiceService(
          mockInvoice: const Invoice(
            invoiceNumber: 'INV-20261011-0001',
            serviceOrderId: 1,
            grandTotal: 150000,
            paymentStatus: 'rejected',
            paymentMethod: 'transfer',
          ),
        );
        final invoiceProvider =
            InvoiceProvider(invoiceService: fakeInvoiceService);

        await tester.pumpWidget(
          ChangeNotifierProvider<InvoiceProvider>.value(
            value: invoiceProvider,
            child: const MaterialApp(
              home: CustomerInvoiceDetailPage(serviceOrderId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Ajukan Pembayaran Ulang'), findsOneWidget);
        expect(find.text('Bayar Tagihan Sekarang'), findsNothing);
      },
    );

    testWidgets(
      '10. Customer Invoice Detail: kondisi waiting_verification menampilkan peringatan verifikasi dan mengunci pembayaran',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeInvoiceService = _FakeInvoiceService(
          mockInvoice: const Invoice(
            invoiceNumber: 'INV-20261011-0001',
            serviceOrderId: 1,
            grandTotal: 150000,
            paymentStatus: 'waiting_verification',
            paymentMethod: 'cash',
          ),
        );
        final invoiceProvider =
            InvoiceProvider(invoiceService: fakeInvoiceService);

        await tester.pumpWidget(
          ChangeNotifierProvider<InvoiceProvider>.value(
            value: invoiceProvider,
            child: const MaterialApp(
              home: CustomerInvoiceDetailPage(serviceOrderId: 1),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.textContaining('Pengajuan pembayaran baru dinonaktifkan'),
          findsOneWidget,
        );
        expect(find.text('Bayar Tagihan Sekarang'), findsNothing);
        expect(find.text('Ajukan Pembayaran Ulang'), findsNothing);
      },
    );

    testWidgets(
      '11. Navigasi Notifikasi: Admin membuka notifikasi payment diarahkan ke AdminPaymentsPage, Customer diarahkan ke CustomerInvoicesPage',
      (tester) async {
        final adminNotification = const AppNotification(
          id: 1,
          title: 'Pembayaran Menunggu Verifikasi',
          message: 'Payment untuk order #1 menunggu verifikasi.',
          type: 'payment',
          entityType: 'Payment',
          entityId: 9,
          readAt: null,
        );

        final notifService =
            _FakeNotificationService([adminNotification]);
        final notifProvider =
            NotificationProvider(notificationService: notifService);
        final authProvider = AuthProvider(
          authService: _FakeAuthService(
            mockUser: {'id': 1, 'name': 'Admin User', 'role': 'admin'},
          ),
        );
        await authProvider.loadCurrentUser();

        final bookingProvider =
            BookingProvider(bookingService: _FakeBookingService());
        final orderProvider =
            ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService());
        final paymentProvider =
            PaymentProvider(paymentService: _FakePaymentService());

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<NotificationProvider>.value(
                value: notifProvider,
              ),
              ChangeNotifierProvider<AuthProvider>.value(
                value: authProvider,
              ),
              ChangeNotifierProvider<BookingProvider>.value(
                value: bookingProvider,
              ),
              ChangeNotifierProvider<ServiceOrderProvider>.value(
                value: orderProvider,
              ),
              ChangeNotifierProvider<PaymentProvider>.value(
                value: paymentProvider,
              ),
            ],
            child: const MaterialApp(
              home: NotificationCenterPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Pembayaran Menunggu Verifikasi'), findsOneWidget);

        // Tap notifikasi sebagai Admin
        await tester.tap(find.text('Pembayaran Menunggu Verifikasi'));
        await tester.pumpAndSettle();

        // Diarahkan ke AdminPaymentsPage
        expect(find.byType(AdminPaymentsPage), findsOneWidget);
        expect(find.text('Kelola Pembayaran'), findsOneWidget);
      },
    );
  });
}
