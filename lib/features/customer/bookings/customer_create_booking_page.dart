import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/service_area_constants.dart';
import '../../../models/vehicle.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../services/location_service.dart';
import '../../maps/interactive_map_page.dart';

class CustomerCreateBookingPage extends StatefulWidget {
  const CustomerCreateBookingPage({super.key});

  @override
  State<CustomerCreateBookingPage> createState() =>
      _CustomerCreateBookingPageState();
}

class _CustomerCreateBookingPageState extends State<CustomerCreateBookingPage> {
  final _formKey = GlobalKey<FormState>();

  final _keluhanController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _catatanController = TextEditingController();
  final _alamatPickupController = TextEditingController();
  final _jarakController = TextEditingController();

  final LocationService _locationService = LocationService();

  int? _selectedVehicleId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _selectedService = 'servis_rutin';
  bool _pickupRequested = false;

  // Koordinat GPS untuk pickup
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  final List<Map<String, String>> _serviceTypes = const [
    {'value': 'servis_rutin', 'label': 'Servis Rutin'},
    {'value': 'tune_up', 'label': 'Tune Up'},
    {'value': 'ganti_oli', 'label': 'Ganti Oli'},
    {'value': 'overhaul', 'label': 'Overhaul'},
    {'value': 'kelistrikan', 'label': 'Kelistrikan'},
    {'value': 'lainnya', 'label': 'Lainnya'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VehicleProvider>().loadVehicles();
    });
  }

  @override
  void dispose() {
    _keluhanController.dispose();
    _diagnosisController.dispose();
    _catatanController.dispose();
    _alamatPickupController.dispose();
    _jarakController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (selected != null) {
      setState(() {
        _selectedTime = selected;
      });
    }
  }

  void _showOutOfServiceAreaDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(
          Icons.location_off_rounded,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text(
          ServiceAreaConstants.outOfAreaTitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          ServiceAreaConstants.outOfAreaMessage,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _checkLocationAndValidateServiceArea();
            },
            child: const Text('Cek Lokasi Lagi'),
          ),
        ],
      ),
    );
  }

  void _showGpsErrorDialog(
    String title,
    String message, {
    LocationPermissionState? state,
    VoidCallback? onRetry,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: Icon(
          state == LocationPermissionState.serviceDisabled
              ? Icons.location_off_outlined
              : Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 44,
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          if (state == LocationPermissionState.serviceDisabled) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _locationService.openLocationSettings();
              },
              child: const Text('Buka Pengaturan Lokasi'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Tutup'),
            ),
          ] else if (state == LocationPermissionState.deniedForever) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                _locationService.openAppSettings();
              },
              child: const Text('Buka Pengaturan Aplikasi'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Tutup'),
            ),
          ] else ...[
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Tutup'),
            ),
            if (onRetry != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogCtx).pop();
                  onRetry();
                },
                child: const Text('Coba Lagi'),
              ),
          ],
        ],
      ),
    );
  }

  /// Mengambil GPS perangkat dan memvalidasi wilayah layanan Kota Tanjungpinang
  Future<void> _checkLocationAndValidateServiceArea({
    bool isAutoTriggered = false,
  }) async {
    if (_isGettingLocation) {
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final location = await _locationService.getCurrentLocationData();

      if (!mounted) {
        return;
      }

      // Validasi wilayah layanan Kota Tanjungpinang
      if (!location.isInsideServiceArea) {
        setState(() {
          _latitude = null;
          _longitude = null;
          _alamatPickupController.clear();
          _jarakController.clear();
          if (isAutoTriggered) {
            _pickupRequested = false;
          }
        });
        _showOutOfServiceAreaDialog();
        return;
      }

      // Berada di dalam Kota Tanjungpinang
      setState(() {
        _pickupRequested = true;
        _latitude = location.latitude;
        _longitude = location.longitude;

        if (location.address != null && location.address!.trim().isNotEmpty) {
          _alamatPickupController.text = location.address!;
        }

        if (location.distanceToWorkshopKm != null) {
          _jarakController.text = location.distanceToWorkshopKm!
              .toStringAsFixed(1);
        }
      });

      if (location.address == null || location.address!.trim().isEmpty) {
        _showMessage(
          'Lokasi GPS Tanjungpinang diperoleh. Silakan lengkapi detail jalan/patokan.',
        );
      } else {
        _showMessage(
          'Lokasi Kota Tanjungpinang terverifikasi. '
          'Jarak ke bengkel: ${_jarakController.text} km',
        );
      }
    } on LocationServiceException catch (e) {
      if (!mounted) {
        return;
      }
      if (isAutoTriggered) {
        setState(() {
          _pickupRequested = false;
        });
      }
      _showGpsErrorDialog(
        e.title ?? 'Lokasi Tidak Tersedia',
        e.message,
        state: e.state,
        onRetry: () => _checkLocationAndValidateServiceArea(
          isAutoTriggered: isAutoTriggered,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (isAutoTriggered) {
        setState(() {
          _pickupRequested = false;
        });
      }
      _showGpsErrorDialog(
        'Lokasi Tidak Tersedia',
        'Lokasi Anda belum dapat ditentukan. Silakan coba lagi.',
        onRetry: () => _checkLocationAndValidateServiceArea(
          isAutoTriggered: isAutoTriggered,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<MapPickerResult>(
      MaterialPageRoute(
        builder: (context) => InteractiveMapPage(
          mode: MapPageMode.picker,
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    // Validasi apakah titik yang dipilih berada di wilayah Kota Tanjungpinang
    if (!ServiceAreaConstants.isWithinServiceArea(
      result.latitude,
      result.longitude,
    )) {
      setState(() {
        _latitude = null;
        _longitude = null;
        _alamatPickupController.clear();
        _jarakController.clear();
      });
      _showOutOfServiceAreaDialog();
      return;
    }

    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      if (result.address.trim().isNotEmpty) {
        _alamatPickupController.text = result.address;
      }
      _jarakController.text = result.distanceKm.toStringAsFixed(1);
    });

    _showMessage(
      'Titik pickup di Kota Tanjungpinang dipilih. '
      'Estimasi jarak: ${result.distanceKm.toStringAsFixed(1)} km',
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedVehicleId == null) {
      _showMessage('Silakan pilih kendaraan.');
      return;
    }

    if (_selectedDate == null) {
      _showMessage('Silakan pilih tanggal booking.');
      return;
    }

    if (_selectedTime == null) {
      _showMessage('Silakan pilih waktu booking.');
      return;
    }

    final tanggal =
        '${_selectedDate!.year.toString().padLeft(4, '0')}-'
        '${_selectedDate!.month.toString().padLeft(2, '0')}-'
        '${_selectedDate!.day.toString().padLeft(2, '0')}';

    final waktu =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
        '${_selectedTime!.minute.toString().padLeft(2, '0')}';

    double? distance;

    if (_pickupRequested) {
      if (_latitude == null || _longitude == null) {
        _showGpsErrorDialog(
          'Lokasi Tidak Tersedia',
          'Silakan tentukan titik lokasi pickup di Kota Tanjungpinang terlebih dahulu.',
        );
        return;
      }

      if (!ServiceAreaConstants.isWithinServiceArea(_latitude!, _longitude!)) {
        _showOutOfServiceAreaDialog();
        return;
      }

      if (_alamatPickupController.text.trim().isEmpty) {
        _showMessage('Alamat pickup wajib diisi.');
        return;
      }

      final jarakText = _jarakController.text.trim();
      if (jarakText.isEmpty) {
        _showMessage('Estimasi jarak wajib diisi jika meminta pickup.');
        return;
      }

      final parsed = double.tryParse(jarakText);
      if (parsed == null || parsed <= 0) {
        _showMessage('Estimasi jarak harus berupa angka lebih dari 0.');
        return;
      }
      distance = parsed;
    }

    final provider = context.read<BookingProvider>();

    final success = await provider.createBooking(
      vehicleId: _selectedVehicleId!,
      tanggal: tanggal,
      waktu: waktu,
      keluhan: _keluhanController.text.trim(),
      diagnosisCustomer: _diagnosisController.text.trim().isEmpty
          ? null
          : _diagnosisController.text.trim(),
      jenisLayanan: _selectedService,
      pickupRequested: _pickupRequested,
      alamatPickup: _pickupRequested
          ? _alamatPickupController.text.trim()
          : null,
      estimatedDistanceKm: _pickupRequested ? distance : null,
      catatan: _catatanController.text.trim().isEmpty
          ? null
          : _catatanController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking berhasil dibuat.')));

      Navigator.of(context).pop();
      return;
    }

    final error = provider.errorMessage ?? 'Gagal membuat booking.';
    _showMessage(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Booking Servis')),
      body: Consumer2<VehicleProvider, BookingProvider>(
        builder: (context, vehicleProvider, bookingProvider, child) {
          if (vehicleProvider.isLoading && vehicleProvider.vehicles.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicles = vehicleProvider.vehicles;

          if (vehicles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.two_wheeler_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Anda belum memiliki kendaraan.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tambahkan kendaraan terlebih dahulu sebelum membuat booking servis.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<VehicleProvider>().loadVehicles();
                      },
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildVehicleDropdown(vehicles),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedService,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Layanan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build_outlined),
                  ),
                  items: _serviceTypes.map((item) {
                    return DropdownMenuItem<String>(
                      value: item['value'],
                      child: Text(item['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedService = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Booking',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Pilih tanggal'
                                : _formatDate(_selectedDate!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Waktu Booking',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time_outlined),
                          ),
                          child: Text(
                            _selectedTime == null
                                ? 'Pilih waktu'
                                : _selectedTime!.format(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _keluhanController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Keluhan Kendaraan',
                    hintText: 'Contoh: Rem belakang berbunyi, tarikan berat...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.report_problem_outlined),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Keluhan kendaraan wajib diisi.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _diagnosisController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis Mandiri (Opsional)',
                    hintText: 'Contoh: Kemungkinan kampas rem habis...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Minta Pickup Kendaraan (Kota Tanjungpinang)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _pickupRequested
                        ? 'Kendaraan akan dijemput oleh kurir di wilayah Kota Tanjungpinang.'
                        : 'Saya akan datang sendiri ke bengkel.',
                  ),
                  value: _pickupRequested,
                  onChanged: (value) {
                    if (value) {
                      setState(() {
                        _pickupRequested = true;
                      });
                      _checkLocationAndValidateServiceArea(
                        isAutoTriggered: true,
                      );
                    } else {
                      setState(() {
                        _pickupRequested = false;
                        _alamatPickupController.clear();
                        _jarakController.clear();
                        _latitude = null;
                        _longitude = null;
                      });
                    }
                  },
                ),
                if (_pickupRequested) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isGettingLocation
                              ? null
                              : () => _checkLocationAndValidateServiceArea(),
                          icon: _isGettingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location),
                          label: Text(
                            _isGettingLocation ? 'Mencari...' : 'Lokasi Saya',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Pilih di Peta'),
                        ),
                      ),
                    ],
                  ),
                  if (_latitude != null && _longitude != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Titik Pickup Terverifikasi (Tanjungpinang)\n'
                              'Lat: ${_latitude!.toStringAsFixed(6)} | '
                              'Lng: ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openMapPicker,
                            child: const Text('Buka Peta'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _alamatPickupController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Pickup di Kota Tanjungpinang',
                      hintText: 'Gunakan GPS atau isi manual...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      if (_pickupRequested &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Alamat pickup wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _jarakController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Estimasi Jarak ke Bengkel (km)',
                      hintText: 'Contoh: 3.5',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.route_outlined),
                    ),
                    validator: (value) {
                      if (_pickupRequested) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Estimasi jarak wajib diisi jika meminta pickup.';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Jarak harus berupa angka lebih dari 0.';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _catatanController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                    hintText: 'Catatan tambahan untuk bengkel...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: bookingProvider.isLoading ? null : _submit,
                    icon: bookingProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      bookingProvider.isLoading
                          ? 'Menyimpan...'
                          : 'Buat Booking',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVehicleDropdown(List<Vehicle> vehicles) {
    return DropdownButtonFormField<int>(
      initialValue: _selectedVehicleId,
      decoration: const InputDecoration(
        labelText: 'Kendaraan',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.two_wheeler_outlined),
      ),
      items: vehicles.map((vehicle) {
        return DropdownMenuItem<int>(
          value: vehicle.id,
          child: Text(
            '${vehicle.nomorPolisi} • '
            '${vehicle.merk} ${vehicle.model}',
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedVehicleId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Kendaraan wajib dipilih.';
        }
        return null;
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
