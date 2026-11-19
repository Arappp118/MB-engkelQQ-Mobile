import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/service_status_timeline.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/booking.dart';
import '../../../models/service_order.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/service_order_provider.dart';
import '../payments/customer_payment_page.dart';
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

  Future<void> _cancelBooking(Booking booking) async {
    final reasonController = TextEditingController();

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          actionsOverflowButtonSpacing: 8,
          title: const Text(
            'Batalkan Booking',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Apakah Anda yakin ingin membatalkan booking #${booking.nomorBooking ?? booking.id}?',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Alasan Pembatalan (Opsional):',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan jika ada...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text(
                'Kembali',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
              child: const Text('Batalkan Booking'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) {
      reasonController.dispose();
      return;
    }

    final reason = reasonController.text.trim();
    reasonController.dispose();

    final provider = context.read<BookingProvider>();
    final success = await provider.cancelBooking(
      booking.id,
      reason: reason.isNotEmpty ? reason : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil dibatalkan.'),
          backgroundColor: AppColors.success,
        ),
      );
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal membatalkan booking.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildPickupLifecycleBanner(String status) {
    if (status == 'waiting_pickup') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.5),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.access_time_outlined,
              color: AppColors.warning,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menunggu Penjemputan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kurir bengkel akan segera mengambil motor di lokasi penjemputan Anda.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'vehicle_picked_up') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.5),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.two_wheeler_outlined,
              color: AppColors.secondary,
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motor Dalam Perjalanan ke Bengkel',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kendaraan telah dijemput Kurir dan diserahterimakan ke bengkel MB-engkelQQ. '
                    'Pengerjaan servis belum dimulai. Menunggu sistem bengkel menugaskan mekanik dan membuat order servis.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (status == 'waiting_service') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.infoContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.info.withValues(alpha: 0.5),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.garage_outlined, color: AppColors.info, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motor Telah Tiba di Bengkel',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kendaraan telah sampai di bengkel dan masuk antrean servis mekanik.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Booking'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer2<BookingProvider, ServiceOrderProvider>(
        builder: (context, bookingProvider, serviceOrderProvider, child) {
          if (bookingProvider.isLoading &&
              bookingProvider.selectedBooking == null) {
            return const LoadingState(
              height: 350,
              message: 'Memuat detail booking...',
            );
          }

          if (bookingProvider.errorMessage != null &&
              bookingProvider.selectedBooking == null) {
            return ErrorState(
              title: 'Booking Tidak Ditemukan',
              message: bookingProvider.errorMessage!,
              onRetry: _reload,
            );
          }

          final booking = bookingProvider.selectedBooking;

          if (booking == null) {
            return ErrorState(
              title: 'Data Tidak Ditemukan',
              message: 'Data booking dengan ID #${widget.bookingId} tidak ada.',
              onRetry: _reload,
            );
          }

          final serviceOrder = _findServiceOrder(
            serviceOrderProvider.serviceOrders,
            booking.id,
          );

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceCard,
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(booking),
                const SizedBox(height: 16),
                ServiceStatusTimeline(
                  currentStatus: booking.status ?? 'pending',
                ),
                if (booking.pickupRequested == true) ...[
                  const SizedBox(height: 16),
                  _buildPickupLifecycleBanner(booking.status ?? ''),
                ],
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Informasi Jadwal',
                  subtitle: 'Waktu dan rincian layanan yang dipilih',
                ),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Nomor Booking',
                        value: booking.nomorBooking ?? 'Booking #${booking.id}',
                        icon: Icons.confirmation_number_outlined,
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 16),
                      _InfoRow(
                        label: 'Tanggal Servis',
                        value: booking.tanggal ?? '-',
                        icon: Icons.calendar_today_outlined,
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 16),
                      _InfoRow(
                        label: 'Waktu Kedatangan',
                        value: booking.waktu ?? '-',
                        icon: Icons.access_time_outlined,
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 16),
                      _InfoRow(
                        label: 'Jenis Layanan',
                        value: _formatServiceType(booking.jenisLayanan),
                        icon: Icons.build_outlined,
                      ),
                      const Divider(color: AppColors.borderSubtle, height: 16),
                      _InfoRow(
                        label: 'Status Pengerjaan',
                        value: _formatStatus(booking.status),
                        icon: Icons.flag_outlined,
                        customBadge: StatusBadge(
                          status: booking.status ?? 'unknown',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Layanan Pickup & Lokasi',
                  subtitle: 'Informasi penjemputan motor',
                ),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Metode Pengantaran',
                        value: booking.pickupRequested == true
                            ? 'Pickup Kendaraan oleh Kurir'
                            : 'Datang Sendiri ke Bengkel',
                        icon: booking.pickupRequested == true
                            ? Icons.local_shipping_outlined
                            : Icons.storefront_outlined,
                      ),
                      if (booking.alamatPickup != null &&
                          booking.alamatPickup!.isNotEmpty) ...[
                        const Divider(
                          color: AppColors.borderSubtle,
                          height: 16,
                        ),
                        _InfoRow(
                          label: 'Alamat Pickup',
                          value: booking.alamatPickup!,
                          icon: Icons.location_on_outlined,
                        ),
                      ],
                      if (booking.estimatedDistanceKm != null) ...[
                        const Divider(
                          color: AppColors.borderSubtle,
                          height: 16,
                        ),
                        _InfoRow(
                          label: 'Jarak ke Bengkel',
                          value:
                              '${booking.estimatedDistanceKm!.toStringAsFixed(1)} km',
                          icon: Icons.straighten_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
                if ((booking.keluhan != null && booking.keluhan!.isNotEmpty) ||
                    (booking.diagnosisCustomer != null &&
                        booking.diagnosisCustomer!.isNotEmpty)) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Keluhan & Diagnosis',
                    subtitle: 'Keluhan awal yang disampaikan',
                  ),
                  PremiumCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (booking.keluhan != null &&
                            booking.keluhan!.isNotEmpty) ...[
                          const Text(
                            'Keluhan Motor',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.keluhan!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (booking.diagnosisCustomer != null &&
                            booking.diagnosisCustomer!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(
                            color: AppColors.borderSubtle,
                            height: 16,
                          ),
                          const Text(
                            'Diagnosis Awal Customer',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking.diagnosisCustomer!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (booking.catatan != null && booking.catatan!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Catatan Tambahan',
                    subtitle: 'Instruksi khusus untuk mekanik',
                  ),
                  PremiumCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      booking.catatan!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
                if (booking.cancellationReason != null &&
                    booking.cancellationReason!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const SectionHeader(
                    title: 'Alasan Pembatalan',
                    subtitle: 'Status pembatalan dari bengkel',
                  ),
                  PremiumCard(
                    borderColor: AppColors.error.withValues(alpha: 0.5),
                    backgroundColor: AppColors.errorContainer,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.cancel_outlined,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            booking.cancellationReason!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (serviceOrder != null) ...[
                  const SizedBox(height: 20),
                  _buildServiceOrderCard(booking, serviceOrder),
                ],
                if (booking.status == 'pending' ||
                    booking.status == 'confirmed') ...[
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: bookingProvider.isLoading
                          ? null
                          : () => _cancelBooking(booking),
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      label: const Text(
                        'Batalkan Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceOrderCard(Booking booking, ServiceOrder serviceOrder) {
    final isServiceCompleted = booking.status == 'service_completed';
    final isWaitingPayment = booking.status == 'waiting_payment';

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.secondary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.build_circle_rounded,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Work Order Terkait',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Order #${serviceOrder.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: serviceOrder.status ?? 'unknown'),
            ],
          ),
          if (serviceOrder.mechanicId != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.engineering_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mekanik Ditugaskan: Mekanik #${serviceOrder.mechanicId}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (serviceOrder.grandTotal != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.borderSubtle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isServiceCompleted ? 'Total Tagihan Resmi:' : 'Estimasi Biaya:',
                    style: TextStyle(
                      fontSize: 13,
                      color: isServiceCompleted ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: isServiceCompleted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatCurrency(serviceOrder.grandTotal!),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isServiceCompleted) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tagihan Siap Dibayar',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Servis telah selesai dikerjakan mekanik. Silakan selesaikan pembayaran.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    text: serviceOrder.grandTotal != null
                        ? 'Bayar Tagihan (${_formatCurrency(serviceOrder.grandTotal!)})'
                        : 'Bayar Tagihan Sekarang',
                    icon: Icons.payment_rounded,
                    height: 42,
                    onPressed: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CustomerPaymentPage(
                            serviceOrder: serviceOrder,
                          ),
                        ),
                      );
                      if (result == true && mounted) {
                        _reload();
                      }
                    },
                  ),
                ],
              ),
            ),
          ] else if (isWaitingPayment) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time_rounded, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pembayaran Menunggu Verifikasi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bukti pembayaran telah dikirim dan menunggu verifikasi admin. Pengajuan pembayaran baru dikunci untuk mencegah duplikasi.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SecondaryButton(
            text: 'Lihat Detail Servis & Part',
            icon: Icons.arrow_forward_rounded,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CustomerServiceOrderDetailPage(
                    serviceOrderId: serviceOrder.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match.group(1)}.')}';
  }

  Widget _buildHeader(Booking booking) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            booking.nomorBooking ?? 'Booking #${booking.id}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          StatusBadge(status: booking.status ?? 'unknown'),
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
        return value?.replaceAll('_', ' ').toUpperCase() ?? '-';
    }
  }

  String _formatStatus(String? value) {
    if (value == null) return '-';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon,
    this.customBadge,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? customBadge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const Spacer(),
        if (customBadge != null)
          customBadge!
        else
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
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
