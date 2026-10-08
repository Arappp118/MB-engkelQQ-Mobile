import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/dashboard.dart';

class DashboardService {
  DashboardService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<Dashboard> getDashboard() async {
    final response = await _apiClient.get(ApiConstants.dashboard);

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response dashboard tidak memiliki format data yang valid.',
      );
    }

    return Dashboard.fromJson(Map<String, dynamic>.from(data));
  }
}
