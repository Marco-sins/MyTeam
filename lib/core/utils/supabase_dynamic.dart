// Utilidades para valores que vienen de PostgREST / JSON en Supabase.

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
