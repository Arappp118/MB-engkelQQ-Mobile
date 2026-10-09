import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/service_area_constants.dart';
import '../../core/constants/workshop_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/location_service.dart';

enum MapPageMode {
  picker, // Customer memilih lokasi pickup
  viewer, // Courier atau Customer melihat lokasi tujuan & navigasi
}

class MapPickerResult {
  const MapPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.distanceKm,
    this.isInsideServiceArea = true,
  });

  final double latitude;
  final double longitude;
  final String address;
  final double distanceKm;
  final bool isInsideServiceArea;
}

class InteractiveMapPage extends StatefulWidget {
  const InteractiveMapPage({
    super.key,
    this.mode = MapPageMode.viewer,
    this.initialLatitude,
    this.initialLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.destinationTitle,
    this.destinationAddress,
  });

  final MapPageMode mode;
  final double? initialLatitude;
  final double? initialLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final String? destinationTitle;
  final String? destinationAddress;

  @override
  State<InteractiveMapPage> createState() => _InteractiveMapPageState();
}

class _InteractiveMapPageState extends State<InteractiveMapPage> {
  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;

  bool _isLoading = true;
  String? _errorMessage;
  String? _errorTitle;
  LocationPermissionState? _errorState;

  // Koordinat lokasi pengguna saat ini (GPS aktual device)
  double? _currentLat;
  double? _currentLng;

  // Koordinat titik yang dipilih (untuk picker mode)
  double? _selectedLat;
  double? _selectedLng;
  String _selectedAddress = '';
  bool _isGeocoding = false;
  bool _isInsideServiceArea = true;

  // Jarak ke workshop / destination
  double? _calculatedDistanceKm;

  // Marker & Polygon set
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  @override
  void initState() {
    super.initState();
    _initPolygons();
    _initLocation();
  }

  void _initPolygons() {
    // Polygon batas administratif Kota Tanjungpinang
    _polygons.add(
      Polygon(
        polygonId: const PolygonId('tanjungpinang_administrative_area'),
        points: ServiceAreaConstants.administrativePolygon
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList(),
        strokeColor: Colors.blue.shade800,
        strokeWidth: 2,
        fillColor: Colors.blue.withValues(alpha: 0.10),
      ),
    );
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorTitle = null;
      _errorState = null;
    });

    try {
      // 1. Cek izin dan ambil GPS terkini perangkat secara aktual
      final position = await _locationService.getCurrentPosition();
      final currentLat = position.latitude;
      final currentLng = position.longitude;

      _currentLat = currentLat;
      _currentLng = currentLng;

      // 2. Setup koordinat awal picker atau viewer
      if (widget.mode == MapPageMode.picker) {
        // Jika ada initial coordinate yang dioper: gunakan
        if (widget.initialLatitude != null && widget.initialLongitude != null) {
          _selectedLat = widget.initialLatitude;
          _selectedLng = widget.initialLongitude;
        } else {
          // Jika GPS device berada di dalam Tanjungpinang, gunakan GPS device
          final isCurrentInArea = ServiceAreaConstants.isWithinServiceArea(
            currentLat,
            currentLng,
          );
          if (isCurrentInArea) {
            _selectedLat = currentLat;
            _selectedLng = currentLng;
          } else {
            // Jika device di luar Tanjungpinang (misal emulator), default fokus ke workshop
            _selectedLat = WorkshopConstants.workshopLatitude;
            _selectedLng = WorkshopConstants.workshopLongitude;
          }
        }
        await _updateDistanceAndAddress(_selectedLat!, _selectedLng!);
      } else {
        // Viewer mode: Jarak dari current location ke destination
        final destLat =
            widget.destinationLatitude ?? WorkshopConstants.workshopLatitude;
        final destLng =
            widget.destinationLongitude ?? WorkshopConstants.workshopLongitude;
        _calculatedDistanceKm = _locationService.calculateDistanceKm(
          currentLat,
          currentLng,
          destLat,
          destLng,
        );
      }

      _rebuildMarkers();

      setState(() {
        _isLoading = false;
      });

      _animateToPosition(
        _selectedLat ?? _currentLat!,
        _selectedLng ?? _currentLng!,
      );
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorTitle = e.title;
        _errorMessage = e.message;
        _errorState = e.state;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorTitle = 'Lokasi Tidak Tersedia';
        _errorMessage =
            'Lokasi Anda belum dapat ditentukan. Silakan coba lagi.';
      });
    }
  }

  Future<void> _updateDistanceAndAddress(double lat, double lng) async {
    setState(() {
      _isGeocoding = true;
    });

    final isInside = ServiceAreaConstants.isWithinServiceArea(lat, lng);
    final addr = await _locationService.getAddressFromCoordinates(lat, lng);

    // Hitung jarak ke workshop jika di dalam wilayah layanan
    double? dist;
    if (isInside) {
      dist = _locationService.calculateDistanceToWorkshop(lat, lng);
    }

    if (!mounted) return;
    setState(() {
      _isInsideServiceArea = isInside;
      _calculatedDistanceKm = dist;
      _selectedAddress =
          addr ??
          (isInside
              ? 'Kota Tanjungpinang (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})'
              : 'Di luar wilayah layanan Kota Tanjungpinang');
      _isGeocoding = false;
    });

    _rebuildMarkers();
  }

  void _rebuildMarkers() {
    _markers.clear();

    // 1. Marker Workshop MB-engkelQQ di Kota Tanjungpinang (Selalu ditampilkan)
    _markers.add(
      Marker(
        markerId: const MarkerId('workshop'),
        position: const LatLng(
          WorkshopConstants.workshopLatitude,
          WorkshopConstants.workshopLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(
          title: WorkshopConstants.workshopName,
          snippet: WorkshopConstants.workshopAddress,
        ),
      ),
    );

    // 2. Marker Current Location (GPS aktual device)
    if (_currentLat != null && _currentLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentLat!, _currentLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(
            title: 'Lokasi Anda Saat Ini',
            snippet: 'Posisi GPS perangkat',
          ),
        ),
      );
    }

    // 3. Mode Picker: Marker titik pickup yang dipilih
    if (widget.mode == MapPageMode.picker &&
        _selectedLat != null &&
        _selectedLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: LatLng(_selectedLat!, _selectedLng!),
          draggable: true,
          onDragEnd: (newPos) {
            _onMapTapped(newPos);
          },
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _isInsideServiceArea
                ? BitmapDescriptor.hueRed
                : BitmapDescriptor.hueRose,
          ),
          infoWindow: InfoWindow(
            title: _isInsideServiceArea
                ? 'Titik Pickup Dipilih'
                : 'Di Luar Wilayah Layanan',
            snippet: _selectedAddress.isNotEmpty ? _selectedAddress : null,
          ),
        ),
      );
    }

    // 4. Mode Viewer: Marker Destinasi / Tujuan Tugas
    if (widget.mode == MapPageMode.viewer &&
        widget.destinationLatitude != null &&
        widget.destinationLongitude != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(
            widget.destinationLatitude!,
            widget.destinationLongitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: widget.destinationTitle ?? 'Lokasi Tujuan',
            snippet: widget.destinationAddress ?? 'Alamat Tujuan',
          ),
        ),
      );
    }
  }

  void _onMapTapped(LatLng position) {
    if (widget.mode != MapPageMode.picker) return;

    setState(() {
      _selectedLat = position.latitude;
      _selectedLng = position.longitude;
    });

    _updateDistanceAndAddress(position.latitude, position.longitude);
  }

  void _animateToPosition(double lat, double lng, {double zoom = 14.5}) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: zoom),
        ),
      );
    }
  }

  void _recenterToCurrent() {
    if (_currentLat != null && _currentLng != null) {
      _animateToPosition(_currentLat!, _currentLng!);
    } else {
      _initLocation();
    }
  }

  void _recenterToWorkshop() {
    _animateToPosition(
      WorkshopConstants.workshopLatitude,
      WorkshopConstants.workshopLongitude,
      zoom: 15.5,
    );
  }

  void _recenterToDestination() {
    if (widget.destinationLatitude != null &&
        widget.destinationLongitude != null) {
      _animateToPosition(
        widget.destinationLatitude!,
        widget.destinationLongitude!,
      );
    }
  }

  Future<void> _launchNavigationToDestination() async {
    final destLat =
        widget.destinationLatitude ?? WorkshopConstants.workshopLatitude;
    final destLng =
        widget.destinationLongitude ?? WorkshopConstants.workshopLongitude;

    final launched = await _locationService.launchNavigation(
      destLat,
      destLng,
      destinationTitle:
          widget.destinationTitle ?? WorkshopConstants.workshopName,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka aplikasi navigasi/peta.'),
        ),
      );
    }
  }

  void _showOutOfAreaDialog() {
    showDialog<void>(
      context: context,
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
              _recenterToWorkshop();
            },
            child: const Text('Ke Bengkel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPicker = widget.mode == MapPageMode.picker;

    return Scaffold(
      appBar: AppBar(
        title: Text(isPicker ? 'Pilih Lokasi Pickup' : 'Peta & Navigasi'),
        actions: [
          IconButton(
            tooltip: 'Refresh Lokasi GPS',
            icon: const Icon(Icons.refresh),
            onPressed: _initLocation,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mengakses GPS & memuat peta Tanjungpinang...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _errorState == LocationPermissionState.serviceDisabled
                      ? Icons.location_off_outlined
                      : Icons.security_outlined,
                  size: 56,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorTitle ?? 'Pemberitahuan Lokasi',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _initLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                    const SizedBox(width: 12),
                    if (_errorState == LocationPermissionState.serviceDisabled)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () =>
                            _locationService.openLocationSettings(),
                        icon: const Icon(Icons.settings),
                        label: const Text('Buka GPS'),
                      ),
                    if (_errorState == LocationPermissionState.deniedForever)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: () => _locationService.openAppSettings(),
                        icon: const Icon(Icons.app_settings_alt),
                        label: const Text('Buka Pengaturan'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Default target: koordinat terpilih atau workshop Tanjungpinang
    final initialTarget = LatLng(
      _selectedLat ?? WorkshopConstants.workshopLatitude,
      _selectedLng ?? WorkshopConstants.workshopLongitude,
    );

    return Stack(
      children: [
        // 1. Google Map View dengan Polygon Wilayah Layanan Tanjungpinang
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: 14,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: _onMapTapped,
          markers: _markers,
          polygons: _polygons,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
        ),

        // 2. Floating action quick buttons (Recenter)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'recenter_current',
                tooltip: 'Lokasi Saya (GPS)',
                backgroundColor: AppColors.surfaceCardElevated,
                foregroundColor: AppColors.secondary,
                onPressed: _recenterToCurrent,
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'recenter_workshop',
                tooltip: 'Bengkel MB-engkelQQ Tanjungpinang',
                backgroundColor: AppColors.surfaceCardElevated,
                foregroundColor: AppColors.primary,
                onPressed: _recenterToWorkshop,
                child: const Icon(Icons.build_circle_outlined),
              ),
              if (widget.mode == MapPageMode.viewer &&
                  widget.destinationLatitude != null) ...[
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'recenter_dest',
                  tooltip: 'Lokasi Tujuan',
                  backgroundColor: AppColors.surfaceCardElevated,
                  foregroundColor: AppColors.success,
                  onPressed: _recenterToDestination,
                  child: const Icon(Icons.flag_outlined),
                ),
              ],
            ],
          ),
        ),

        // 3. Bottom Information & Action Card
        Positioned(left: 16, right: 16, bottom: 16, child: _buildBottomPanel()),
      ],
    );
  }

  Widget _buildBottomPanel() {
    final isPicker = widget.mode == MapPageMode.picker;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status baris atas: Jarak / Wilayah Layanan
          Row(
            children: [
              Icon(
                _isInsideServiceArea ? Icons.route : Icons.warning_amber,
                color: _isInsideServiceArea
                    ? AppColors.secondary
                    : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPicker
                      ? (_isInsideServiceArea
                            ? 'Jarak ke Bengkel: ${_calculatedDistanceKm != null ? '${_calculatedDistanceKm!.toStringAsFixed(1)} km' : 'Menghitung...'}'
                            : 'Di Luar Wilayah Layanan')
                      : 'Jarak Tujuan: ${_calculatedDistanceKm != null ? '${_calculatedDistanceKm!.toStringAsFixed(1)} km' : '-'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _isInsideServiceArea
                        ? AppColors.textPrimary
                        : AppColors.error,
                  ),
                ),
              ),
              if (_isGeocoding)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(color: AppColors.borderSubtle, height: 16),

          // Alamat & Koordinat
          if (isPicker) ...[
            if (!_isInsideServiceArea) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Layanan penjemputan khusus Kota Tanjungpinang.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Alamat Pickup Terpilih:',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _selectedAddress.isNotEmpty
                  ? _selectedAddress
                  : 'Ketuk pada peta untuk menentukan titik pickup.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            if (_selectedLat != null && _selectedLng != null) ...[
              const SizedBox(height: 3),
              Text(
                'Lat: ${_selectedLat!.toStringAsFixed(5)}, Lng: ${_selectedLng!.toStringAsFixed(5)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _selectedLat == null
                  ? null
                  : () {
                      if (!_isInsideServiceArea) {
                        _showOutOfAreaDialog();
                        return;
                      }

                      final result = MapPickerResult(
                        latitude: _selectedLat!,
                        longitude: _selectedLng!,
                        address: _selectedAddress,
                        distanceKm: _calculatedDistanceKm ?? 0.0,
                        isInsideServiceArea: true,
                      );
                      Navigator.of(context).pop(result);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: _isInsideServiceArea
                    ? AppColors.primary
                    : AppColors.textDisabled,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(
                _isInsideServiceArea
                    ? 'Gunakan Lokasi Ini'
                    : 'Lokasi di Luar Jangkauan',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ] else ...[
            Text(
              widget.destinationTitle ?? 'Lokasi Tujuan',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.destinationAddress ??
                  'Koordinat: ${widget.destinationLatitude?.toStringAsFixed(5) ?? '-'}, ${widget.destinationLongitude?.toStringAsFixed(5) ?? '-'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _launchNavigationToDestination,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.navigation_outlined, size: 18),
              label: const Text(
                'Buka Navigasi (Google Maps)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
