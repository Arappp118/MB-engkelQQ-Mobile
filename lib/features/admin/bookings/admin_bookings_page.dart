import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/booking.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';

class AdminBookingsPage extends StatefulWidget {
  const AdminBookingsPage({super.key});

  @override
  State<AdminBookingsPage> createState() => _AdminBookingsPageState();
}

class _AdminBookingsPageState extends State<AdminBookingsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Masuk'),
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              context.push('/notifications');
            },
          ),
          IconButton(
            tooltip: 'Pembayaran',
            icon: const Icon(Icons.payment_outlined),
            onPressed: () {
              context.push('/admin/payments');
            },
          ),
          IconButton(
            tooltip: 'Delivery Tasks',
            icon: const Icon(Icons.local_shipping_outlined),
            onPressed: () {
              context.push('/admin/delivery');
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: provider.loadBookings,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.bookings.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.loadBookings,
              child: ListView(
                children: const [
                  SizedBox(height: 180),
                  Center(child: Text('Belum ada booking masuk.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: provider.loadBookings,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.bookings.length,
              separatorBuilder: (_, _) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final booking = provider.bookings[index];

                return _BookingCard(
                  booking: booking,
                  isLoading: provider.isLoading,
                  onConfirm: () {
                    _confirmBooking(context, booking);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmBooking(BuildContext context, Booking booking) async {
    final provider = context.read<BookingProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Booking'),
          content: Text(
            'Apakah booking #${booking.id} '
            'ingin dikonfirmasi?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking berhasil dikonfirmasi.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal mengkonfirmasi booking.',
          ),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari akun Admin?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
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
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.isLoading,
    required this.onConfirm,
  });

  final Booking booking;
  final bool isLoading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final status = booking.status ?? '-';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Booking #${booking.id}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),

            const SizedBox(height: 16),

            _InfoRow(label: 'Nomor', value: booking.nomorBooking ?? '-'),

            _InfoRow(label: 'Tanggal', value: booking.tanggal ?? '-'),

            _InfoRow(label: 'Waktu', value: booking.waktu ?? '-'),

            _InfoRow(label: 'Kendaraan', value: booking.vehicleId.toString()),

            _InfoRow(label: 'Layanan', value: booking.jenisLayanan ?? '-'),

            _InfoRow(label: 'Keluhan', value: booking.keluhan ?? '-'),

            _InfoRow(
              label: 'Pickup',
              value: booking.pickupRequested == true ? 'Ya' : 'Tidak',
            ),

            if (booking.alamatPickup != null &&
                booking.alamatPickup!.trim().isNotEmpty)
              _InfoRow(label: 'Alamat', value: booking.alamatPickup!),

            const SizedBox(height: 16),

            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isLoading ? null : onConfirm,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Konfirmasi Booking'),
                ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Text(status, style: const TextStyle(fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
