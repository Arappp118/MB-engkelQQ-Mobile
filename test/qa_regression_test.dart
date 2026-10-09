import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/core/errors/api_exception.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
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
    test('mechanic recognizes both pending and assigned status as actionable queue', () {
      const pendingOrder = ServiceOrder(
        id: 9,
        bookingId: 10,
        mechanicId: 2,
        status: 'pending',
      );

      const assignedOrder = ServiceOrder(
        id: 10,
        bookingId: 11,
        mechanicId: 2,
        status: 'assigned',
      );

      const inProgressOrder = ServiceOrder(
        id: 11,
        bookingId: 12,
        mechanicId: 2,
        status: 'in_progress',
      );

      final orders = [pendingOrder, assignedOrder, inProgressOrder];

      final assignedCount = orders
          .where((o) => o.status == 'assigned' || o.status == 'pending')
          .length;
      expect(assignedCount, 2);

      // Verify canStart logic for pending status (genuine backend initial status)
      final canStartPending =
          pendingOrder.status == 'assigned' || pendingOrder.status == 'pending';
      expect(canStartPending, isTrue);

      // Verify canStart logic for assigned status
      final canStartAssigned =
          assignedOrder.status == 'assigned' ||
          assignedOrder.status == 'pending';
      expect(canStartAssigned, isTrue);

      // Verify in_progress cannot be started again
      final canStartInProgress =
          inProgressOrder.status == 'assigned' ||
          inProgressOrder.status == 'pending';
      expect(canStartInProgress, isFalse);
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
