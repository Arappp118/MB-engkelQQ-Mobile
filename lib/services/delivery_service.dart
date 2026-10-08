import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/delivery_task.dart';

class DeliveryService {
  DeliveryService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<DeliveryTask>> getDeliveryTasks() async {
    final response = await _apiClient.get(ApiConstants.deliveryTasks);

    final data = response['data'];

    if (data is! List) {
      throw const FormatException(
        'Response delivery task tidak memiliki format data yang valid.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => DeliveryTask.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<DeliveryTask> getDeliveryTask(int id) async {
    final response = await _apiClient.get('${ApiConstants.deliveryTasks}/$id');

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response detail delivery task tidak memiliki format data yang valid.',
      );
    }

    return DeliveryTask.fromJson(Map<String, dynamic>.from(data));
  }

  Future<DeliveryTask> assignDeliveryTask({
    required int id,
    required int courierId,
  }) async {
    final response = await _apiClient.post(
      '${ApiConstants.deliveryTasks}/$id/assign',
      body: {'courier_id': courierId},
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response assignment delivery task tidak memiliki format data yang valid.',
      );
    }

    return DeliveryTask.fromJson(Map<String, dynamic>.from(data));
  }

  Future<DeliveryTask> startDeliveryTask(int id) async {
    final response = await _apiClient.post(
      '${ApiConstants.deliveryTasks}/$id/start',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response start delivery task tidak memiliki format data yang valid.',
      );
    }

    return DeliveryTask.fromJson(Map<String, dynamic>.from(data));
  }

  Future<DeliveryTask> completeDeliveryTask(int id) async {
    final response = await _apiClient.post(
      '${ApiConstants.deliveryTasks}/$id/complete',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response complete delivery task tidak memiliki format data yang valid.',
      );
    }

    return DeliveryTask.fromJson(Map<String, dynamic>.from(data));
  }
}
