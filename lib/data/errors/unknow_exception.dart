class UnknowException implements Exception {
  final String message;

  UnknowException(this.message);

  @override
  String toString() => 'UnknowException: message="$message"';
}
