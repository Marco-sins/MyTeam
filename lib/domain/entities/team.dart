/// Entidad `Team` que contiene nombre, categoría, logo y color (hex).
///
/// Usada en vistas y lógica que necesita metadatos del equipo.
class Team {
  final int id;
  final String name;
  final String category;
  final String? logoUrl;

  /// Hex guardado en Supabase (`teams.color`), p. ej. `#14532D`. Vacío → acento por defecto.
  final String? color;

  const Team({
    this.id = 0,
    required this.name,
    required this.category,
    this.logoUrl,
    this.color,
  });
}
