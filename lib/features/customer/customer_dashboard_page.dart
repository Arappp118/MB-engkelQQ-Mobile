import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bookings/customer_bookings_page.dart';
import 'invoices/customer_invoices_page.dart';
import 'vehicles/customer_vehicles_page.dart';
import '../notifications/notification_center_page.dart';

import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().loadDashboard();
        context.read<NotificationProvider>().loadUnreadNotifications();
      }
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<DashboardProvider>().loadDashboard(),
      context.read<NotificationProvider>().loadUnreadNotifications(),
    ]);
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<DashboardProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final dashboard = provider.dashboard;
    final userName = auth.user?['name'] as String? ?? 'Customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MB-engkelQQ'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterPage(),
                ),
              );
            },
            icon: Badge(
              isLabelVisible: notifProvider.unreadCount > 0,
              label: Text('${notifProvider.unreadCount}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Invoice Saya',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerInvoicesPage()),
              );
            },
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          IconButton(
            tooltip: 'Booking Saya',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerBookingsPage()),
              );
            },
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Kendaraan Saya',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerVehiclesPage()),
              );
            },
            icon: const Icon(Icons.two_wheeler_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: auth.isAuthenticated ? _logout : null,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _buildBody(context, provider, dashboard, userName),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    DashboardProvider provider,
    Dashboard? dashboard,
    String userName,
  ) {
    if (provider.isLoading && dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 400,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (provider.errorMessage != null && dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.cloud_off_outlined, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Dashboard tidak dapat dimuat',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(provider.errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: provider.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      );
    }

    if (dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 300,
            child: Center(child: Text('Data dashboard belum tersedia.')),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Halo, $userName 👋',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Pantau kendaraan dan layanan servis kamu.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        _buildSummaryGrid(dashboard),
        const SizedBox(height: 24),
        _buildRecentBookings(context, dashboard),
        const SizedBox(height: 24),
        _buildLatestDelivery(context, dashboard),
      ],
    );
  }

  Widget _buildSummaryGrid(Dashboard dashboard) {
    final cards = [
      _SummaryCard(
        icon: Icons.two_wheeler_outlined,
        title: 'Kendaraan',
        value: '${dashboard.vehiclesCount ?? 0}',
      ),
      _SummaryCard(
        icon: Icons.calendar_month_outlined,
        title: 'Booking Aktif',
        value: '${dashboard.activeBookings ?? 0}',
      ),
      _SummaryCard(
        icon: Icons.build_outlined,
        title: 'Service Aktif',
        value: '${dashboard.activeServiceOrders ?? 0}',
      ),
      _SummaryCard(
        icon: Icons.payment_outlined,
        title: 'Pembayaran',
        value: '${dashboard.pendingPayments ?? 0}',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 145,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildRecentBookings(BuildContext context, Dashboard dashboard) {
    final bookings = dashboard.recentBookings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Booking Terbaru',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (bookings == null || bookings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Belum ada booking terbaru.'),
            ),
          )
        else
          ...bookings.take(3).map((booking) {
            final title = _value(booking, [
              'nomor_booking',
              'booking_number',
              'id',
            ], 'Booking');
            final status = _value(booking, ['status'], 'unknown');

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.calendar_today_outlined),
                ),
                title: Text('Booking #$title'),
                subtitle: Text('Status: ${_formatStatus(status)}'),
                trailing: _StatusBadge(status: status),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildLatestDelivery(BuildContext context, Dashboard dashboard) {
    final delivery = dashboard.latestDelivery;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup Terbaru',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (delivery == null)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Belum ada pickup terbaru.'),
            ),
          )
        else
          Builder(
            builder: (context) {
              final id = _value(delivery, ['id', 'delivery_task_id'], '');
              final status = _value(delivery, ['status'], 'unknown');

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_shipping_outlined),
                  ),
                  title: Text(id.isEmpty ? 'Pickup' : 'Pickup #$id'),
                  subtitle: Text('Status: ${_formatStatus(status)}'),
                  trailing: _StatusBadge(status: status),
                ),
              );
            },
          ),
      ],
    );
  }

  String _value(dynamic data, List<String> keys, String fallback) {
    if (data is Map) {
      for (final key in keys) {
        final value = data[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return fallback;
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 8),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');

    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
