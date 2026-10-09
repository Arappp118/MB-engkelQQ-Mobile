import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/booking.dart';
import '../../../providers/booking_provider.dart';
import 'customer_booking_detail_page.dart';
import 'customer_create_booking_page.dart';

class CustomerBookingsPage extends StatefulWidget {
  const CustomerBookingsPage({super.key});

  @override
  State<CustomerBookingsPage> createState() => _CustomerBookingsPageState();
}

class _CustomerBookingsPageState extends State<CustomerBookingsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadBookings();
    });
  }

  Future<void> _refreshBookings() async {
    await context.read<BookingProvider>().loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Saya'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
        actions: [
          IconButton(
            tooltip: 'Buat Booking',
            icon: const Icon(Icons.add, color: AppColors.primary),
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
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.bookings.isEmpty) {
            return const LoadingState(
              height: 350,
              message: 'Memuat riwayat booking...',
            );
          }

          if (provider.errorMessage != null && provider.bookings.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshBookings,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  ErrorState(
                    title: 'Gagal Memuat Booking',
                    message: provider.errorMessage!,
                    onRetry: _refreshBookings,
                  ),
                ],
              ),
            );
          }

          if (provider.bookings.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshBookings,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 60),
                  EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'Belum Ada Booking',
                    message: 'Booking service kamu akan muncul di halaman ini.',
                    actionLabel: 'Buat Booking Sekarang',
                    onAction: () {
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

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceCard,
            onRefresh: _refreshBookings,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: provider.bookings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = provider.bookings[index];

                return _BookingCard(
                  booking: booking,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerBookingDetailPage(bookingId: booking.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.nomorBooking ?? 'Booking #${booking.id}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatServiceType(booking.jenisLayanan),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: booking.status ?? 'unknown'),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Jadwal Servis',
            value: '${booking.tanggal ?? '-'} • ${booking.waktu ?? '-'}',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: booking.pickupRequested == true
                ? Icons.local_shipping_outlined
                : Icons.directions_car_outlined,
            label: 'Metode Kunjungan',
            value: booking.pickupRequested == true
                ? 'Pickup Kendaraan'
                : 'Datang Sendiri',
          ),
          if (booking.alamatPickup != null &&
              booking.alamatPickup!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Alamat Pickup',
              value: booking.alamatPickup!,
            ),
          ],
          if (booking.keluhan != null && booking.keluhan!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundDarker,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.report_problem_outlined,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.keluhan!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatServiceType(String? value) {
    switch (value) {
      case 'medical_checkup':
        return 'Medical Checkup';
      case 'service_rutin':
      case 'servis_rutin':
        return 'Service Rutin';
      case 'tune_up':
        return 'Tune Up';
      case 'ganti_oli':
        return 'Ganti Oli';
      case 'overhaul':
        return 'Overhaul';
      case 'kelistrikan':
        return 'Kelistrikan';
      case 'perbaikan':
        return 'Perbaikan';
      default:
        return value?.replaceAll('_', ' ').toUpperCase() ?? 'Layanan Servis';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
