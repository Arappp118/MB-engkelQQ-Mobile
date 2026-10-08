import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/notification.dart';

class NotificationService {
  NotificationService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _apiClient.get(ApiConstants.notifications);

    var data = response['data'];
    if (data is Map && data['data'] is List) {
      data = data['data'];
    }

    if (data is! List) {
      throw const FormatException(
        'Response notification tidak memiliki format data yang valid.',
      );
    }

    return data
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<AppNotification>> getUnreadNotifications() async {
    final response = await _apiClient.get(ApiConstants.unreadNotifications);

    var data = response['data'];
    if (data is Map && data['data'] is List) {
      data = data['data'];
    }

    if (data is! List) {
      throw const FormatException(
        'Response unread notification tidak memiliki format data yang valid.',
      );
    }

    return data
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<AppNotification> markAsRead(int id) async {
    final response = await _apiClient.post(
      '${ApiConstants.notifications}/$id/read',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response mark notification as read tidak memiliki format data yang valid.',
      );
    }

    return AppNotification.fromJson(Map<String, dynamic>.from(data));
  }
}
