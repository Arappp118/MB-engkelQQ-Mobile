import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/booking.dart';
import '../../../models/service_order.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/service_order_provider.dart';
import '../service_orders/customer_service_order_detail_page.dart';

class CustomerBookingDetailPage extends StatefulWidget {
  const CustomerBookingDetailPage({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<CustomerBookingDetailPage> createState() =>
      _CustomerBookingDetailPageState();
}

class _CustomerBookingDetailPageState extends State<CustomerBookingDetailPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadBooking(widget.bookingId);
      context.read<ServiceOrderProvider>().loadServiceOrders();
    });
  }

  Future<void> _reload() async {
    await Future.wait([
      context.read<BookingProvider>().loadBooking(widget.bookingId),
      context.read<ServiceOrderProvider>().loadServiceOrders(),
    ]);
  }

  ServiceOrder? _findServiceOrder(
    List<ServiceOrder> serviceOrders,
    int bookingId,
  ) {
    for (final order in serviceOrders) {
      if (order.bookingId == bookingId) {
        return order;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Booking')),
      body: Consumer2<BookingProvider, ServiceOrderProvider>(
        builder: (context, bookingProvider, serviceOrderProvider, child) {
          if (bookingProvider.isLoading &&
              bookingProvider.selectedBooking == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (bookingProvider.errorMessage != null &&
              bookingProvider.selectedBooking == null) {
            return _buildError(bookingProvider.errorMessage!);
          }

          final booking = bookingProvider.selectedBooking;

          if (booking == null) {
            return _buildError('Data booking tidak ditemukan.');
          }

          final serviceOrder = _findServiceOrder(
            serviceOrderProvider.serviceOrders,
            booking.id,
          );

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(booking),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Informasi Booking',
                  children: [
                    _InfoRow(
                      label: 'Nomor Booking',
                      value: booking.nomorBooking ?? 'Booking #${booking.id}',
                    ),
                    _InfoRow(label: 'Tanggal', value: booking.tanggal ?? '-'),
                    _InfoRow(label: 'Waktu', value: booking.waktu ?? '-'),
                    _InfoRow(
                      label: 'Layanan',
                      value: _formatServiceType(booking.jenisLayanan),
                    ),
                    _InfoRow(
                      label: 'Status',
                      value: _formatStatus(booking.status),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Kendaraan',
                  children: [
                    _InfoRow(
                      label: 'Vehicle ID',
                      value: booking.vehicleId.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Keluhan',
                  children: [
                    Text(
                      booking.keluhan?.isNotEmpty == true
                          ? booking.keluhan!
                          : '-',
                    ),
                  ],
                ),
                if (booking.diagnosisCustomer != null &&
                    booking.diagnosisCustomer!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Diagnosis Awal',
                    children: [Text(booking.diagnosisCustomer!)],
                  ),
                ],
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Pickup',
                  children: [
                    _InfoRow(
                      label: 'Metode',
                      value: booking.pickupRequested == true
                          ? 'Pickup Kendaraan'
                          : 'Datang Sendiri',
                    ),
                    if (booking.alamatPickup != null &&
                        booking.alamatPickup!.isNotEmpty)
                      _InfoRow(label: 'Alamat', value: booking.alamatPickup!),
                    if (booking.estimatedDistanceKm != null)
                      _InfoRow(
                        label: 'Jarak',
                        value:
                            '${booking.estimatedDistanceKm!.toStringAsFixed(1)} km',
                      ),
                  ],
                ),
                if (booking.catatan != null && booking.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Catatan',
                    children: [Text(booking.catatan!)],
                  ),
                ],
                if (booking.cancellationReason != null &&
                    booking.cancellationReason!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Alasan Pembatalan',
                    children: [Text(booking.cancellationReason!)],
                  ),
                ],
                if (serviceOrder != null) ...[
                  const SizedBox(height: 16),
                  _buildServiceOrderCard(serviceOrder),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceOrderCard(ServiceOrder serviceOrder) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build_circle_outlined),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Service Order',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusBadge(status: serviceOrder.status ?? 'unknown'),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(label: 'Service Order', value: '#${serviceOrder.id}'),
            if (serviceOrder.grandTotal != null)
              _InfoRow(
                label: 'Total',
                value: _formatCurrency(serviceOrder.grandTotal!),
              ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CustomerServiceOrderDetailPage(
                        serviceOrderId: serviceOrder.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Lihat Detail Servis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}';
  }

  Widget _buildHeader(Booking booking) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.calendar_month, size: 48),
            const SizedBox(height: 12),
            Text(
              booking.nomorBooking ?? 'Booking #${booking.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _StatusBadge(status: booking.status ?? 'unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildError(String message) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 20),
          const Text(
            'Gagal Memuat Detail',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ),
        ],
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

  String _formatStatus(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(fontWeight: FontWeight.w600),
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
