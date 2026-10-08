class AppNotification {
  const AppNotification({
    required this.id,
    this.title,
    this.message,
    this.type,
    this.entityType,
    this.entityId,
    this.readAt,
    this.createdAt,
    this.isRead,
  });

  final int id;
  final String? title;
  final String? message;
  final String? type;
  final String? entityType;
  final int? entityId;
  final String? readAt;
  final String? createdAt;
  final bool? isRead;

  bool get isReadStatus {
    if (readAt != null && readAt!.isNotEmpty) {
      return true;
    }
    if (isRead != null) {
      return isRead!;
    }
    return false;
  }

  AppNotification copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    String? entityType,
    int? entityId,
    String? readAt,
    String? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final readAtStr = json['read_at']?.toString();
    final explicitIsRead = _toBool(json['is_read']);
    final computedIsRead =
        (readAtStr != null && readAtStr.isNotEmpty) || (explicitIsRead == true);

    return AppNotification(
      id: _toInt(json['id']) ?? 0,
      title: json['title']?.toString(),
      message: json['message']?.toString(),
      type: json['type']?.toString(),
      entityType: json['entity_type']?.toString(),
      entityId: _toInt(json['entity_id']),
      readAt: readAtStr,
      createdAt: json['created_at']?.toString(),
      isRead: computedIsRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'entity_type': entityType,
      'entity_id': entityId,
      'read_at': readAt,
      'created_at': createdAt,
      'is_read': isReadStatus,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value != 0;
    }

    if (value is String) {
      if (value == '1' || value.toLowerCase() == 'true') {
        return true;
      }

      if (value == '0' || value.toLowerCase() == 'false') {
        return false;
      }
    }

    return null;
  }
}
