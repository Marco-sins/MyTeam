// Utilidades puras para valores en mapas JSON (sin dependencias de capas externas).

/// Respuesta de consultas HTTP/PostgREST: a veces es `null`.
List<dynamic> jsonResponseAsList(dynamic response) {
  if (response == null) return const [];
  if (response is List) return response;
  return const [];
}

/// Convierte enteros que a veces llegan como [num], [String] u otro tipo.
int? jsonOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return int.tryParse(value.toString().trim());
}

/// Alias (PostgREST / mapas de evento): mismos casos que [jsonOptionalInt].
int? supabaseInt(dynamic value) => jsonOptionalInt(value);

/// Minuto del evento: corrige [num] en JSON y, en cambios, lee `min:` en [note].
int resolveMatchEventMinute(Map<String, dynamic> row) {
  final parsed = jsonOptionalInt(row['minute']);
  if (parsed != null && parsed > 0) return parsed;

  final typeTail = row['type']?.toString().split('.').last ?? '';
  final key = typeTail.toLowerCase().replaceAll('_', '');
  if (key != 'substitution') return parsed ?? 0;

  final note = row['note']?.toString() ?? '';
  final match = RegExp(r'min:(\d+)', caseSensitive: false).firstMatch(note);
  if (match != null) {
    final n = int.tryParse(match.group(1)!);
    if (n != null) return n;
  }
  return parsed ?? 0;
}

/// Normaliza el campo `type` de eventos (camelCase, snake_case, guiones, etc.).
String canonicalMatchEventTypeKey(dynamic rawType) {
  if (rawType == null) return '';
  var k = rawType.toString().split('.').last.toLowerCase().trim();
  k = k
      .replaceAll('_', '')
      .replaceAll(' ', '')
      .replaceAll('-', '')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');

  const aliases = <String, String>{
    'buenpase': 'goodpass',
    'malpase': 'badpass',
    'buenajugada': 'goodplay',
    'malajugada': 'badplay',
    'recuperacion': 'ballrecovery',
    'paseclave': 'keypass',
    'tarjetaamarilla': 'yellowcard',
    'tarjetaroja': 'redcard',
    'golenpropia': 'owngoal',
    'golencajado': 'concedegoal',
    'golrival': 'concedegoal',
    'tiro': 'shot',
    'tirorival': 'rivalshot',
    'falta': 'foul',
    'corner': 'corner',
    'cornerrival': 'rivalcorner',
    'faltarival': 'rivalfoul',
    'sustitucion': 'substitution',
  };

  return aliases[k] ?? k;
}
