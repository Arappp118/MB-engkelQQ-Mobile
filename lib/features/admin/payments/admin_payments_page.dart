import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
          title: const Text('Verifikasi Pembayaran'),
          content: Text(
            'Apakah pembayaran #${payment.id} sebesar '
            '${_formatCurrency(payment.amount)} ingin diverifikasi?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
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
        const SnackBar(content: Text('Pembayaran berhasil diverifikasi.')),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal memverifikasi pembayaran.',
          ),
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
          title: const Text('Tolak Pembayaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Masukkan alasan penolakan pembayaran #${payment.id}:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Bukti transfer tidak jelas / nominal tidak sesuai',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).colorScheme.error,
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
        const SnackBar(content: Text('Pembayaran berhasil ditolak.')),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menolak pembayaran.'),
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
          title: Text('Bukti Pembayaran #${payment.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (payment.proofUrl != null && payment.proofUrl!.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      payment.proofUrl!,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Gagal memuat gambar bukti.'),
                          ),
                    ),
                  ),
                )
              else if (hasProof)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bukti transfer/QRIS telah diunggah oleh pelanggan.',
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Tidak ada file bukti pembayaran terlampir.'),
                ),
              if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Catatan:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(payment.notes!),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
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
                label: Text(label),
                selected: isSelected,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (orderProvider.errorMessage != null &&
        orderProvider.serviceOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(orderProvider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
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
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 140),
            Center(
              child: Text(
                _selectedFilter == 'waiting_verification'
                    ? 'Tidak ada pembayaran menunggu verifikasi.'
                    : 'Tidak ada data pembayaran dengan status ini.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Order #${order.id}',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _PaymentStatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 14),
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
                  onPressed: onViewProof,
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Bukti'),
                ),
                const Spacer(),
                if (isPendingVerification) ...[
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: isLoading ? null : onReject,
                    child: const Text('Tolak'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: isLoading ? null : onVerify,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Verifikasi'),
                  ),
                ],
              ],
            ),
          ],
        ),
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

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'waiting_payment':
      case 'waiting_verification':
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.orange.shade800;
        label = 'Menunggu Verifikasi';
        break;
      case 'paid':
      case 'verified':
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade800;
        label = 'Terverifikasi';
        break;
      case 'payment_rejected':
      case 'rejected':
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade800;
        label = 'Ditolak';
        break;
      default:
        bg = Theme.of(context).colorScheme.secondaryContainer;
        fg = Theme.of(context).colorScheme.onSecondaryContainer;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
