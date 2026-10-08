import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        const SnackBar(content: Text('Tahun kendaraan harus berupa angka.')),
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

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan'),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, provider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _nomorPolisiController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoration(
                    'Nomor Polisi',
                    hint: 'Contoh: BP 1234 XX',
                  ),
                  validator: (value) {
                    return _requiredValidator(value, 'Nomor polisi');
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _merkController,
                  decoration: _decoration('Merek', hint: 'Contoh: Honda'),
                  validator: (value) {
                    return _requiredValidator(value, 'Merek');
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _modelController,
                  decoration: _decoration('Model', hint: 'Contoh: Vario 160'),
                  validator: (value) {
                    return _requiredValidator(value, 'Model');
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _tahunController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Tahun', hint: 'Contoh: 2024'),
                  validator: _yearValidator,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _tipeMesinController,
                  decoration: _decoration('Tipe Mesin', hint: 'Contoh: 160cc'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _transmisiController,
                  decoration: _decoration(
                    'Transmisi',
                    hint: 'Contoh: Automatic',
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _warnaController,
                  decoration: _decoration('Warna', hint: 'Contoh: Hitam'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nomorRangkaController,
                  decoration: _decoration('Nomor Rangka'),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _catatanController,
                  maxLines: 3,
                  decoration: _decoration(
                    'Catatan',
                    hint: 'Catatan tambahan kendaraan',
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: provider.isLoading ? null : _submit,
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.isEdit
                                ? 'Simpan Perubahan'
                                : 'Tambah Kendaraan',
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
