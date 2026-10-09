class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({required this.message, this.statusCode, this.errors});

  static String extractMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    final str = error.toString();
    final clean = str
        .replaceFirst(RegExp(r'^ApiException(\([0-9]*\))?:\s*'), '')
        .replaceFirst(RegExp(r'^Exception:\s*'), '');
    return clean.isEmpty ? 'Terjadi kesalahan sistem.' : clean;
  }

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}
