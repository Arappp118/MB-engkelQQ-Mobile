import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'customer_create_booking_page.dart';

import '../../../models/booking.dart';
import '../../../providers/booking_provider.dart';
import 'customer_booking_detail_page.dart';

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
      appBar: AppBar(
        title: const Text('Booking Saya'),
        actions: [
          IconButton(
            tooltip: 'Buat Booking',
            icon: const Icon(Icons.add),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.bookings.isEmpty) {
            return _buildErrorState(provider.errorMessage!);
          }

          if (provider.bookings.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
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

  Widget _buildErrorState(String message) {
    return RefreshIndicator(
      onRefresh: _refreshBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Gagal Memuat Booking',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _refreshBookings,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _refreshBookings,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 100),
          Icon(Icons.calendar_month_outlined, size: 72),
          SizedBox(height: 20),
          Text(
            'Belum Ada Booking',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Booking service kamu akan muncul '
            'di halaman ini.',
            textAlign: TextAlign.center,
          ),
        ],
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      booking.nomorBooking ?? 'Booking #${booking.id}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: booking.status ?? 'unknown'),
                ],
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Tanggal',
                value: booking.tanggal ?? '-',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.access_time_outlined,
                label: 'Waktu',
                value: booking.waktu ?? '-',
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.build_outlined,
                label: 'Layanan',
                value: _formatServiceType(booking.jenisLayanan),
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: booking.pickupRequested == true
                    ? Icons.local_shipping_outlined
                    : Icons.directions_car_outlined,
                label: 'Layanan Pickup',
                value: booking.pickupRequested == true
                    ? 'Pickup Kendaraan'
                    : 'Datang Sendiri',
              ),
              if (booking.alamatPickup != null &&
                  booking.alamatPickup!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat',
                  value: booking.alamatPickup!,
                ),
              ],
              if (booking.keluhan != null && booking.keluhan!.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Keluhan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text(
                  booking.keluhan!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatServiceType(String? value) {
    switch (value) {
      case 'medical_checkup':
        return 'Medical Checkup';
      case 'service_rutin':
        return 'Service Rutin';
      case 'perbaikan':
        return 'Perbaikan';
      default:
        return value ?? '-';
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatStatus(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
