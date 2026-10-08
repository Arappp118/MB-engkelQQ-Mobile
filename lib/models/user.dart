class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.specialization,
    this.phone,
    this.address,
    this.avatar,
    this.isActive,
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final String? specialization;
  final String? phone;
  final String? address;
  final String? avatar;
  final bool? isActive;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _toInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      specialization: json['specialization']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      avatar: json['avatar']?.toString(),
      isActive: _toBool(json['is_active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'specialization': specialization,
      'phone': phone,
      'address': address,
      'avatar': avatar,
      'is_active': isActive,
    };
  }

  static int? _toInt(dynamic value) {
    if (value is int) {
      return value;
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
