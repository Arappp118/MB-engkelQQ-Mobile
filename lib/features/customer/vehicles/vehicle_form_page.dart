import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../models/vehicle.dart';
import '../../../providers/vehicle_provider.dart';

class VehicleFormPage extends StatefulWidget {
  const VehicleFormPage({super.key, this.vehicle});

  final Vehicle? vehicle;

  bool get isEdit => vehicle != null;

  @override
  State<VehicleFormPage> createState() => _VehicleFormPageState();
}

class _VehicleFormPageState extends State<VehicleFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomorPolisiController;
  late final TextEditingController _merkController;
  late final TextEditingController _modelController;
  late final TextEditingController _tahunController;
  late final TextEditingController _tipeMesinController;
  late final TextEditingController _transmisiController;
  late final TextEditingController _warnaController;
  late final TextEditingController _nomorRangkaController;
  late final TextEditingController _catatanController;

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    _nomorPolisiController = TextEditingController(
      text: vehicle?.nomorPolisi ?? '',
    );

    _merkController = TextEditingController(text: vehicle?.merk ?? '');

    _modelController = TextEditingController(text: vehicle?.model ?? '');

    _tahunController = TextEditingController(
      text: vehicle?.tahun?.toString() ?? '',
    );

    _tipeMesinController = TextEditingController(
      text: vehicle?.tipeMesin ?? '',
    );

    _transmisiController = TextEditingController(
      text: vehicle?.transmisi ?? '',
    );

    _warnaController = TextEditingController(text: vehicle?.warna ?? '');

    _nomorRangkaController = TextEditingController(
      text: vehicle?.nomorRangka ?? '',
    );

    _catatanController = TextEditingController(text: vehicle?.catatan ?? '');
  }

  @override
  void dispose() {
    _nomorPolisiController.dispose();
    _merkController.dispose();
    _modelController.dispose();
    _tahunController.dispose();
    _tipeMesinController.dispose();
    _transmisiController.dispose();
    _warnaController.dispose();
    _nomorRangkaController.dispose();
    _catatanController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<VehicleProvider>();

    final tahun = int.tryParse(_tahunController.text.trim());

    if (tahun == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tahun kendaraan harus berupa angka.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    bool success;

    if (widget.isEdit) {
      success = await provider.updateVehicle(
        id: widget.vehicle!.id,
        nomorPolisi: _nomorPolisiController.text.trim(),
        merk: _merkController.text.trim(),
        model: _modelController.text.trim(),
        tahun: tahun,
        tipeMesin: _optionalValue(_tipeMesinController),
        transmisi: _optionalValue(_transmisiController),
        warna: _optionalValue(_warnaController),
        nomorRangka: _optionalValue(_nomorRangkaController),
        catatan: _optionalValue(_catatanController),
      );
    } else {
      success = await provider.createVehicle(
        nomorPolisi: _nomorPolisiController.text.trim(),
        merk: _merkController.text.trim(),
        model: _modelController.text.trim(),
        tahun: tahun,
        tipeMesin: _optionalValue(_tipeMesinController),
        transmisi: _optionalValue(_transmisiController),
        warna: _optionalValue(_warnaController),
        nomorRangka: _optionalValue(_nomorRangkaController),
        catatan: _optionalValue(_catatanController),
      );
    }

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEdit
                ? 'Data kendaraan berhasil diperbarui.'
                : 'Kendaraan berhasil ditambahkan.',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.errorMessage ??
              'Terjadi kesalahan saat menyimpan kendaraan.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String? _optionalValue(TextEditingController controller) {
    final value = controller.text.trim();

    if (value.isEmpty) {
      return null;
    }

    return value;
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi.';
    }

    return null;
  }

  String? _yearValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tahun wajib diisi.';
    }

    final year = int.tryParse(value.trim());

    if (year == null) {
      return 'Tahun harus berupa angka.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(
                  title: 'Informasi Utama',
                  subtitle: 'Data wajib identitas sepeda motor Anda',
                ),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomorPolisiController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Polisi (Plat Motor)',
                          hintText: 'Contoh: BP 1234 XY',
                          prefixIcon: Icon(Icons.credit_card_outlined),
                        ),
                        validator: (value) =>
                            _requiredValidator(value, 'Nomor polisi'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _merkController,
                        decoration: const InputDecoration(
                          labelText: 'Merk Kendaraan',
                          hintText: 'Contoh: Honda, Yamaha, Suzuki',
                          prefixIcon: Icon(Icons.branding_watermark_outlined),
                        ),
                        validator: (value) =>
                            _requiredValidator(value, 'Merk kendaraan'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model / Tipe',
                          hintText: 'Contoh: Vario 160, Beat, NMAX',
                          prefixIcon: Icon(Icons.two_wheeler_outlined),
                        ),
                        validator: (value) =>
                            _requiredValidator(value, 'Model kendaraan'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tahunController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tahun Pembuatan',
                          hintText: 'Contoh: 2023',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        validator: _yearValidator,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(
                  title: 'Spesifikasi Tambahan (Opsional)',
                  subtitle: 'Detail mesin, transmisi, dan warna',
                ),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _tipeMesinController,
                        decoration: const InputDecoration(
                          labelText: 'Kapasitas / Tipe Mesin',
                          hintText: 'Contoh: 150cc, 4-tak',
                          prefixIcon: Icon(Icons.speed_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _transmisiController,
                        decoration: const InputDecoration(
                          labelText: 'Transmisi',
                          hintText: 'Contoh: Matic, Manual, Bebek',
                          prefixIcon: Icon(Icons.tune_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _warnaController,
                        decoration: const InputDecoration(
                          labelText: 'Warna Motor',
                          hintText: 'Contoh: Hitam Glossy, Merah',
                          prefixIcon: Icon(Icons.palette_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nomorRangkaController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Rangka (VIN)',
                          hintText: 'Opsional untuk kelengkapan administrasi',
                          prefixIcon: Icon(Icons.qr_code_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Kendaraan',
                          hintText: 'Riwayat modifikasi atau catatan khusus...',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  text: widget.isEdit
                      ? 'Simpan Perubahan'
                      : 'Tambahkan Kendaraan',
                  icon: Icons.check_circle_outline,
                  isLoading: provider.isLoading,
                  onPressed: provider.isLoading ? null : _submit,
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
