class AuthServerException implements Exception {
  final String message;
  final String? code;

  AuthServerException(this.message, {this.code});

  @override
  String toString() => 'AuthServerException: message="$message", code="$code"';
}
