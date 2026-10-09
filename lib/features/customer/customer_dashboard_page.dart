import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/confirmation_dialog.dart';
import '../../core/widgets/premium_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/service_status_timeline.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import 'bookings/customer_booking_detail_page.dart';
import 'bookings/customer_bookings_page.dart';
import 'bookings/customer_create_booking_page.dart';
import 'invoices/customer_invoices_page.dart';
import 'vehicles/customer_vehicles_page.dart';
import '../notifications/notification_center_page.dart';

class CustomerDashboardPage extends StatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  State<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends State<CustomerDashboardPage> {
  final int _currentNavIndex = 0;

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
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Konfirmasi Logout',
      content: 'Apakah Anda yakin ingin keluar dari akun ini?',
      confirmText: 'Logout',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _currentNavIndex) return;

    if (index == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CustomerVehiclesPage()));
    } else if (index == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CustomerBookingsPage()));
    } else if (index == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CustomerInvoicesPage()));
    } else if (index == 4) {
      _showProfileSheet();
    }
  }

  void _showProfileSheet() {
    final auth = context.read<AuthProvider>();
    final userName = auth.user?['name'] as String? ?? 'Customer';
    final userEmail = auth.user?['email'] as String? ?? '-';
    final userPhone = auth.user?['phone'] as String? ?? '-';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.border),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.phone_outlined,
                    color: AppColors.secondary,
                  ),
                  title: const Text('No. Handphone'),
                  subtitle: Text(userPhone),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  title: const Text('Lokasi Layanan'),
                  subtitle: const Text('Kota Tanjungpinang, Kepulauan Riau'),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Logout Akun',
                  icon: Icons.logout,
                  backgroundColor: AppColors.error,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<DashboardProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final dashboard = provider.dashboard;
    final userName = auth.user?['name'] as String? ?? 'Customer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppAvatarHeader(
          name: userName,
          role: 'Customer',
          subtitle: 'Pantau servis & rawat motormu',
          unreadCount: notifProvider.unreadCount,
          onNotificationTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationCenterPage()),
            );
          },
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout, color: AppColors.textSecondary),
              onPressed: auth.isAuthenticated ? _logout : null,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceCard,
        onRefresh: _refresh,
        child: _buildBody(context, provider, dashboard, userName),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: _onBottomNavTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.two_wheeler_outlined),
              activeIcon: Icon(Icons.two_wheeler),
              label: 'Kendaraan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Invoice',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
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
          LoadingState(height: 400, message: 'Memuat data dashboard...'),
        ],
      );
    }

    if (provider.errorMessage != null && dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 60),
          ErrorState(
            title: 'Dashboard Gagal Dimuat',
            message: provider.errorMessage!,
            onRetry: provider.isLoading ? null : _refresh,
          ),
        ],
      );
    }

    if (dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyState(
            height: 350,
            title: 'Data Belum Tersedia',
            message: 'Tarik ke bawah untuk menyegarkan data dashboard.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Hero Card
        _buildHeroBanner(context),
        const SizedBox(height: 20),

        // Quick Actions
        _buildQuickActions(context),
        const SizedBox(height: 24),

        // Summary Stats Grid
        const SectionHeader(
          title: 'Ringkasan Aktivitas',
          subtitle: 'Status menyeluruh akun Anda',
        ),
        _buildSummaryGrid(context, dashboard),
        const SizedBox(height: 24),

        // Active service timeline if there are active bookings or active services
        if ((dashboard.activeBookings ?? 0) > 0 ||
            (dashboard.activeServiceOrders ?? 0) > 0) ...[
          const SectionHeader(
            title: 'Progres Pengerjaan Terkini',
            subtitle: 'Pantau tahapan servis motor Anda',
          ),
          const ServiceStatusTimeline(currentStatus: 'in_progress'),
          const SizedBox(height: 24),
        ],

        // Recent Bookings
        _buildRecentBookings(context, dashboard),
        const SizedBox(height: 24),

        // Latest Delivery
        _buildLatestDelivery(context, dashboard),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF261D15), Color(0xFF191C24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 13, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'BENGKEL RESMI TANJUNGPINANG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Servis Motor Cepat & Terpercaya',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Layanan servis berkala, ganti oli, hingga pickup motor langsung dari lokasi Anda.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Booking Servis Sekarang',
            icon: Icons.calendar_today_rounded,
            height: 46,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CustomerCreateBookingPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickActionItem(
        icon: Icons.add_circle_outline,
        label: 'Booking',
        color: AppColors.primary,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CustomerCreateBookingPage(),
            ),
          );
        },
      ),
      _QuickActionItem(
        icon: Icons.two_wheeler_outlined,
        label: 'Kendaraan',
        color: AppColors.secondary,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerVehiclesPage()),
          );
        },
      ),
      _QuickActionItem(
        icon: Icons.history_outlined,
        label: 'Riwayat',
        color: AppColors.warning,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerBookingsPage()),
          );
        },
      ),
      _QuickActionItem(
        icon: Icons.receipt_long_outlined,
        label: 'Invoice',
        color: AppColors.info,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerInvoicesPage()),
          );
        },
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.map((a) => Expanded(child: a)).toList(),
    );
  }

  Widget _buildSummaryGrid(BuildContext context, Dashboard dashboard) {
    final cards = [
      StatCard(
        icon: Icons.two_wheeler_outlined,
        title: 'Kendaraan',
        value: '${dashboard.vehiclesCount ?? 0}',
        accentColor: AppColors.primary,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerVehiclesPage()),
          );
        },
      ),
      StatCard(
        icon: Icons.calendar_month_outlined,
        title: 'Booking Aktif',
        value: '${dashboard.activeBookings ?? 0}',
        accentColor: AppColors.secondary,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerBookingsPage()),
          );
        },
      ),
      StatCard(
        icon: Icons.build_outlined,
        title: 'Service Aktif',
        value: '${dashboard.activeServiceOrders ?? 0}',
        accentColor: AppColors.warning,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerBookingsPage()),
          );
        },
      ),
      StatCard(
        icon: Icons.payment_outlined,
        title: 'Pembayaran',
        value: '${dashboard.pendingPayments ?? 0}',
        accentColor: AppColors.info,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerInvoicesPage()),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 110,
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
        SectionHeader(
          title: 'Booking Terbaru',
          subtitle: 'Daftar pemesanan servis motor Anda',
          actionLabel: 'Lihat Semua',
          onAction: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerBookingsPage()),
            );
          },
        ),
        if (bookings == null || bookings.isEmpty)
          const EmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Belum Ada Booking',
            message: 'Mulai servis motor Anda sekarang dengan mudah.',
          )
        else
          ...bookings.take(3).map((booking) {
            final title = _value(booking, [
              'nomor_booking',
              'booking_number',
              'id',
            ], 'Booking');
            final status = _value(booking, ['status'], 'unknown');
            final bookingId = int.tryParse(_value(booking, ['id'], '0')) ?? 0;

            return PremiumCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: bookingId > 0
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomerBookingDetailPage(bookingId: bookingId),
                        ),
                      );
                    }
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking #$title',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: ${_formatStatus(status)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: status),
                ],
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
        const SectionHeader(
          title: 'Pickup Terbaru',
          subtitle: 'Status penjemputan dan pengantaran',
        ),
        if (delivery == null)
          const EmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'Belum Ada Pickup',
            message: 'Layanan pickup akan muncul di sini jika dipilih.',
          )
        else
          Builder(
            builder: (context) {
              final id = _value(delivery, ['id', 'delivery_task_id'], '');
              final status = _value(delivery, ['status'], 'unknown');

              return PremiumCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: AppColors.secondary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            id.isEmpty ? 'Pickup Motor' : 'Pickup #$id',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status: ${_formatStatus(status)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
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

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
