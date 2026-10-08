import 'package:flutter/foundation.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class VehicleProvider extends ChangeNotifier {
  VehicleProvider({VehicleService? vehicleService})
    : _vehicleService = vehicleService ?? VehicleService();

  final VehicleService _vehicleService;

  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;

  bool _isLoading = false;
  String? _errorMessage;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  Vehicle? get selectedVehicle => _selectedVehicle;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loadVehicles() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _vehicles = await _vehicleService.getVehicles();
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadVehicle(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedVehicle = await _vehicleService.getVehicle(id);
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createVehicle({
    required String nomorPolisi,
    required String merk,
    required String model,
    required int tahun,
    String? tipeMesin,
    String? transmisi,
    String? warna,
    String? nomorRangka,
    String? catatan,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final vehicle = await _vehicleService.createVehicle(
        nomorPolisi: nomorPolisi,
        merk: merk,
        model: model,
        tahun: tahun,
        tipeMesin: tipeMesin,
        transmisi: transmisi,
        warna: warna,
        nomorRangka: nomorRangka,
        catatan: catatan,
      );

      _vehicles = [..._vehicles, vehicle];

      _selectedVehicle = vehicle;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateVehicle({
    required int id,
    required String nomorPolisi,
    required String merk,
    required String model,
    required int tahun,
    String? tipeMesin,
    String? transmisi,
    String? warna,
    String? nomorRangka,
    String? catatan,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final vehicle = await _vehicleService.updateVehicle(
        id: id,
        nomorPolisi: nomorPolisi,
        merk: merk,
        model: model,
        tahun: tahun,
        tipeMesin: tipeMesin,
        transmisi: transmisi,
        warna: warna,
        nomorRangka: nomorRangka,
        catatan: catatan,
      );

      _vehicles = _vehicles
          .map((item) => item.id == id ? vehicle : item)
          .toList();

      _selectedVehicle = vehicle;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteVehicle(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _vehicleService.deleteVehicle(id);

      _vehicles = _vehicles.where((vehicle) => vehicle.id != id).toList();

      if (_selectedVehicle?.id == id) {
        _selectedVehicle = null;
      }

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectVehicle(Vehicle? vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearVehicles() {
    _vehicles = [];
    _selectedVehicle = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    return error.toString().replaceFirst('ApiException(null): ', '');
  }
}
