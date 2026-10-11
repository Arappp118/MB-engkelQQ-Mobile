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
import '../../../models/invoice.dart';
import '../../../models/service_order.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/service_order_provider.dart';
import '../invoices/customer_invoice_detail_page.dart';
import '../payments/customer_payment_page.dart';

class CustomerServiceOrderDetailPage extends StatefulWidget {
  const CustomerServiceOrderDetailPage({
    super.key,
    required this.serviceOrderId,
  });

  final int serviceOrderId;

  @override
  State<CustomerServiceOrderDetailPage> createState() =>
      _CustomerServiceOrderDetailPageState();
}

class _CustomerServiceOrderDetailPageState
    extends State<CustomerServiceOrderDetailPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final serviceOrderProvider = context.read<ServiceOrderProvider>();
    final invoiceProvider = context.read<InvoiceProvider>();
    final bookingProvider = context.read<BookingProvider>();

    await Future.wait([
      serviceOrderProvider.loadServiceOrder(
        widget.serviceOrderId,
      ),
      invoiceProvider.loadInvoice(
        widget.serviceOrderId,
      ),
    ]);

    if (!mounted) return;

    final order = serviceOrderProvider.selectedServiceOrder;
    if (order?.bookingId != null) {
      await bookingProvider.loadBooking(order!.bookingId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Servis'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat Ulang',
            onPressed: _refresh,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer3<ServiceOrderProvider, InvoiceProvider, BookingProvider>(
        builder: (context, serviceProvider, invoiceProvider, bookingProvider, _) {
          final order = serviceProvider.selectedServiceOrder;
          final invoice = invoiceProvider.selectedInvoice?.serviceOrderId == widget.serviceOrderId
              ? invoiceProvider.selectedInvoice
              : null;
          final booking = bookingProvider.selectedBooking?.id == order?.bookingId
              ? bookingProvider.selectedBooking
              : (bookingProvider.bookings.where((b) => b.id == order?.bookingId).firstOrNull);

          if (serviceProvider.isLoading && order == null) {
            return const LoadingState(
              height: 350,
              message: 'Memuat data order servis...',
            );
          }

          if (serviceProvider.errorMessage != null && order == null) {
            return ErrorState(
              title: 'Gagal Memuat Servis',
              message: serviceProvider.errorMessage!,
              onRetry: _refresh,
            );
          }

          if (order == null) {
            return const Center(
              child: EmptyState(
                title: 'Data Tidak Ditemukan',
                message: 'Data service order tidak tersedia.',
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceCard,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _ServiceHeader(order: order),
                const SizedBox(height: 16),
                ServiceStatusTimeline(currentStatus: order.status ?? 'pending'),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Hasil Diagnosis',
                  subtitle: 'Catatan teknis dari mekanik MB-engkelQQ',
                ),
                _DiagnosisCard(order: order),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Tindakan & Sparepart',
                  subtitle: 'Daftar suku cadang dan jasa servis',
                ),
                _ItemsCard(order: order),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Rincian Biaya',
                  subtitle: 'Total estimasi biaya pengerjaan',
                ),
                _SummaryCard(order: order),
                const SizedBox(height: 20),
                _PaymentSection(
                  order: order,
                  invoice: invoice,
                  booking: booking,
                  onPaymentCompleted: _refresh,
                ),
                if (order.status?.toLowerCase() == 'completed' ||
                    order.status?.toLowerCase() == 'paid') ...[
                  const SizedBox(height: 16),
                  _InvoiceSection(order: order),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.secondary, AppColors.secondaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.build_circle_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Order',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '#${order.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (order.mechanicId != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Mekanik Ditugaskan: #${order.mechanicId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          StatusBadge(status: order.status ?? 'unknown'),
        ],
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    final diagnosis = order.diagnosis?.trim();

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Diagnosis Mekanik',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            diagnosis == null || diagnosis.isEmpty
                ? 'Diagnosis belum dicatat oleh mekanik.'
                : diagnosis,
            style: TextStyle(
              fontSize: 13,
              color: diagnosis == null || diagnosis.isEmpty
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada tindakan atau suku cadang yang dimasukkan.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else
            ...order.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == order.items.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCardElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.handyman_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${item.quantity} × ${_formatCurrency(item.price)}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatCurrency(item.subtotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(color: AppColors.borderSubtle, height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Subtotal Servis & Part',
            value: _formatCurrency(order.subtotal),
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Biaya Layanan Pickup',
            value: _formatCurrency(order.deliveryFee),
          ),
          const Divider(color: AppColors.borderSubtle, height: 24),
          _SummaryRow(
            label: 'Grand Total',
            value: _formatCurrency(order.grandTotal),
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.order,
    this.invoice,
    this.booking,
    this.onPaymentCompleted,
  });

  final ServiceOrder order;
  final Invoice? invoice;
  final Booking? booking;
  final VoidCallback? onPaymentCompleted;

  static String _formatPaymentMethod(String method) {
    switch (method.toLowerCase().trim()) {
      case 'cash':
        return 'Tunai (Cash)';
      case 'transfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderStatus = order.status?.toLowerCase().trim();
    final invoicePaymentStatus = invoice?.paymentStatus?.toLowerCase().trim();
    final bookingStatus = booking?.status?.toLowerCase().trim();

    // Sesuai audit kontrak Laravel (PaymentService::verify & InvoiceResource):
    // 1. payment.status bernilai 'verified' dan diteruskan oleh InvoiceResource sebagai payment_status.
    // 2. booking.status diperbarui menjadi 'paid' lalu 'completed' oleh backend Laravel.
    // 3. service_order.status TETAP 'completed' (enum DB Laravel: pending, in_progress, completed, cancelled).
    final isVerified = invoicePaymentStatus == 'verified' ||
        invoicePaymentStatus == 'paid' ||
        bookingStatus == 'paid' ||
        (bookingStatus == 'completed' &&
            invoicePaymentStatus != 'waiting_verification' &&
            invoicePaymentStatus != 'rejected' &&
            invoicePaymentStatus != null);

    // Saat Customer mengajukan pembayaran (PaymentService::create):
    // - payment.status menjadi 'waiting_verification'
    // - booking.status menjadi 'waiting_payment'
    final isWaitingVerification = !isVerified &&
        (invoicePaymentStatus == 'waiting_verification' ||
            (bookingStatus == 'waiting_payment' &&
                invoicePaymentStatus != 'rejected' &&
                invoicePaymentStatus != null));

    final isRejected = !isVerified &&
        !isWaitingVerification &&
        (invoicePaymentStatus == 'rejected');

    // Jika pekerjaan belum selesai dikerjakan mekanik
    if (orderStatus != 'completed' &&
        orderStatus != 'waiting_payment' &&
        !isVerified &&
        !isWaitingVerification) {
      return PremiumCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceCardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tahap Pengerjaan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Menu pembayaran akan aktif setelah seluruh servis selesai dikerjakan.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // KONDISI 1: Pembayaran sudah diverifikasi Admin
    if (isVerified) {
      final method = invoice?.paymentMethod != null
          ? _formatPaymentMethod(invoice!.paymentMethod!)
          : null;
      final total = order.grandTotal ?? invoice?.grandTotal;

      return PremiumCard(
        padding: const EdgeInsets.all(18),
        borderColor: AppColors.success.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembayaran Telah Lunas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Transaksi telah diverifikasi oleh Admin MB-engkelQQ dan faktur resmi telah diterbitkan.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: invoicePaymentStatus ?? 'verified'),
              ],
            ),
            const Divider(color: AppColors.borderSubtle, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status Pembayaran:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  invoicePaymentStatus == 'paid' ? 'Dibayar' : 'Terverifikasi',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            if (method != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Metode Pembayaran:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    method,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            if (total != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    _formatCurrency(total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SecondaryButton(
              text: 'Buka Invoice Resmi',
              icon: Icons.receipt_long,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomerInvoiceDetailPage(serviceOrderId: order.id),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // KONDISI 2: Menunggu verifikasi Admin
    if (isWaitingVerification) {
      final method = invoice?.paymentMethod != null
          ? _formatPaymentMethod(invoice!.paymentMethod!)
          : null;
      final total = order.grandTotal ?? invoice?.grandTotal;

      return PremiumCard(
        padding: const EdgeInsets.all(18),
        borderColor: AppColors.warning.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menunggu Verifikasi Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bukti pembayaran telah berhasil dikirim. Admin MB-engkelQQ sedang memverifikasi transaksi Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const StatusBadge(status: 'waiting_verification'),
              ],
            ),
            const Divider(color: AppColors.borderSubtle, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status Pembayaran:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const Text(
                  'Menunggu Verifikasi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            if (method != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Metode Pembayaran:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    method,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            if (total != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Tagihan:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    _formatCurrency(total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin akan meninjau pembayaran Anda segera. Anda tidak perlu mengirim pembayaran ulang.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SecondaryButton(
              text: 'Buka Rincian Invoice',
              icon: Icons.receipt_long_outlined,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CustomerInvoiceDetailPage(serviceOrderId: order.id),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // KONDISI 3: Pembayaran ditolak oleh Admin
    if (isRejected) {
      final total = order.grandTotal ?? invoice?.grandTotal;

      return PremiumCard(
        padding: const EdgeInsets.all(18),
        borderColor: AppColors.error.withValues(alpha: 0.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembayaran Ditolak',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Bukti pembayaran sebelumnya ditolak oleh admin. Silakan periksa kembali dan ajukan pembayaran ulang.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const StatusBadge(status: 'rejected'),
              ],
            ),
            const Divider(color: AppColors.borderSubtle, height: 24),
            if (total != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Tagihan:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  Text(
                    _formatCurrency(total),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            PrimaryButton(
              text: 'Bayar Ulang / Kirim Bukti Baru',
              icon: Icons.payment_rounded,
              height: 48,
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CustomerPaymentPage(serviceOrder: order),
                  ),
                );

                if (result == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Pembayaran berhasil dikirim untuk verifikasi admin.',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  onPaymentCompleted?.call();
                }
              },
            ),
          ],
        ),
      );
    }

    // KONDISI 4: Menunggu Pembayaran (Servis selesai, belum ada pembayaran dikirim)
    final total = order.grandTotal ?? invoice?.grandTotal;

    return PremiumCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.primary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Pembayaran Siap Dilakukan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const StatusBadge(status: 'waiting_payment'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Tagihan:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                _formatCurrency(total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Bayar Sekarang',
            icon: Icons.payment_rounded,
            height: 48,
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CustomerPaymentPage(serviceOrder: order),
                ),
              );

              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Pembayaran berhasil dikirim untuk verifikasi admin.',
                    ),
                    backgroundColor: AppColors.success,
                  ),
                );
                onPaymentCompleted?.call();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.secondary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.receipt_long, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Invoice Resmi MB-engkelQQ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Servis telah selesai. Anda dapat mengunduh atau meninjau rincian faktur resmi.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            text: 'Buka Invoice',
            icon: Icons.receipt_long_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CustomerInvoiceDetailPage(serviceOrderId: order.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: bold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: bold ? 17 : 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatCurrency(double? value) {
  if (value == null) {
    return 'Rp 0';
  }

  final rounded = value.round().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < rounded.length; i++) {
    if (i > 0 && (rounded.length - i) % 3 == 0) {
      buffer.write('.');
    }

    buffer.write(rounded[i]);
  }

  return 'Rp ${buffer.toString()}';
}
