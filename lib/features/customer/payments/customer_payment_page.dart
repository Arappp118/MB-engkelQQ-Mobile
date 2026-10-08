import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          title: const Text('Pembayaran Berhasil'),
          content: Text(
            payment?.id != null
                ? 'Pembayaran #${payment!.id} berhasil dikirim dan menunggu verifikasi admin.'
                : 'Pembayaran berhasil dikirim dan menunggu verifikasi admin.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.serviceOrder;
    final provider = context.watch<PaymentProvider>();
    final isProofRequired =
        _selectedMethod == 'transfer' || _selectedMethod == 'qris';

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOrderSummary(order),
          const SizedBox(height: 16),
          _buildPaymentMethod(isProofRequired),
          const SizedBox(height: 16),
          if (isProofRequired) _buildProofSection(),
          if (isProofRequired) const SizedBox(height: 16),
          _buildSubmitSection(provider.isLoading),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(ServiceOrder order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pembayaran',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            _InfoRow(label: 'Service Order', value: '#${order.id}'),
            _InfoRow(label: 'Subtotal', value: _formatCurrency(order.subtotal)),
            _InfoRow(
              label: 'Biaya Pickup',
              value: _formatCurrency(order.deliveryFee),
            ),
            const Divider(height: 24),
            _InfoRow(
              label: 'Total',
              value: _formatCurrency(order.grandTotal),
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(bool isProofRequired) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RadioGroup<String>(
              groupValue: _selectedMethod,
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedMethod = value;

                  if (value == 'cash') {
                    _proofPath = null;
                    _proofName = null;
                  }
                });
              },
              child: const Column(
                children: [
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'cash',
                    title: Text('Cash'),
                    subtitle: Text('Bayar secara tunai.'),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'transfer',
                    title: Text('Transfer'),
                    subtitle: Text('Upload bukti transfer.'),
                  ),
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: 'qris',
                    title: Text('QRIS'),
                    subtitle: Text('Upload bukti pembayaran QRIS.'),
                  ),
                ],
              ),
            ),
            if (isProofRequired)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Bukti pembayaran wajib untuk Transfer dan QRIS.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bukti Pembayaran',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Format: JPG, JPEG, PNG, atau PDF. '
              'Maksimal 2 MB.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickProof,
              icon: const Icon(Icons.upload_file),
              label: Text(
                _proofName == null ? 'Pilih Bukti Pembayaran' : 'Ganti File',
              ),
            ),
            if (_proofName != null) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.insert_drive_file_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_proofName!)),
                  IconButton(
                    tooltip: 'Hapus file',
                    onPressed: () {
                      setState(() {
                        _proofPath = null;
                        _proofName = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitSection(bool isLoading) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _submitPayment,
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payment),
            label: Text(
              isLoading ? 'Mengirim Pembayaran...' : 'Kirim Pembayaran',
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pembayaran akan menunggu verifikasi admin.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
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
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: style)),
          Expanded(child: Text(value, style: style)),
        ],
      ),
    );
  }
}
