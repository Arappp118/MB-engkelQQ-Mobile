import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/service_area_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
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

  String _selectedService = 'service_rutin';
  bool _pickupRequested = false;

  // Koordinat GPS untuk pickup
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  final List<Map<String, String>> _serviceTypes = const [
    {'value': 'service_rutin', 'label': 'Servis Rutin'},
    {'value': 'perbaikan', 'label': 'Perbaikan'},
    {'value': 'medical_checkup', 'label': 'Medical Checkup'},
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
        backgroundColor: AppColors.surface,
        icon: const Icon(
          Icons.location_off_rounded,
          color: AppColors.warning,
          size: 48,
        ),
        title: const Text(
          ServiceAreaConstants.outOfAreaTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          ServiceAreaConstants.outOfAreaMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
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
        backgroundColor: AppColors.surface,
        icon: Icon(
          state == LocationPermissionState.serviceDisabled
              ? Icons.location_off_outlined
              : Icons.error_outline_rounded,
          color: AppColors.error,
          size: 44,
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          if (state == LocationPermissionState.serviceDisabled) ...[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking berhasil dibuat.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
      return;
    }

    final error = provider.errorMessage ?? 'Gagal membuat booking.';
    _showMessage(error);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Booking Servis'),
        backgroundColor: AppColors.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Consumer2<VehicleProvider, BookingProvider>(
        builder: (context, vehicleProvider, bookingProvider, child) {
          if (vehicleProvider.isLoading && vehicleProvider.vehicles.isEmpty) {
            return const LoadingState(
              height: 350,
              message: 'Memuat data kendaraan...',
            );
          }

          final vehicles = vehicleProvider.vehicles;

          if (vehicles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(
                  icon: Icons.two_wheeler_outlined,
                  title: 'Anda Belum Memiliki Kendaraan',
                  message: 'Tambahkan kendaraan terlebih dahulu sebelum membuat booking servis motor.',
                  actionLabel: 'Refresh Data',
                  onAction: () {
                    context.read<VehicleProvider>().loadVehicles();
                  },
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // STEP 1: Kendaraan & Layanan
                const SectionHeader(
                  title: '1. Kendaraan & Jenis Servis',
                  subtitle: 'Pilih motor dan paket perawatan yang diinginkan',
                ),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildVehicleDropdown(vehicles),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedService,
                        dropdownColor: AppColors.surfaceCardElevated,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Layanan Servis',
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // STEP 2: Jadwal Booking
                const SectionHeader(
                  title: '2. Jadwal Kunjungan',
                  subtitle: 'Tentukan tanggal dan estimasi jam servis',
                ),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Tanggal Booking',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(
                              _selectedDate == null
                                  ? 'Pilih tanggal'
                                  : _formatDate(_selectedDate!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
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
                              prefixIcon: Icon(Icons.access_time_outlined),
                            ),
                            child: Text(
                              _selectedTime == null
                                  ? 'Pilih waktu'
                                  : _selectedTime!.format(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _selectedTime == null
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // STEP 3: Keluhan & Diagnosis
                const SectionHeader(
                  title: '3. Keluhan & Catatan',
                  subtitle: 'Ceritakan kendala yang dirasakan pada motor Anda',
                ),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _keluhanController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Keluhan Kendaraan *',
                          hintText:
                              'Contoh: Rem belakang berbunyi, tarikan berat...',
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
                          prefixIcon: Icon(Icons.search_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan Tambahan (Opsional)',
                          hintText: 'Instruksi khusus untuk mekanik...',
                          prefixIcon: Icon(Icons.notes_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // STEP 4: Layanan Pickup
                const SectionHeader(
                  title: '4. Layanan Pickup (Penjemputan)',
                  subtitle: 'Khusus untuk wilayah jangkauan Kota Tanjungpinang',
                ),
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppColors.primary,
                        title: const Text(
                          'Minta Pickup Kendaraan (Kota Tanjungpinang)',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          _pickupRequested
                              ? 'Kendaraan akan dijemput oleh kurir di wilayah Kota Tanjungpinang.'
                              : 'Saya akan datang sendiri ke bengkel.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
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
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SecondaryButton(
                                text: _isGettingLocation
                                    ? 'Mencari...'
                                    : 'Lokasi Saya (GPS)',
                                icon: Icons.my_location,
                                isLoading: _isGettingLocation,
                                onPressed: _isGettingLocation
                                    ? null
                                    : () =>
                                          _checkLocationAndValidateServiceArea(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PrimaryButton(
                                text: 'Pilih di Peta',
                                icon: Icons.map_outlined,
                                backgroundColor: AppColors.secondary,
                                onPressed: _openMapPicker,
                              ),
                            ),
                          ],
                        ),
                        if (_latitude != null && _longitude != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppColors.secondaryContainer,
                              border: Border.all(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: AppColors.secondary,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Titik Pickup Terverifikasi (Tanjungpinang)\n'
                                    'Lat: ${_latitude!.toStringAsFixed(6)} | '
                                    'Lng: ${_longitude!.toStringAsFixed(6)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: AppColors.textPrimary,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _openMapPicker,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    foregroundColor: AppColors.secondary,
                                  ),
                                  child: const Text('Ubah Peta'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _alamatPickupController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Pickup di Kota Tanjungpinang *',
                            hintText: 'Gunakan GPS atau isi detail alamat...',
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
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _jarakController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Estimasi Jarak ke Bengkel (km) *',
                            hintText: 'Contoh: 3.5',
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
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                PrimaryButton(
                  text: 'Konfirmasi & Buat Booking',
                  icon: Icons.check_circle_outline,
                  height: 52,
                  isLoading: bookingProvider.isLoading,
                  onPressed: bookingProvider.isLoading ? null : _submit,
                ),
                const SizedBox(height: 32),
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
      dropdownColor: AppColors.surfaceCardElevated,
      decoration: const InputDecoration(
        labelText: 'Pilih Kendaraan *',
        prefixIcon: Icon(Icons.two_wheeler_outlined),
      ),
      items: vehicles.map((vehicle) {
        return DropdownMenuItem<int>(
          value: vehicle.id,
          child: Text(
            '${vehicle.nomorPolisi} • ${vehicle.merk} ${vehicle.model}',
            overflow: TextOverflow.ellipsis,
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
