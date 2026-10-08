import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/service_order.dart';

class ServiceOrderService {
  ServiceOrderService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ServiceOrder>> getServiceOrders() async {
    final response = await _apiClient.get(ApiConstants.serviceOrders);

    final data = response['data'];

    if (data is! List) {
      throw const FormatException(
        'Response service order tidak memiliki format data yang valid.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => ServiceOrder.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ServiceOrder> getServiceOrder(int id) async {
    final response = await _apiClient.get('${ApiConstants.serviceOrders}/$id');

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response detail service order tidak memiliki format data yang valid.',
      );
    }

    return ServiceOrder.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ServiceOrder> startServiceOrder(int id) async {
    final response = await _apiClient.post(
      '${ApiConstants.serviceOrders}/$id/start',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response start service order tidak memiliki format data yang valid.',
      );
    }

    return ServiceOrder.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ServiceOrder> submitDiagnosis({
    required int id,
    required String diagnosis,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.serviceOrders}/$id/diagnosis',
      body: {
        // Laravel meminta field diagnosis_mechanic
        'diagnosis_mechanic': diagnosis,
      },
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response diagnosis tidak memiliki format data yang valid.',
      );
    }

    return ServiceOrder.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ServiceOrder> completeServiceOrder(int id) async {
    final response = await _apiClient.post(
      '${ApiConstants.serviceOrders}/$id/complete',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response complete service order tidak memiliki format data yang valid.',
      );
    }

    return ServiceOrder.fromJson(Map<String, dynamic>.from(data));
  }
}
