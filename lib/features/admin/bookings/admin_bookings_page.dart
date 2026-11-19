import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/booking.dart';
import '../../../models/service_order.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/service_order_provider.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage>
    with WidgetsBindingObserver {
  String _selectedFilter = 'all';
  int? _refreshingBookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      context.read<BookingProvider>().loadBookings(),
      context.read<ServiceOrderProvider>().loadServiceOrders(),
      context.read<DashboardProvider>().loadDashboard(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Masuk'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan API',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.push('/api-settings');
            },
          ),
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.go('/admin/payments');
              break;
            case 2:
              context.go('/admin/delivery');
              break;
            case 3:
              context.push('/notifications');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment, color: AppColors.primary),
            label: 'Pembayaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping, color: AppColors.primary),
            label: 'Delivery',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppColors.primary),
            label: 'Notifikasi',
          ),
        ],
      ),
      body: Consumer3<BookingProvider, ServiceOrderProvider, DashboardProvider>(
        builder: (context, bookingProvider, orderService, dashProvider, child) {
          if (bookingProvider.isLoading && bookingProvider.bookings.isEmpty) {
            return const LoadingState(message: 'Memuat data booking...');
          }

          if (bookingProvider.errorMessage != null &&
              bookingProvider.bookings.isEmpty) {
            return ErrorState(
              message: bookingProvider.errorMessage!,
              onRetry: _refreshAll,
            );
          }

          final dash = dashProvider.dashboard;
          final totalBookings =
              dash?.totalBookings ?? bookingProvider.bookings.length;
          final activeBookings = dash?.activeBookings ??
              bookingProvider.bookings
                  .where((b) =>
                      b.status != 'cancelled' && b.status != 'completed')
                  .length;
          final pendingPayments = dash?.paymentPending ?? 0;

          // Map related orders by bookingId for efficient O(1) lookup
          final ordersByBooking = <int, ServiceOrder>{};
          for (final order in orderService.serviceOrders) {
            if (order.bookingId != null) {
              ordersByBooking[order.bookingId!] = order;
            }
          }

          // Filter bookings by selected tab
          final filtered = bookingProvider.bookings.where((b) {
            if (_selectedFilter == 'all') return true;
            if (_selectedFilter == 'pending') return b.status == 'pending';
            if (_selectedFilter == 'active') {
              return b.status != 'cancelled' && b.status != 'completed';
            }
            if (_selectedFilter == 'completed') return b.status == 'completed';
            if (_selectedFilter == 'cancelled') return b.status == 'cancelled';
            return true;
          }).toList();

          return Column(
            children: [
              // Operational Dashboard Overview
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Booking',
                        value: '$totalBookings',
                        icon: Icons.calendar_month,
                        accentColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        title: 'Aktif',
                        value: '$activeBookings',
                        icon: Icons.timelapse,
                        accentColor: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        title: 'Bayar Pending',
                        value: '$pendingPayments',
                        icon: Icons.payment,
                        accentColor: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Filter Chips
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('all', 'Semua (${bookingProvider.bookings.length})'),
                    _buildFilterChip(
                      'pending',
                      'Pending (${bookingProvider.bookings.where((b) => b.status == 'pending').length})',
                    ),
                    _buildFilterChip('active', 'Aktif ($activeBookings)'),
                    _buildFilterChip(
                      'completed',
                      'Selesai (${bookingProvider.bookings.where((b) => b.status == 'completed').length})',
                    ),
                    _buildFilterChip(
                      'cancelled',
                      'Batal (${bookingProvider.bookings.where((b) => b.status == 'cancelled').length})',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // Bookings List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshAll,
                  color: AppColors.primary,
                  child: filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 60),
                            EmptyState(
                              icon: Icons.filter_alt_off_outlined,
                              title: 'Tidak Ada Booking',
                              message: bookingProvider.bookings.isEmpty
                                  ? 'Belum ada booking masuk saat ini.'
                                  : 'Tidak ada data booking dengan filter "${_filterLabel(_selectedFilter)}".',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final booking = filtered[index];
                            final relatedOrder = ordersByBooking[booking.id];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BookingCard(
                                booking: booking,
                                relatedOrder: relatedOrder,
                                isLoading: bookingProvider.isLoading,
                                isRefreshing: _refreshingBookingId == booking.id,
                                onConfirm: () {
                                  _confirmBooking(context, booking);
                                },
                                onRefreshStatus: () {
                                  _refreshSingleBooking(booking);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() => _selectedFilter = key);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _filterLabel(String key) {
    switch (key) {
      case 'pending':
        return 'Pending';
      case 'active':
        return 'Aktif';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Batal';
      default:
        return 'Semua';
    }
  }

  Future<void> _confirmBooking(BuildContext context, Booking booking) async {
    final provider = context.read<BookingProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          actionsOverflowButtonSpacing: 8,
          title: const Text(
            'Konfirmasi Booking',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'Apakah booking #${booking.id} ingin dikonfirmasi?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Konfirmasi'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final success = await provider.confirmBooking(booking.id);

    if (!context.mounted) {
      return;
    }

    if (success) {
      await Future.wait([
        context.read<ServiceOrderProvider>().loadServiceOrders(),
        context.read<DashboardProvider>().loadDashboard(),
      ]);

      if (!context.mounted) {
        return;
      }

      final isPickup = booking.pickupRequested == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPickup
                ? 'Booking pickup berhasil dikonfirmasi. Tugas penjemputan diserahkan ke Kurir (penugasan mekanik ditunda hingga motor tiba di bengkel).'
                : 'Booking berhasil dikonfirmasi dan mekanik ditugaskan otomatis.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal mengkonfirmasi booking.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          actionsOverflowButtonSpacing: 8,
          title: const Text(
            'Logout',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun Admin?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<AuthProvider>().logout();

    if (!context.mounted) {
      return;
    }

    context.go('/login');
  }

  Future<void> _refreshSingleBooking(Booking booking) async {
    setState(() {
      _refreshingBookingId = booking.id;
    });

    try {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      await _refreshAll();
      if (!mounted) return;

      final bookingProvider = context.read<BookingProvider>();
      if (bookingProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memeriksa pembaruan status: ${bookingProvider.errorMessage}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final updated = bookingProvider.bookings.firstWhere(
        (b) => b.id == booking.id,
        orElse: () => booking,
      );
      final orders = context.read<ServiceOrderProvider>().serviceOrders;
      final relatedOrder = orders.where((o) => o.bookingId == booking.id).firstOrNull;

      if (updated.status == 'assigned') {
        final mechanicText = relatedOrder?.mechanicId != null
            ? 'Mekanik #${relatedOrder!.mechanicId} telah ditugaskan.'
            : 'Service order telah dibuat.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status booking #${booking.id} berhasil diperbarui: "assigned" (Tiba di bengkel). $mechanicText',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (updated.status == 'waiting_service') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status booking #${booking.id} berhasil diperbarui: "waiting_service" (Tiba di bengkel, antrean servis).',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status booking #${booking.id} dari server masih "${updated.status}". Menunggu pembaruan penugasan mekanik dari sistem backend.',
            ),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memeriksa pembaruan status: $e',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshingBookingId = null;
        });
      }
    }
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    this.relatedOrder,
    required this.isLoading,
    this.isRefreshing = false,
    required this.onConfirm,
    this.onRefreshStatus,
  });

  final Booking booking;
  final ServiceOrder? relatedOrder;
  final bool isLoading;
  final bool isRefreshing;
  final VoidCallback onConfirm;
  final VoidCallback? onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final status = booking.status ?? '-';
    final vehicleDesc = booking.vehicle != null
        ? '${booking.vehicle!.nomorPolisi} (${booking.vehicle!.merk} ${booking.vehicle!.model})'
        : 'Kendaraan #${booking.vehicleId}';

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Booking #${booking.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _InfoRow(label: 'Nomor', value: booking.nomorBooking ?? '-'),
          _InfoRow(label: 'Tanggal', value: booking.tanggal ?? '-'),
          _InfoRow(label: 'Waktu', value: booking.waktu ?? '-'),
          _InfoRow(label: 'Kendaraan', value: vehicleDesc),
          _InfoRow(label: 'Layanan', value: booking.jenisLayanan ?? '-'),
          _InfoRow(label: 'Keluhan', value: booking.keluhan ?? '-'),
          if (relatedOrder?.mechanicId != null)
            _InfoRow(
              label: 'Mekanik',
              value: 'Mekanik #${relatedOrder!.mechanicId}',
            ),
          _InfoRow(
            label: 'Pickup',
            value: booking.pickupRequested == true ? 'Ya' : 'Tidak',
          ),
          if (booking.alamatPickup != null &&
              booking.alamatPickup!.trim().isNotEmpty)
            _InfoRow(label: 'Alamat', value: booking.alamatPickup!),
          if (status == 'waiting_pickup') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time_outlined, color: AppColors.warning, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Menunggu Kurir memulai penjemputan unit. Penugasan mekanik akan ditunda hingga motor tiba di bengkel.',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => context.go('/admin/delivery'),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Penugasan di Delivery Tasks',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status == 'vehicle_picked_up') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.two_wheeler_outlined, color: AppColors.secondary, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Motor Sudah Dijemput Kurir',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Unit kendaraan telah selesai dijemput oleh Kurir dan diserahterimakan ke bengkel.\n'
                    'Menunggu sistem backend memproses penugasan mekanik dan membuat order servis.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: isRefreshing ? null : onRefreshStatus,
                      icon: isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(
                        isRefreshing ? 'Memeriksa Status...' : 'Periksa Pembaruan Status',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status == 'waiting_service') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.garage_outlined, color: AppColors.info, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kendaraan Tiba di Bengkel (Antrean Servis)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kendaraan telah tiba di bengkel dan sedang menunggu alokasi mekanik yang tersedia.\n'
                    'Sistem backend akan otomatis menetapkan mekanik begitu mekanik aktif siap.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: isRefreshing ? null : onRefreshStatus,
                      icon: isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(
                        isRefreshing ? 'Memeriksa Status...' : 'Periksa Pembaruan Status',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: isLoading ? null : onConfirm,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text(
                  'Konfirmasi Booking',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
