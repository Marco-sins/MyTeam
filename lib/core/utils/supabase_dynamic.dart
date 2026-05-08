/// Utilidades para valores que vienen de PostgREST / JSON en Supabase.
///
/// Este archivo publica funciones de ayuda para transformar y normalizar
/// los valores que vienen de la base de datos (vía Supabase/PostgREST). Entre
/// ellas:
/// - `supabaseResponseAsList`: protege contra responses `null` o no-list.
/// - `supabaseInt`: convierte a `int` desde `num`/`String`.
/// - `resolveMatchEventMinute`: heurística para extraer el minuto del evento.
/// - `canonicalMatchEventTypeKey`: normaliza variantes de tipo de evento
///   (camels, snake_case, textos en español) a una clave canónica.
///
/// Usar estas utilidades siempre que se parseen filas devueltas por la API
/// para mantener comportamiento consistente en todo el código.
library;

/// Respuesta de `.select()` / `.insert()` / etc.: a veces es `null` en el cliente;
/// nunca usar [Iterable.isEmpty] directamente sobre el valor crudo.
List<dynamic> supabaseResponseAsList(dynamic response) {
  if (response == null) return const [];
  if (response is List) return response;
  return const [];
}

/// Convierte enteros que a veces llegan como [num], [String] u otro tipo.
int? supabaseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return int.tryParse(value.toString().trim());
}

/// Minuto del evento: corrige [num] en JSON y, en cambios, lee `min:` en [note].
int resolveMatchEventMinute(Map<String, dynamic> row) {
  final parsed = supabaseInt(row['minute']);
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

/// Normaliza el campo `type` de [match_events] (camelCase, snake_case, guiones,
/// mayúsculas, etiquetas en español en enums de Postgres).
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
    'fueradejuego': 'offside',
    'fueradejuegorival': 'rivaloffside',
    'tarjetaamarillarival': 'rivalyellowcard',
    'tarjetarojarival': 'rivalredcard',
  };

  return aliases[k] ?? k;
}
