import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Invoice'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          final invoice = provider.selectedInvoice;

          if (provider.isLoading && invoice == null) {
            return const LoadingState(
              height: 350,
              message: 'Memuat data faktur...',
            );
          }

          if (provider.errorMessage != null && invoice == null) {
            return ErrorState(
              title: 'Invoice Tidak Dapat Dimuat',
              message: provider.errorMessage!,
              onRetry: _refresh,
            );
          }

          if (invoice == null) {
            return const Center(
              child: EmptyState(
                title: 'Data Tidak Ditemukan',
                message: 'Data invoice untuk pesanan servis ini tidak ada.',
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
                _InvoiceHeaderCard(
                  invoice: invoice,
                  serviceOrderId: widget.serviceOrderId,
                ),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Informasi Pelanggan',
                  subtitle: 'Data kepemilikan dan kendaraan bermotor',
                ),
                _CustomerVehicleCard(invoice: invoice),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Rincian Servis & Sparepart',
                  subtitle: 'Komponen yang diperbaiki atau diganti',
                ),
                _InvoiceItemsCard(invoice: invoice),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Rincian Pembayaran',
                  subtitle: 'Total kalkulasi biaya resmi',
                ),
                _InvoiceCostSummaryCard(invoice: invoice),
                const SizedBox(height: 20),
                const SectionHeader(
                  title: 'Status & Metode',
                  subtitle: 'Status verifikasi transaksi keuangan',
                ),
                _InvoicePaymentCard(invoice: invoice),
                const SizedBox(height: 24),
                SecondaryButton(
                  text: 'Lihat Detail Servis',
                  icon: Icons.build_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CustomerServiceOrderDetailPage(
                          serviceOrderId: widget.serviceOrderId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
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
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'FAKTUR RESMI BENGKEL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 12),
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

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_pin_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Informasi Pelanggan & Kendaraan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),
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
    );
  }
}

class _InvoiceItemsCard extends StatelessWidget {
  const _InvoiceItemsCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final items = invoice.items;

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Rincian Item & Servis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tidak ada item tercatat.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.borderSubtle, height: 16),
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
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.quantity} x ${_formatCurrency(item.price)}',
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
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InvoiceCostSummaryCard extends StatelessWidget {
  const _InvoiceCostSummaryCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(
            label: 'Subtotal Item',
            value: _formatCurrency(invoice.subtotal),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Biaya Pengiriman/Pickup',
            value: _formatCurrency(invoice.deliveryFee),
          ),
          const Divider(color: AppColors.borderSubtle, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatCurrency(invoice.grandTotal),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoicePaymentCard extends StatelessWidget {
  const _InvoicePaymentCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final statusText = (invoice.paymentStatus ?? 'Belum ada').toUpperCase();
    final methodText = (invoice.paymentMethod ?? '-').toUpperCase();

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.credit_card_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Informasi Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.borderSubtle, height: 1),
          const SizedBox(height: 10),
          _DetailRow(label: 'Status Pembayaran', value: statusText),
          if (invoice.paymentMethod != null) ...[
            const SizedBox(height: 8),
            _DetailRow(label: 'Metode Pembayaran', value: methodText),
          ],
        ],
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
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
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
