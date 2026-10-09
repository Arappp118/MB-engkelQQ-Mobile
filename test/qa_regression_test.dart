import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/core/errors/api_exception.dart';
import 'package:mb_engkelqq_mobile/features/mechanic/mechanic_dashboard_page.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
import 'package:mb_engkelqq_mobile/models/service_order_item.dart';
import 'package:mb_engkelqq_mobile/providers/auth_provider.dart';
import 'package:mb_engkelqq_mobile/providers/booking_provider.dart';
import 'package:mb_engkelqq_mobile/providers/dashboard_provider.dart';
import 'package:mb_engkelqq_mobile/providers/delivery_provider.dart';
import 'package:mb_engkelqq_mobile/providers/invoice_provider.dart';
import 'package:mb_engkelqq_mobile/providers/notification_provider.dart';
import 'package:mb_engkelqq_mobile/providers/payment_provider.dart';
import 'package:mb_engkelqq_mobile/providers/service_order_provider.dart';
import 'package:mb_engkelqq_mobile/providers/vehicle_provider.dart';
import 'package:mb_engkelqq_mobile/services/auth_service.dart';
import 'package:mb_engkelqq_mobile/services/service_order_service.dart';
import 'package:provider/provider.dart';

class MockAuthService extends AuthService {
  bool logoutCalled = false;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<String?> getStoredToken() async => null;

  @override
  Future<String?> getStoredUser() async => null;
}

class FakeMechanicServiceOrderService extends ServiceOrderService {
  final Map<int, ServiceOrder> orders;
  bool startCalled = false;
  bool completeCalled = false;
  bool shouldThrow422OnComplete;

  FakeMechanicServiceOrderService({
    required this.orders,
    this.shouldThrow422OnComplete = false,
  });

  @override
  Future<List<ServiceOrder>> getServiceOrders() async {
    return orders.values.toList();
  }

  @override
  Future<ServiceOrder> getServiceOrder(int id) async {
    final order = orders[id];
    if (order == null) {
      throw const ApiException(statusCode: 404, message: 'Not found');
    }
    return order;
  }

  @override
  Future<ServiceOrder> startServiceOrder(int id) async {
    startCalled = true;
    final order = orders[id]!;
    final updated = ServiceOrder(
      id: order.id,
      bookingId: order.bookingId,
      customerId: order.customerId,
      mechanicId: order.mechanicId,
      status: 'in_progress',
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      grandTotal: order.grandTotal,
      diagnosis: order.diagnosis,
      notes: order.notes,
      items: order.items,
    );
    orders[id] = updated;
    return updated;
  }

  @override
  Future<ServiceOrder> completeServiceOrder(int id) async {
    completeCalled = true;
    if (shouldThrow422OnComplete) {
      throw const ApiException(
        statusCode: 422,
        message: 'BR-012: Minimal satu tindakan servis harus dipilih.',
      );
    }
    final order = orders[id]!;
    final updated = ServiceOrder(
      id: order.id,
      bookingId: order.bookingId,
      customerId: order.customerId,
      mechanicId: order.mechanicId,
      status: 'completed',
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      grandTotal: order.grandTotal,
      diagnosis: order.diagnosis,
      notes: order.notes,
      items: order.items,
    );
    orders[id] = updated;
    return updated;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QA Regression - ApiException Error Extraction Tests', () {
    test(
      'extractMessage returns clean message from ApiException with status code',
      () {
        const err401 = ApiException(
          message: 'Email atau password salah.',
          statusCode: 401,
        );
        expect(
          ApiException.extractMessage(err401),
          'Email atau password salah.',
        );

        const err422 = ApiException(
          message: 'Validasi gagal: format email tidak valid.',
          statusCode: 422,
        );
        expect(
          ApiException.extractMessage(err422),
          'Validasi gagal: format email tidak valid.',
        );

        const err500 = ApiException(
          message: 'Terjadi kesalahan pada server.',
          statusCode: 500,
        );
        expect(
          ApiException.extractMessage(err500),
          'Terjadi kesalahan pada server.',
        );
      },
    );

    test('extractMessage cleans raw exception prefixes', () {
      final exc = Exception('Koneksi terputus');
      expect(ApiException.extractMessage(exc), 'Koneksi terputus');

      const socketErr = SocketException('Failed host lookup');
      expect(
        ApiException.extractMessage(socketErr),
        contains('Failed host lookup'),
      );
    });
  });

  group('QA Regression - Mechanic Service Order Status Transition Tests', () {
    Widget buildDetailPage(ServiceOrderProvider provider, int id) {
      return MaterialApp(
        home: ChangeNotifierProvider<ServiceOrderProvider>.value(
          value: provider,
          child: MechanicServiceDetailPage(serviceOrderId: id),
        ),
      );
    }

    testWidgets('pending: tombol mulai servis tersedia dan dapat ditekan', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeService = FakeMechanicServiceOrderService(
        orders: {
          101: const ServiceOrder(
            id: 101,
            bookingId: 10,
            customerId: 1,
            mechanicId: 2,
            status: 'pending',
          ),
        },
      );
      final provider = ServiceOrderProvider(serviceOrderService: fakeService);
      await provider.loadServiceOrder(101);

      await tester.pumpWidget(buildDetailPage(provider, 101));
      await tester.pumpAndSettle();

      expect(find.text('Mulai Service'), findsOneWidget);
      expect(
        find.textContaining('Status service order adalah assigned'),
        findsNothing,
      );
      expect(find.text('Selesaikan Service'), findsNothing);

      await tester.tap(find.text('Mulai Service'));
      await tester.pumpAndSettle();

      expect(fakeService.startCalled, isTrue);
    });

    testWidgets(
      'assigned: banner tampil dan tombol mulai servis tidak tersedia',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeMechanicServiceOrderService(
          orders: {
            102: const ServiceOrder(
              id: 102,
              bookingId: 11,
              customerId: 1,
              mechanicId: 2,
              status: 'assigned',
            ),
          },
        );
        final provider = ServiceOrderProvider(serviceOrderService: fakeService);
        await provider.loadServiceOrder(102);

        await tester.pumpWidget(buildDetailPage(provider, 102));
        await tester.pumpAndSettle();

        expect(find.text('Mulai Service'), findsNothing);
        expect(
          find.textContaining('Status service order adalah assigned'),
          findsOneWidget,
        );
        expect(find.text('Selesaikan Service'), findsNothing);
      },
    );

    testWidgets(
      'in_progress dengan item kosong: tombol selesaikan servis nonaktif (BR-012)',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeMechanicServiceOrderService(
          orders: {
            103: const ServiceOrder(
              id: 103,
              bookingId: 12,
              customerId: 1,
              mechanicId: 2,
              status: 'in_progress',
              diagnosis: 'Pemeriksaan rem dan busi',
              items: [],
            ),
          },
        );
        final provider = ServiceOrderProvider(serviceOrderService: fakeService);
        await provider.loadServiceOrder(103);

        await tester.pumpWidget(buildDetailPage(provider, 103));
        await tester.pumpAndSettle();

        expect(find.text('Mulai Service'), findsNothing);
        expect(find.text('Selesaikan Service'), findsOneWidget);

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Selesaikan Service'),
        );
        expect(button.onPressed, isNull);

        expect(
          find.textContaining('Belum ada service item/tindakan service'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'in_progress dengan diagnosis dan item: aksi penyelesaian aktif',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fakeService = FakeMechanicServiceOrderService(
          orders: {
            104: const ServiceOrder(
              id: 104,
              bookingId: 13,
              customerId: 1,
              mechanicId: 2,
              status: 'in_progress',
              diagnosis: 'Ganti oli mesin',
              items: [
                ServiceOrderItem(
                  name: 'Oli MPX 1',
                  price: 55000,
                  quantity: 1,
                  subtotal: 55000,
                ),
              ],
            ),
          },
        );
        final provider = ServiceOrderProvider(serviceOrderService: fakeService);
        await provider.loadServiceOrder(104);

        await tester.pumpWidget(buildDetailPage(provider, 104));
        await tester.pumpAndSettle();

        expect(find.text('Selesaikan Service'), findsOneWidget);

        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Selesaikan Service'),
        );
        expect(button.onPressed, isNotNull);

        await tester.tap(find.text('Selesaikan Service'));
        await tester.pumpAndSettle();

        expect(fakeService.completeCalled, isTrue);
        expect(find.text('Service telah selesai.'), findsOneWidget);
      },
    );

    test('HTTP 422 saat completion: aplikasi tidak menandai order sebagai completed', () async {
      final fakeService = FakeMechanicServiceOrderService(
        orders: {
          105: const ServiceOrder(
            id: 105,
            bookingId: 14,
            customerId: 1,
            mechanicId: 2,
            status: 'in_progress',
            diagnosis: 'Ganti oli',
            items: [],
          ),
        },
        shouldThrow422OnComplete: true,
      );
      final provider = ServiceOrderProvider(serviceOrderService: fakeService);

      await provider.loadServiceOrder(105);
      expect(provider.selectedServiceOrder?.status, 'in_progress');

      final success = await provider.completeServiceOrder(105);
      expect(success, isFalse);

      // Memastikan status tidak berubah ke completed
      expect(provider.selectedServiceOrder?.status, 'in_progress');
      expect(provider.errorMessage, contains('BR-012'));
    });
  });

  group('QA Regression - Session Lifecycle & State Cleanup Tests', () {
    test(
      'authProvider logout invokes all registered provider cleanup callbacks',
      () async {
        final mockAuth = MockAuthService();
        final authProvider = AuthProvider(authService: mockAuth);

        final bookingProvider = BookingProvider();
        final vehicleProvider = VehicleProvider();
        final deliveryProvider = DeliveryProvider();
        final serviceOrderProvider = ServiceOrderProvider();
        final invoiceProvider = InvoiceProvider();
        final paymentProvider = PaymentProvider();
        final notificationProvider = NotificationProvider();
        final dashboardProvider = DashboardProvider();

        bool callbacksInvoked = false;

        authProvider.registerLogoutCallback(() {
          callbacksInvoked = true;
          bookingProvider.clearBookings();
          vehicleProvider.clearVehicles();
          deliveryProvider.clearDeliveryTasks();
          serviceOrderProvider.clearServiceOrders();
          invoiceProvider.clearInvoices();
          paymentProvider.clearPayment();
          notificationProvider.clearNotifications();
          dashboardProvider.clearDashboard();
        });

        await authProvider.logout();

        expect(mockAuth.logoutCalled, isTrue);
        expect(callbacksInvoked, isTrue);
        expect(bookingProvider.bookings, isEmpty);
        expect(vehicleProvider.vehicles, isEmpty);
        expect(deliveryProvider.deliveryTasks, isEmpty);
        expect(serviceOrderProvider.serviceOrders, isEmpty);
        expect(invoiceProvider.invoices, isEmpty);
        expect(notificationProvider.notifications, isEmpty);
        expect(dashboardProvider.dashboard, isNull);
      },
    );
  });
}
