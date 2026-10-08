import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routing/app_router.dart';
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

  @override
  void initState() {
    super.initState();

    _authProvider = AuthProvider();

    _appRouter = AppRouter(authProvider: _authProvider);

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
    _appRouter.router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<DashboardProvider>(
          create: (_) => DashboardProvider(),
        ),
        ChangeNotifierProvider<VehicleProvider>(
          create: (_) => VehicleProvider(),
        ),
        ChangeNotifierProvider<BookingProvider>(
          create: (_) => BookingProvider(),
        ),
        ChangeNotifierProvider<DeliveryProvider>(
          create: (_) => DeliveryProvider(),
        ),
        ChangeNotifierProvider<ServiceOrderProvider>(
          create: (_) => ServiceOrderProvider(),
        ),
        ChangeNotifierProvider<PaymentProvider>(
          create: (_) => PaymentProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider<InvoiceProvider>(
          create: (_) => InvoiceProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'MB-engkelQQ Mobile',
        debugShowCheckedModeBanner: false,
        routerConfig: _appRouter.router,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
      ),
    );
  }
}
