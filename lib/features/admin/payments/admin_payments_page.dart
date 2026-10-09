import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/booking.dart';
import '../../../models/payment.dart';
import '../../../models/service_order.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../providers/service_order_provider.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  String _selectedFilter =
      'waiting_verification'; // waiting_verification, verified, rejected, all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<BookingProvider>().loadBookings(),
      context.read<ServiceOrderProvider>().loadServiceOrders(),
    ]);
  }

  Future<void> _showVerifyPaymentDialog(
    Booking booking,
    ServiceOrder? order,
  ) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _PaymentVerifyOrRejectDialog(booking: booking, order: order),
    );

    if (action == null || !mounted) return;

    if (action.startsWith('verify:')) {
      final idStr = action.substring('verify:'.length);
      final paymentId = int.tryParse(idStr);
      if (paymentId == null) {
        _showErrorSnackBar('ID Pembayaran harus berupa angka yang valid.');
        return;
      }
      await _executeVerify(paymentId);
    } else if (action.startsWith('reject:')) {
      final idStr = action.substring('reject:'.length);
      final paymentId = int.tryParse(idStr);
      if (paymentId == null) {
        _showErrorSnackBar('ID Pembayaran harus berupa angka yang valid.');
        return;
      }
      await _executeRejectWithReason(paymentId);
    }
  }

  Future<void> _executeVerify(int paymentId) async {
    final provider = context.read<PaymentProvider>();
    final success = await provider.verifyPayment(paymentId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran #$paymentId berhasil diverifikasi.'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } else {
      _showErrorSnackBar(
        provider.errorMessage ?? 'Gagal memverifikasi pembayaran.',
      );
    }
  }

  Future<void> _executeRejectWithReason(int paymentId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _RejectReasonDialog(paymentId: paymentId),
    );

    if (reason == null || reason.isEmpty || !mounted) return;

    final provider = context.read<PaymentProvider>();
    final success = await provider.rejectPayment(paymentId, reason: reason);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pembayaran #$paymentId berhasil ditolak.'),
          backgroundColor: AppColors.warning,
        ),
      );
      _loadData();
    } else {
      _showErrorSnackBar(provider.errorMessage ?? 'Gagal menolak pembayaran.');
    }
  }

  Future<void> _showLookupDialog() async {
    final lookupId = await showDialog<int>(
      context: context,
      builder: (dialogContext) => const _PaymentLookupDialog(),
    );

    if (lookupId == null || !mounted) return;

    final provider = context.read<PaymentProvider>();
    final success = await provider.loadPayment(lookupId);

    if (!mounted) return;

    if (success && provider.selectedPayment != null) {
      _showPaymentDetailsDialog(provider.selectedPayment!);
    } else {
      _showErrorSnackBar(
        provider.errorMessage ?? 'Pembayaran #$lookupId tidak ditemukan.',
      );
    }
  }

  void _showPaymentDetailsDialog(Payment payment) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Detail Pembayaran #${payment.id}',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Status', payment.statusLabel),
              _detailRow('Metode', payment.methodLabel),
              _detailRow('Nominal', _formatCurrency(payment.amount)),
              _detailRow(
                'Order ID',
                payment.serviceOrderId != null
                    ? '#${payment.serviceOrderId}'
                    : '-',
              ),
              _detailRow('Waktu Bayar', payment.paidAt ?? '-'),
              if (payment.hasProof == true) ...[
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Bukti pembayaran terlampir.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Catatan: ${payment.notes}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(color: AppColors.secondary),
              ),
            ),
            if (payment.status?.toLowerCase() == 'waiting_verification') ...[
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _executeRejectWithReason(payment.id);
                },
                child: const Text('Tolak'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _executeVerify(payment.id);
                },
                child: const Text('Verifikasi'),
              ),
            ],
          ],
        );
      },
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final orderProvider = context.watch<ServiceOrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Pembayaran'),
        actions: [
          IconButton(
            tooltip: 'Cari Payment by ID',
            icon: const Icon(Icons.search),
            onPressed: _showLookupDialog,
          ),
          IconButton(
            tooltip: 'Booking Masuk',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => context.go('/admin'),
          ),
          IconButton(
            tooltip: 'Delivery Tasks',
            icon: const Icon(Icons.local_shipping_outlined),
            onPressed: () => context.push('/admin/delivery'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/admin');
              break;
            case 1:
              break;
            case 2:
              context.push('/admin/delivery');
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
      body: Column(
        children: [
          _buildFilterTabs(),
          _buildApiLimitationNotice(),
          Expanded(
            child: _buildBody(bookingProvider, orderProvider, paymentProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildApiLimitationNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.secondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Status pembayaran merujuk pada status Booking (waiting_payment/paid). Untuk eksekusi verifikasi via API, masukkan ID Pembayaran resmi.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'waiting_verification', 'label': 'Menunggu'},
      {'key': 'verified', 'label': 'Terverifikasi'},
      {'key': 'rejected', 'label': 'Dibatalkan'},
      {'key': 'all', 'label': 'Semua'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final key = f['key']!;
            final label = f['label']!;
            final isSelected = _selectedFilter == key;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = key;
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody(
    BookingProvider bookingProvider,
    ServiceOrderProvider orderProvider,
    PaymentProvider paymentProvider,
  ) {
    final isInitialLoading =
        (bookingProvider.isLoading || orderProvider.isLoading) &&
        bookingProvider.bookings.isEmpty;

    if (isInitialLoading) {
      return const LoadingState(message: 'Memuat data pembayaran...');
    }

    if (bookingProvider.errorMessage != null &&
        bookingProvider.bookings.isEmpty) {
      return ErrorState(
        message: bookingProvider.errorMessage!,
        onRetry: _loadData,
      );
    }

    // Filter berdasarkan status resmi Booking
    final bookings = bookingProvider.bookings;
    final orders = orderProvider.serviceOrders;

    final filtered = bookings.where((b) {
      final status = b.status?.toLowerCase();
      if (_selectedFilter == 'waiting_verification') {
        return status == 'waiting_payment';
      }
      if (_selectedFilter == 'verified') {
        return status == 'paid' || status == 'completed';
      }
      if (_selectedFilter == 'rejected') {
        return status == 'cancelled';
      }
      // 'all'
      return status == 'waiting_payment' ||
          status == 'paid' ||
          status == 'completed' ||
          status == 'cancelled';
    }).toList();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Tidak Ada Data',
              message: _selectedFilter == 'waiting_verification'
                  ? 'Tidak ada booking menunggu verifikasi pembayaran.'
                  : 'Tidak ada data pembayaran dengan status ini.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = filtered[index];
          final matchedOrder = _findOrderForBooking(orders, booking.id);

          return _AdminPaymentBookingCard(
            booking: booking,
            order: matchedOrder,
            isLoading: paymentProvider.isLoading,
            onVerifyWithId: () {
              _showVerifyPaymentDialog(booking, matchedOrder);
            },
          );
        },
      ),
    );
  }

  ServiceOrder? _findOrderForBooking(List<ServiceOrder> orders, int bookingId) {
    for (final order in orders) {
      if (order.bookingId == bookingId) {
        return order;
      }
    }
    return null;
  }

  static String _formatCurrency(double? value) {
    if (value == null) return 'Rp 0';
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
}

class _AdminPaymentBookingCard extends StatelessWidget {
  const _AdminPaymentBookingCard({
    required this.booking,
    required this.order,
    required this.isLoading,
    required this.onVerifyWithId,
  });

  final Booking booking;
  final ServiceOrder? order;
  final bool isLoading;
  final VoidCallback onVerifyWithId;

  @override
  Widget build(BuildContext context) {
    final status = booking.status?.toLowerCase() ?? '-';
    final isWaitingPayment = status == 'waiting_payment';

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
                  Icons.receipt_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${booking.nomorBooking ?? booking.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (order != null)
                      Text(
                        'Service Order #${order!.id}',
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
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Total Tagihan',
            value: order?.grandTotal != null
                ? _AdminPaymentsPageState._formatCurrency(order!.grandTotal)
                : 'Menunggu kalkulasi',
            isBold: true,
          ),
          if (booking.jenisLayanan != null)
            _InfoRow(label: 'Layanan', value: booking.jenisLayanan!),
          if (booking.tanggal != null)
            _InfoRow(
              label: 'Jadwal',
              value: '${booking.tanggal} ${booking.waktu ?? ''}'.trim(),
            ),
          if (order?.diagnosis != null && order!.diagnosis!.trim().isNotEmpty)
            _InfoRow(label: 'Diagnosis', value: order!.diagnosis!),
          if (booking.keluhan != null && booking.keluhan!.trim().isNotEmpty)
            _InfoRow(label: 'Keluhan', value: booking.keluhan!),
          const SizedBox(height: 14),
          Row(
            children: [
              const Spacer(),
              if (isWaitingPayment)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : onVerifyWithId,
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: const Text('Verifikasi Pembayaran'),
                )
              else if (status == 'paid')
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Pembayaran Terverifikasi',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              else if (status == 'cancelled')
                const Row(
                  children: [
                    Icon(Icons.cancel, color: AppColors.error, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Booking Dibatalkan',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? AppColors.primary : AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentVerifyOrRejectDialog extends StatefulWidget {
  final Booking booking;
  final ServiceOrder? order;

  const _PaymentVerifyOrRejectDialog({required this.booking, this.order});

  @override
  State<_PaymentVerifyOrRejectDialog> createState() =>
      _PaymentVerifyOrRejectDialogState();
}

class _PaymentVerifyOrRejectDialogState
    extends State<_PaymentVerifyOrRejectDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text(
        'Verifikasi Pembayaran',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking #${widget.booking.nomorBooking ?? widget.booking.id}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.order != null) ...[
              const SizedBox(height: 4),
              Text(
                'Order #${widget.order!.id} — Total: ${_AdminPaymentsPageState._formatCurrency(widget.order!.grandTotal)}',
                style: const TextStyle(color: AppColors.secondary),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Sesuai kontrak API, masukkan ID Pembayaran (Payment ID) resmi transaksi ini:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'ID Pembayaran (Payment ID)',
                hintText: 'Contoh: 1',
                hintStyle: TextStyle(color: AppColors.textMuted),
                prefixIcon: Icon(Icons.numbers, color: AppColors.secondary),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
          ),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(context).pop('reject:$text');
          },
          child: const Text('Tolak'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(context).pop('verify:$text');
          },
          child: const Text('Verifikasi'),
        ),
      ],
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  final int paymentId;

  const _RejectReasonDialog({required this.paymentId});

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      title: Text(
        'Tolak Pembayaran #${widget.paymentId}',
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Masukkan alasan penolakan pembayaran:',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText:
                  'Contoh: Bukti transfer tidak valid / nominal tidak sesuai',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
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
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(context).pop(text);
          },
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}

class _PaymentLookupDialog extends StatefulWidget {
  const _PaymentLookupDialog();

  @override
  State<_PaymentLookupDialog> createState() => _PaymentLookupDialogState();
}

class _PaymentLookupDialogState extends State<_PaymentLookupDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      title: const Text(
        'Cek Detail Pembayaran',
        style: TextStyle(color: AppColors.textPrimary),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(
          labelText: 'ID Pembayaran (Payment ID)',
          hintText: 'Contoh: 1',
          prefixIcon: Icon(Icons.search, color: AppColors.secondary),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Tutup',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final parsed = int.tryParse(_controller.text.trim());
            if (parsed != null) {
              Navigator.of(context).pop(parsed);
            }
          },
          child: const Text('Cari'),
        ),
      ],
    );
  }
}
