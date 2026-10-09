import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../models/payment.dart';
import '../../../models/service_order.dart';
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
    await context.read<ServiceOrderProvider>().loadServiceOrders();
  }

  Future<void> _verifyPayment(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
          content: Text(
            'Apakah pembayaran #${payment.id} sebesar '
            '${_formatCurrency(payment.amount)} ingin diverifikasi?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
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
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Verifikasi'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final provider = context.read<PaymentProvider>();
    final success = await provider.verifyPayment(payment.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil diverifikasi.'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal memverifikasi pembayaran.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _rejectPayment(Payment payment) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Text(
            'Tolak Pembayaran',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan alasan penolakan pembayaran #${payment.id}:',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Contoh: Bukti transfer tidak jelas / nominal tidak sesuai',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
                final text = reasonController.text.trim();
                if (text.isEmpty) return;
                Navigator.of(dialogContext).pop(text);
              },
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.isEmpty || !mounted) return;

    final provider = context.read<PaymentProvider>();
    final success = await provider.rejectPayment(payment.id, reason: reason);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pembayaran berhasil ditolak.'),
          backgroundColor: AppColors.warning,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menolak pembayaran.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showProofDialog(Payment payment) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final hasProof =
            payment.hasProof == true ||
            (payment.proofUrl != null && payment.proofUrl!.isNotEmpty);

        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Text(
            'Bukti Pembayaran #${payment.id}',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (payment.proofUrl != null && payment.proofUrl!.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      payment.proofUrl!,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Gagal memuat gambar bukti.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                    ),
                  ),
                )
              else if (hasProof)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bukti transfer/QRIS telah diunggah oleh pelanggan.',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Tidak ada file bukti pembayaran terlampir.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Catatan:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payment.notes!,
                  style: const TextStyle(color: AppColors.textSecondary),
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = context.watch<PaymentProvider>();
    final orderProvider = context.watch<ServiceOrderProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Pembayaran'),
        actions: [
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
          Expanded(child: _buildBody(orderProvider, paymentProvider)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'waiting_verification', 'label': 'Menunggu'},
      {'key': 'verified', 'label': 'Terverifikasi'},
      {'key': 'rejected', 'label': 'Ditolak'},
      {'key': 'all', 'label': 'Semua'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
    ServiceOrderProvider orderProvider,
    PaymentProvider paymentProvider,
  ) {
    if (orderProvider.isLoading && orderProvider.serviceOrders.isEmpty) {
      return const LoadingState(message: 'Memuat data pembayaran...');
    }

    if (orderProvider.errorMessage != null &&
        orderProvider.serviceOrders.isEmpty) {
      return ErrorState(
        message: orderProvider.errorMessage!,
        onRetry: _loadData,
      );
    }

    // Filter service orders yang relevan
    final orders = orderProvider.serviceOrders;
    final filtered = orders.where((o) {
      final status = o.status?.toLowerCase();
      if (_selectedFilter == 'waiting_verification') {
        return status == 'waiting_payment';
      }
      if (_selectedFilter == 'verified') {
        return status == 'paid';
      }
      if (_selectedFilter == 'rejected') {
        return status == 'payment_rejected' ||
            (status == 'waiting_payment' && o.notes?.isNotEmpty == true);
      }
      // 'all'
      return status == 'waiting_payment' ||
          status == 'paid' ||
          status == 'completed' ||
          status == 'payment_rejected';
    }).toList();

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Tidak Ada Data',
              message: _selectedFilter == 'waiting_verification'
                  ? 'Tidak ada pembayaran menunggu verifikasi.'
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
          final order = filtered[index];

          return _AdminPaymentCard(
            order: order,
            isLoading: paymentProvider.isLoading,
            onVerify: () {
              // ServiceOrder ID dipakai sebagai identifier pembayaran
              _verifyPayment(
                Payment(
                  id: order.id,
                  serviceOrderId: order.id,
                  amount: order.grandTotal,
                  status: 'waiting_verification',
                ),
              );
            },
            onReject: () {
              _rejectPayment(
                Payment(
                  id: order.id,
                  serviceOrderId: order.id,
                  amount: order.grandTotal,
                  status: 'waiting_verification',
                ),
              );
            },
            onViewProof: () {
              _showProofDialog(
                Payment(
                  id: order.id,
                  serviceOrderId: order.id,
                  amount: order.grandTotal,
                  hasProof: true,
                  notes: order.notes,
                ),
              );
            },
          );
        },
      ),
    );
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

class _AdminPaymentCard extends StatelessWidget {
  const _AdminPaymentCard({
    required this.order,
    required this.isLoading,
    required this.onVerify,
    required this.onReject,
    required this.onViewProof,
  });

  final ServiceOrder order;
  final bool isLoading;
  final VoidCallback onVerify;
  final VoidCallback onReject;
  final VoidCallback onViewProof;

  @override
  Widget build(BuildContext context) {
    final status = order.status?.toLowerCase() ?? '-';
    final isPendingVerification = status == 'waiting_payment';

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
                  Icons.payment_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order #${order.id}',
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
          _InfoRow(
            label: 'Booking',
            value: order.bookingId != null ? '#${order.bookingId}' : '-',
          ),
          _InfoRow(
            label: 'Total Tagihan',
            value: _formatCurrency(order.grandTotal),
            isBold: true,
          ),
          if (order.diagnosis != null && order.diagnosis!.trim().isNotEmpty)
            _InfoRow(label: 'Diagnosis', value: order.diagnosis!),
          if (order.notes != null && order.notes!.trim().isNotEmpty)
            _InfoRow(label: 'Catatan', value: order.notes!),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onViewProof,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Bukti'),
              ),
              const Spacer(),
              if (isPendingVerification) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : onReject,
                  child: const Text('Tolak'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading ? null : onVerify,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Verifikasi'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
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
