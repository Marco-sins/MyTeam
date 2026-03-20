class NetworkException implements Exception {
  final String message;
  final String? code;

  NetworkException(this.message, {this.code});

  @override
  String toString() => 'NetworkException: message="$message", code="$code"';
}
