import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/delivery_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/service_order_provider.dart';
import 'providers/vehicle_provider.dart';

void main() {
  runApp(const MBEngkelQQApp());
}

class MBEngkelQQApp extends StatefulWidget {
  const MBEngkelQQApp({super.key});

  @override
  State<MBEngkelQQApp> createState() => _MBEngkelQQAppState();
}

class _MBEngkelQQAppState extends State<MBEngkelQQApp> {
  late final AuthProvider _authProvider;
  late final AppRouter _appRouter;
  late final DashboardProvider _dashboardProvider;
  late final VehicleProvider _vehicleProvider;
  late final BookingProvider _bookingProvider;
  late final DeliveryProvider _deliveryProvider;
  late final ServiceOrderProvider _serviceOrderProvider;
  late final PaymentProvider _paymentProvider;
  late final NotificationProvider _notificationProvider;
  late final InvoiceProvider _invoiceProvider;

  @override
  void initState() {
    super.initState();

    _authProvider = AuthProvider();
    _appRouter = AppRouter(authProvider: _authProvider);
    _dashboardProvider = DashboardProvider();
    _vehicleProvider = VehicleProvider();
    _bookingProvider = BookingProvider();
    _deliveryProvider = DeliveryProvider();
    _serviceOrderProvider = ServiceOrderProvider();
    _paymentProvider = PaymentProvider();
    _notificationProvider = NotificationProvider();
    _invoiceProvider = InvoiceProvider();

    _authProvider.registerLogoutCallback(() {
      _dashboardProvider.clearDashboard();
      _vehicleProvider.clearVehicles();
      _bookingProvider.clearBookings();
      _deliveryProvider.clearDeliveryTasks();
      _serviceOrderProvider.clearServiceOrders();
      _paymentProvider.clearPayment();
      _notificationProvider.clearNotifications();
      _invoiceProvider.clearInvoices();
    });

    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final hasSession = await _authProvider.hasSession();

    if (hasSession) {
      await _authProvider.loadCurrentUser();
    }
  }

  @override
  void dispose() {
    _authProvider.dispose();
    _dashboardProvider.dispose();
    _vehicleProvider.dispose();
    _bookingProvider.dispose();
    _deliveryProvider.dispose();
    _serviceOrderProvider.dispose();
    _paymentProvider.dispose();
    _notificationProvider.dispose();
    _invoiceProvider.dispose();
    _appRouter.router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<DashboardProvider>.value(
          value: _dashboardProvider,
        ),
        ChangeNotifierProvider<VehicleProvider>.value(value: _vehicleProvider),
        ChangeNotifierProvider<BookingProvider>.value(value: _bookingProvider),
        ChangeNotifierProvider<DeliveryProvider>.value(
          value: _deliveryProvider,
        ),
        ChangeNotifierProvider<ServiceOrderProvider>.value(
          value: _serviceOrderProvider,
        ),
        ChangeNotifierProvider<PaymentProvider>.value(value: _paymentProvider),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: _notificationProvider,
        ),
        ChangeNotifierProvider<InvoiceProvider>.value(value: _invoiceProvider),
      ],
      child: MaterialApp.router(
        title: 'MB-engkelQQ Mobile',
        debugShowCheckedModeBanner: false,
        routerConfig: _appRouter.router,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
      ),
    );
  }
}
