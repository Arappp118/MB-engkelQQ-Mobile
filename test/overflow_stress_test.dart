import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mb_engkelqq_mobile/features/auth/login_page.dart';
import 'package:mb_engkelqq_mobile/features/settings/api_settings_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/customer_dashboard_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/vehicles/customer_vehicles_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/vehicles/vehicle_form_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/bookings/customer_create_booking_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/bookings/customer_booking_detail_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/payments/customer_payment_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/invoices/customer_invoices_page.dart';
import 'package:mb_engkelqq_mobile/features/mechanic/mechanic_dashboard_page.dart';
import 'package:mb_engkelqq_mobile/models/service_order.dart';
import 'package:mb_engkelqq_mobile/models/vehicle.dart';
import 'package:mb_engkelqq_mobile/features/admin/bookings/admin_bookings_page.dart';
import 'package:mb_engkelqq_mobile/features/admin/delivery/admin_delivery_tasks_page.dart';
import 'package:mb_engkelqq_mobile/features/admin/payments/admin_payments_page.dart';
import 'package:mb_engkelqq_mobile/features/courier/courier_dashboard_page.dart';
import 'package:mb_engkelqq_mobile/features/notifications/notification_center_page.dart';

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
import 'package:mb_engkelqq_mobile/services/booking_service.dart';
import 'package:mb_engkelqq_mobile/services/dashboard_service.dart';
import 'package:mb_engkelqq_mobile/services/delivery_service.dart';
import 'package:mb_engkelqq_mobile/services/invoice_service.dart';
import 'package:mb_engkelqq_mobile/services/notification_service.dart';
import 'package:mb_engkelqq_mobile/services/payment_service.dart';
import 'package:mb_engkelqq_mobile/services/service_order_service.dart';
import 'package:mb_engkelqq_mobile/services/vehicle_service.dart';

class _FakeAuthService extends AuthService {}
class _FakeBookingService extends BookingService {}
class _FakeDashboardService extends DashboardService {}
class _FakeDeliveryService extends DeliveryService {}
class _FakeInvoiceService extends InvoiceService {}
class _FakeNotificationService extends NotificationService {}
class _FakePaymentService extends PaymentService {}
class _FakeServiceOrderService extends ServiceOrderService {}
class _FakeVehicleService extends VehicleService {
  @override
  Future<List<Vehicle>> getVehicles() async {
    return [
      Vehicle(
        id: 1,
        userId: 1,
        nomorPolisi: 'BP 1234 XY',
        merk: 'Honda',
        model: 'Vario 150 CBS ISS Street Extra Edition Special 2024',
      ),
    ];
  }
}

Widget buildTestApp(Widget child, {double width = 360, double textScale = 1.0}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider(authService: _FakeAuthService())),
      ChangeNotifierProvider(create: (_) => BookingProvider(bookingService: _FakeBookingService())),
      ChangeNotifierProvider(create: (_) => DashboardProvider(dashboardService: _FakeDashboardService())),
      ChangeNotifierProvider(create: (_) => DeliveryProvider(deliveryService: _FakeDeliveryService())),
      ChangeNotifierProvider(create: (_) => InvoiceProvider(invoiceService: _FakeInvoiceService())),
      ChangeNotifierProvider(create: (_) => NotificationProvider(notificationService: _FakeNotificationService())),
      ChangeNotifierProvider(create: (_) => PaymentProvider(paymentService: _FakePaymentService())),
      ChangeNotifierProvider(create: (_) => ServiceOrderProvider(serviceOrderService: _FakeServiceOrderService())),
      ChangeNotifierProvider(create: (_) => VehicleProvider(vehicleService: _FakeVehicleService())),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: Size(width, 700),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        home: child,
      ),
    ),
  );
}

void main() {
  group('Zero Overflow Stress Tests (Narrow Viewports & High Text Scaling)', () {
    testWidgets('LoginPage renders without overflow on 320px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginPage(), width: 320, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('LoginPage Forgot Password sheet opens without overflow on 320px viewport', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginPage(), width: 320, textScale: 1.3));
      await tester.pump();
      final forgotBtn = find.text('Lupa Password?');
      expect(forgotBtn, findsOneWidget);
      await tester.ensureVisible(forgotBtn);
      await tester.pumpAndSettle();
      await tester.tap(forgotBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text('Petunjuk Reset Password:'), findsOneWidget);
    });

    testWidgets('LoginPage Register sheet opens without overflow on 320px viewport', (tester) async {
      await tester.pumpWidget(buildTestApp(const LoginPage(), width: 320, textScale: 1.3));
      await tester.pump();
      final registerBtn = find.text('Daftar Sekarang');
      expect(registerBtn, findsOneWidget);
      await tester.ensureVisible(registerBtn);
      await tester.pumpAndSettle();
      await tester.tap(registerBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      expect(find.text('Tahapan Pendaftaran Pelanggan:'), findsOneWidget);
    });

    testWidgets('ApiSettingsPage renders without overflow on 320px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const ApiSettingsPage(), width: 320, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerDashboardPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const CustomerDashboardPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerVehiclesPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const CustomerVehiclesPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerCreateBookingPage renders without overflow on 320px viewport with 1.3x text scale', (tester) async {
      final app = buildTestApp(const CustomerCreateBookingPage(), width: 320, textScale: 1.3);
      await tester.pumpWidget(app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('VehicleFormPage renders without overflow on 320px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const VehicleFormPage(), width: 320, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerInvoicesPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const CustomerInvoicesPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminBookingsPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const AdminBookingsPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminPaymentsPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const AdminPaymentsPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('AdminDeliveryTasksPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const AdminDeliveryTasksPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerBookingDetailPage renders without overflow on 320px viewport with 1.3x text scale', (tester) async {
      final app = buildTestApp(const CustomerBookingDetailPage(bookingId: 1), width: 320, textScale: 1.3);
      await tester.pumpWidget(app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerPaymentPage renders without overflow on 320px viewport with 1.3x text scale', (tester) async {
      final order = ServiceOrder(
        id: 1,
        bookingId: 1,
        status: 'service_completed',
        subtotal: 100000,
        deliveryFee: 15000,
        grandTotal: 115000,
      );
      final app = buildTestApp(CustomerPaymentPage(serviceOrder: order), width: 320, textScale: 1.3);
      await tester.pumpWidget(app);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('MechanicDashboardPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const MechanicDashboardPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('CourierDashboardPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const CourierDashboardPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('NotificationCenterPage renders without overflow on 360px viewport with 1.3x text scale', (tester) async {
      await tester.pumpWidget(buildTestApp(const NotificationCenterPage(), width: 360, textScale: 1.3));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });
  });
}
