class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({required this.message, this.statusCode, this.errors});

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}
