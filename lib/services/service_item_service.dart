import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/service_item.dart';

class ServiceItemService {
  ServiceItemService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<ServiceItem>> getServiceItems() async {
    final response = await _apiClient.get(ApiConstants.serviceItems);

    final data = response['data'];

    if (data is! List) {
      throw const FormatException(
        'Response service item tidak memiliki format data yang valid.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => ServiceItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ServiceItem> getServiceItem(int id) async {
    final response = await _apiClient.get('${ApiConstants.serviceItems}/$id');

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response detail service item tidak memiliki format data yang valid.',
      );
    }

    return ServiceItem.fromJson(Map<String, dynamic>.from(data));
  }
}
