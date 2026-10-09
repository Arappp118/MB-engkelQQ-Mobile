import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_page.dart';
import '../../features/customer/customer_dashboard_page.dart';
import '../../features/customer/invoices/customer_invoices_page.dart';
import '../../features/customer/invoices/customer_invoice_detail_page.dart';
import '../../features/notifications/notification_center_page.dart';
import '../../features/admin/bookings/admin_bookings_page.dart';
import '../../features/admin/delivery/admin_delivery_tasks_page.dart';
import '../../features/admin/payments/admin_payments_page.dart';
import '../../features/mechanic/mechanic_dashboard_page.dart';
import '../../features/courier/courier_dashboard_page.dart';
import '../../features/maps/interactive_map_page.dart';
import '../../providers/auth_provider.dart';

class AppRouter {
  AppRouter({required this.authProvider}) {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: _redirect,
      routes: [
        // ==========================================================
        // LOGIN
        // ==========================================================

        GoRoute(
          path: '/login',
          builder: (context, state) {
            return const LoginPage();
          },
        ),

        // ==========================================================
        // CUSTOMER
        // ==========================================================
        GoRoute(
          path: '/customer',
          builder: (context, state) {
            return const CustomerDashboardPage();
          },
        ),

        GoRoute(
          path: '/customer/invoices',
          builder: (context, state) {
            return const CustomerInvoicesPage();
          },
        ),

        GoRoute(
          path: '/customer/invoices/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return CustomerInvoiceDetailPage(serviceOrderId: id);
          },
        ),

        // ==========================================================
        // NOTIFICATIONS
        // ==========================================================
        GoRoute(
          path: '/notifications',
          builder: (context, state) {
            return const NotificationCenterPage();
          },
        ),

        // ==========================================================
        // ADMIN
        // ==========================================================
        GoRoute(
          path: '/admin',
          builder: (context, state) {
            return const AdminBookingsPage();
          },
        ),

        GoRoute(
          path: '/admin/delivery',
          builder: (context, state) {
            return const AdminDeliveryTasksPage();
          },
        ),

        GoRoute(
          path: '/admin/payments',
          builder: (context, state) {
            return const AdminPaymentsPage();
          },
        ),

        // ==========================================================
        // MECHANIC
        // ==========================================================
        GoRoute(
          path: '/mechanic',
          builder: (context, state) {
            return const MechanicDashboardPage();
          },
        ),

        // ==========================================================
        // COURIER
        // ==========================================================
        GoRoute(
          path: '/courier',
          builder: (context, state) {
            return const CourierDashboardPage();
          },
        ),

        // ==========================================================
        // MAPS
        // ==========================================================
        GoRoute(
          path: '/maps',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return InteractiveMapPage(
              mode: extra['mode'] == 'picker'
                  ? MapPageMode.picker
                  : MapPageMode.viewer,
              initialLatitude: extra['latitude'] as double?,
              initialLongitude: extra['longitude'] as double?,
              destinationLatitude: extra['destinationLatitude'] as double?,
              destinationLongitude: extra['destinationLongitude'] as double?,
              destinationTitle: extra['destinationTitle'] as String?,
              destinationAddress: extra['destinationAddress'] as String?,
            );
          },
        ),
      ],
    );
  }

  final AuthProvider authProvider;

  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final isAuthenticated = authProvider.isAuthenticated;

    final currentPath = state.uri.path;

    // ==========================================================
    // BELUM LOGIN
    // ==========================================================

    if (!isAuthenticated && currentPath != '/login') {
      return '/login';
    }

    // ==========================================================
    // SUDAH LOGIN
    // ==========================================================

    if (isAuthenticated) {
      if (currentPath == '/login') {
        return _rolePath(authProvider.role);
      }

      final role = authProvider.role;
      if (currentPath.startsWith('/admin') && role != 'admin') {
        return _rolePath(role);
      }
      if (currentPath.startsWith('/mechanic') && role != 'mechanic') {
        return _rolePath(role);
      }
      if (currentPath.startsWith('/courier') && role != 'courier') {
        return _rolePath(role);
      }
      if (currentPath.startsWith('/customer') && role != 'customer') {
        return _rolePath(role);
      }
    }

    return null;
  }

  String _rolePath(String? role) {
    switch (role) {
      case 'customer':
        return '/customer';

      case 'admin':
        return '/admin';

      case 'mechanic':
        return '/mechanic';

      case 'courier':
        return '/courier';

      default:
        return '/login';
    }
  }
}
