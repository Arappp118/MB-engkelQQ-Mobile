import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../invoices/customer_invoice_detail_page.dart';
import '../payments/customer_payment_page.dart';

import '../../../models/service_order.dart';
import '../../../providers/service_order_provider.dart';

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
      context.read<ServiceOrderProvider>().loadServiceOrder(
        widget.serviceOrderId,
      );
    });
  }

  Future<void> _refresh() async {
    await context.read<ServiceOrderProvider>().loadServiceOrder(
      widget.serviceOrderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Servis')),
      body: Consumer<ServiceOrderProvider>(
        builder: (context, provider, _) {
          final order = provider.selectedServiceOrder;

          if (provider.isLoading && order == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && order == null) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: _refresh,
            );
          }

          if (order == null) {
            return const Center(
              child: Text('Data service order tidak ditemukan.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ServiceHeader(order: order),
                const SizedBox(height: 16),
                _DiagnosisCard(order: order),
                const SizedBox(height: 16),
                _ItemsCard(order: order),
                const SizedBox(height: 16),
                _SummaryCard(order: order),
                const SizedBox(height: 16),
                _PaymentSection(order: order),
                if (order.status?.toLowerCase() == 'completed' ||
                    order.status?.toLowerCase() == 'paid') ...[
                  const SizedBox(height: 16),
                  _InvoiceSection(order: order),
                ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Order',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              '#${order.id}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Status:'),
                const SizedBox(width: 8),
                _StatusBadge(status: order.status),
              ],
            ),
          ],
        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Diagnosis Mekanik',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              diagnosis == null || diagnosis.isEmpty
                  ? 'Diagnosis belum tersedia.'
                  : diagnosis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tindakan / Item Servis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (order.items.isEmpty)
              const Text(
                'Belum ada item servis.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.build_outlined, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.quantity} x '
                                  '${_formatCurrency(item.price)}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatCurrency(item.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Subtotal',
              value: _formatCurrency(order.subtotal),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Biaya Pickup',
              value: _formatCurrency(order.deliveryFee),
            ),
            const Divider(height: 24),
            _SummaryRow(
              label: 'Grand Total',
              value: _formatCurrency(order.grandTotal),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    final status = order.status?.toLowerCase();

    if (status == 'paid') {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle_outline, color: Colors.green),
                title: Text('Pembayaran Selesai'),
                subtitle: Text('Pembayaran servis Anda telah diverifikasi.'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerInvoiceDetailPage(serviceOrderId: order.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Lihat Invoice'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (status != 'completed' && status != 'waiting_payment') {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.payment_outlined),
          title: const Text('Pembayaran'),
          subtitle: const Text('Pembayaran tersedia setelah servis selesai.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total yang harus dibayar: '
              '${_formatCurrency(order.grandTotal)}',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.payment),
                label: const Text('Bayar Sekarang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.order});

  final ServiceOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Invoice Servis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Servis telah selesai. Anda dapat melihat rincian tagihan resmi untuk pesanan servis ini.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CustomerInvoiceDetailPage(serviceOrderId: order.id),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Buka Invoice'),
              ),
            ),
          ],
        ),
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
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade200,
      ),
      child: Text(
        _formatStatus(status),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}

String _formatStatus(String? value) {
  if (value == null || value.isEmpty) {
    return '-';
  }

  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
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
