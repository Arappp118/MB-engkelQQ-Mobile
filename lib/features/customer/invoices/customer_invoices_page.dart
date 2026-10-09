import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../models/invoice.dart';
import '../../../providers/invoice_provider.dart';
import 'customer_invoice_detail_page.dart';

class CustomerInvoicesPage extends StatefulWidget {
  const CustomerInvoicesPage({super.key});

  @override
  State<CustomerInvoicesPage> createState() => _CustomerInvoicesPageState();
}

class _CustomerInvoicesPageState extends State<CustomerInvoicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
    });
  }

  Future<void> _refresh() async {
    await context.read<InvoiceProvider>().loadInvoices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Invoice'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          final invoices = provider.invoices;

          if (provider.isLoading && invoices.isEmpty) {
            return const LoadingState(
              height: 350,
              message: 'Memuat riwayat invoice...',
            );
          }

          if (provider.errorMessage != null && invoices.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 60),
                  ErrorState(
                    title: 'Gagal Memuat Invoice',
                    message: provider.errorMessage!,
                    onRetry: _refresh,
                  ),
                ],
              ),
            );
          }

          if (invoices.isEmpty) {
            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum Ada Invoice',
                    message: 'Invoice akan dibuat dan tersedia secara otomatis setelah pekerjaan servis kendaraan Anda selesai.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surfaceCard,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return _InvoiceItemCard(invoice: invoice);
              },
            ),
          );
        },
      ),
    );
  }
}

class _InvoiceItemCard extends StatelessWidget {
  const _InvoiceItemCard({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        if (invoice.serviceOrderId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerInvoiceDetailPage(
                serviceOrderId: invoice.serviceOrderId!,
              ),
            ),
          );
        }
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Service Order #${invoice.serviceOrderId ?? '-'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(invoice.grandTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
        ],
      ),
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
