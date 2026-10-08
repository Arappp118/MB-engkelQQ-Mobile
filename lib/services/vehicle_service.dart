import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/vehicle.dart';

class VehicleService {
  VehicleService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Vehicle>> getVehicles() async {
    final response = await _apiClient.get(ApiConstants.vehicles);

    final data = response['data'];

    if (data is! List) {
      throw const FormatException(
        'Response kendaraan tidak memiliki format data yang valid.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => Vehicle.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Vehicle> getVehicle(int id) async {
    final response = await _apiClient.get('${ApiConstants.vehicles}/$id');

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response detail kendaraan tidak memiliki format data yang valid.',
      );
    }

    return Vehicle.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Vehicle> createVehicle({
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
    final response = await _apiClient.post(
      ApiConstants.vehicles,
      body: {
        'nomor_polisi': nomorPolisi,
        'merk': merk,
        'model': model,
        'tahun': tahun,
        'tipe_mesin': tipeMesin,
        'transmisi': transmisi,
        'warna': warna,
        'nomor_rangka': nomorRangka,
        'catatan': catatan,
      },
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response kendaraan baru tidak memiliki format data yang valid.',
      );
    }

    return Vehicle.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Vehicle> updateVehicle({
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
    final response = await _apiClient.put(
      '${ApiConstants.vehicles}/$id',
      body: {
        'nomor_polisi': nomorPolisi,
        'merk': merk,
        'model': model,
        'tahun': tahun,
        'tipe_mesin': tipeMesin,
        'transmisi': transmisi,
        'warna': warna,
        'nomor_rangka': nomorRangka,
        'catatan': catatan,
      },
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response perubahan kendaraan tidak memiliki format data yang valid.',
      );
    }

    return Vehicle.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteVehicle(int id) async {
    await _apiClient.delete('${ApiConstants.vehicles}/$id');
  }
}
