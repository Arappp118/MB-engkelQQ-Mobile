import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/payment.dart';
import '../../../models/service_order.dart';
import '../../../providers/payment_provider.dart';

class CustomerPaymentPage extends StatefulWidget {
  const CustomerPaymentPage({super.key, required this.serviceOrder});

  final ServiceOrder serviceOrder;

  @override
  State<CustomerPaymentPage> createState() => _CustomerPaymentPageState();
}

class _CustomerPaymentPageState extends State<CustomerPaymentPage> {
  String _selectedMethod = 'cash';
  String? _proofPath;
  String? _proofName;

  Future<void> _pickProof() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result.isEmpty) {
      return;
    }

    final file = result.single;

    if (file.path == null || file.path!.isEmpty) {
      _showMessage('File tidak dapat diakses.');
      return;
    }

    final selectedFile = File(file.path!);

    final fileSize = await selectedFile.length();

    if (fileSize > 2 * 1024 * 1024) {
      _showMessage('Ukuran bukti pembayaran maksimal 2 MB.');
      return;
    }

    setState(() {
      _proofPath = file.path;
      _proofName = file.name;
    });
  }

  Future<void> _submitPayment() async {
    if (_selectedMethod != 'cash' &&
        (_proofPath == null || _proofPath!.isEmpty)) {
      _showMessage('Bukti pembayaran wajib diunggah untuk Transfer/QRIS.');
      return;
    }

    final provider = context.read<PaymentProvider>();

    final success = await provider.createPayment(
      serviceOrderId: widget.serviceOrder.id,
      method: _selectedMethod,
      proofPath: _proofPath,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(provider.errorMessage ?? 'Pembayaran gagal dibuat.');
      return;
    }

    final payment = provider.selectedPayment;

    await _showSuccessDialog(payment);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _showSuccessDialog(Payment? payment) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          icon: const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 48,
          ),
          title: const Text(
            'Pembayaran Berhasil Dikirim',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            payment?.id != null
                ? 'Pembayaran #${payment!.id} berhasil dikirim dan menunggu verifikasi admin.'
                : 'Pembayaran berhasil dikirim dan menunggu verifikasi admin.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            Center(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(120, 44),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceCardElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.serviceOrder;
    final provider = context.watch<PaymentProvider>();
    final isProofRequired =
        _selectedMethod == 'transfer' || _selectedMethod == 'qris';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konfirmasi Pembayaran'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
            title: 'Tagihan Servis',
            subtitle: 'Rincian total biaya yang harus dibayarkan',
          ),
          _buildOrderSummary(order),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'Metode Pembayaran',
            subtitle: 'Pilih salah satu metode pembayaran yang tersedia',
          ),
          _buildPaymentMethod(isProofRequired),
          const SizedBox(height: 20),
          if (isProofRequired) ...[
            const SectionHeader(
              title: 'Upload Bukti Bayar',
              subtitle: 'Lampirkan foto/struk transfer atau QRIS',
            ),
            _buildProofSection(),
            const SizedBox(height: 24),
          ],
          _buildSubmitSection(provider.isLoading),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ServiceOrder order) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tagihan Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Subtotal Jasa & Part',
            value: _formatCurrency(order.subtotal),
          ),
          _InfoRow(
            label: 'Biaya Penjemputan (Pickup)',
            value: _formatCurrency(order.deliveryFee),
          ),
          const Divider(color: AppColors.borderSubtle, height: 20),
          _InfoRow(
            label: 'Total Tagihan',
            value: _formatCurrency(order.grandTotal),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(bool isProofRequired) {
    return PremiumCard(
      padding: const EdgeInsets.all(8),
      child: RadioGroup<String>(
        groupValue: _selectedMethod,
        onChanged: (val) {
          if (val != null) {
            setState(() {
              _selectedMethod = val;
              if (val == 'cash') {
                _proofPath = null;
                _proofName = null;
              }
            });
          }
        },
        child: Column(
          children: [
            _buildMethodTile(
              value: 'cash',
              title: 'Bayar Tunai (Cash)',
              subtitle: 'Bayar langsung ke kasir bengkel atau kurir pickup.',
              icon: Icons.payments_outlined,
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            _buildMethodTile(
              value: 'transfer',
              title: 'Transfer Bank',
              subtitle: 'BCA / Mandiri / BNI. Upload struk bukti transfer.',
              icon: Icons.account_balance_outlined,
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
            _buildMethodTile(
              value: 'qris',
              title: 'QRIS (Gopay/OVO/Dana/BCA)',
              subtitle: 'Pindai barcode QRIS dan upload tangkapan layar bukti.',
              icon: Icons.qr_code_2_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMethod = value;
          if (value == 'cash') {
            _proofPath = null;
            _proofName = null;
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceCardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryLight
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(value: value, activeColor: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lampiran Bukti Pembayaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Format yang didukung: JPG, PNG, PDF (Maks. 2 MB)',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SecondaryButton(
            text: _proofName == null ? 'Pilih File Bukti' : 'Ganti File',
            icon: Icons.upload_file_rounded,
            onPressed: _pickProof,
          ),
          if (_proofName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceCardElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _proofName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus file',
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.textMuted,
                    onPressed: () {
                      setState(() {
                        _proofPath = null;
                        _proofName = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitSection(bool isLoading) {
    return Column(
      children: [
        PrimaryButton(
          text: isLoading ? 'Mengirim Pembayaran...' : 'Kirim Pembayaran',
          icon: Icons.payment_rounded,
          isLoading: isLoading,
          onPressed: isLoading ? null : _submitPayment,
        ),
        const SizedBox(height: 8),
        const Text(
          'Pembayaran akan segera diverifikasi oleh tim admin bengkel.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
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
                fontSize: bold ? 18 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
