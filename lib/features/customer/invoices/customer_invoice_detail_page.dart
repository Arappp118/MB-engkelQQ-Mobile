import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/invoice.dart';
import '../../../providers/invoice_provider.dart';
import '../service_orders/customer_service_order_detail_page.dart';

class CustomerInvoiceDetailPage extends StatefulWidget {
  const CustomerInvoiceDetailPage({super.key, required this.serviceOrderId});

  final int serviceOrderId;

  @override
  State<CustomerInvoiceDetailPage> createState() =>
      _CustomerInvoiceDetailPageState();
}

class _CustomerInvoiceDetailPageState extends State<CustomerInvoiceDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoice(widget.serviceOrderId);
    });
  }

  Future<void> _refresh() async {
    await context.read<InvoiceProvider>().loadInvoice(widget.serviceOrderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Invoice')),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          final invoice = provider.selectedInvoice;

          if (provider.isLoading && invoice == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && invoice == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Invoice tidak dapat dimuat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(provider.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (invoice == null) {
            return const Center(child: Text('Data invoice tidak ditemukan.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InvoiceHeaderCard(
                  invoice: invoice,
                  serviceOrderId: widget.serviceOrderId,
                ),
                const SizedBox(height: 16),
                _CustomerVehicleCard(invoice: invoice),
                const SizedBox(height: 16),
                _InvoiceItemsCard(invoice: invoice),
                const SizedBox(height: 16),
                _InvoiceCostSummaryCard(invoice: invoice),
                const SizedBox(height: 16),
                _InvoicePaymentCard(invoice: invoice),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerServiceOrderDetailPage(
                          serviceOrderId: widget.serviceOrderId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.build_outlined),
                  label: const Text('Lihat Detail Servis'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceHeaderCard extends StatelessWidget {
  const _InvoiceHeaderCard({
    required this.invoice,
    required this.serviceOrderId,
  });

  final Invoice invoice;
  final int serviceOrderId;

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
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invoice.invoiceNumber,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _DetailRow(label: 'Service Order ID', value: '#$serviceOrderId'),
            if (invoice.nomorBooking != null) ...[
              const SizedBox(height: 8),
              _DetailRow(label: 'Nomor Booking', value: invoice.nomorBooking!),
            ],
            if (invoice.tanggal != null) ...[
              const SizedBox(height: 8),
              _DetailRow(label: 'Tanggal', value: invoice.tanggal!),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomerVehicleCard extends StatelessWidget {
  const _CustomerVehicleCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final vehicleDesc = [
      if (invoice.vehicleMerk != null) invoice.vehicleMerk,
      if (invoice.vehicleModel != null) invoice.vehicleModel,
    ].join(' ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pelanggan & Kendaraan',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            if (invoice.customerName != null)
              _DetailRow(label: 'Pelanggan', value: invoice.customerName!),
            if (invoice.customerEmail != null) ...[
              const SizedBox(height: 8),
              _DetailRow(label: 'Email', value: invoice.customerEmail!),
            ],
            if (invoice.vehiclePlate != null) ...[
              const SizedBox(height: 8),
              _DetailRow(label: 'Plat Nomor', value: invoice.vehiclePlate!),
            ],
            if (vehicleDesc.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(label: 'Kendaraan', value: vehicleDesc),
            ],
          ],
        ),
      ),
    );
  }
}

class _InvoiceItemsCard extends StatelessWidget {
  const _InvoiceItemsCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final items = invoice.items;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Item & Servis',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            if (items.isEmpty)
              const Text('Tidak ada item tercatat.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              '${item.quantity} x ${_formatCurrency(item.price)}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCostSummaryCard extends StatelessWidget {
  const _InvoiceCostSummaryCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Biaya',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _DetailRow(
              label: 'Subtotal Item',
              value: _formatCurrency(invoice.subtotal),
            ),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Biaya Pengiriman/Pickup',
              value: _formatCurrency(invoice.deliveryFee),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatCurrency(invoice.grandTotal),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoicePaymentCard extends StatelessWidget {
  const _InvoicePaymentCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pembayaran',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _DetailRow(
              label: 'Status Pembayaran',
              value: (invoice.paymentStatus ?? 'Belum ada').toUpperCase(),
            ),
            if (invoice.paymentMethod != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                label: 'Metode Pembayaran',
                value: invoice.paymentMethod!.toUpperCase(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
