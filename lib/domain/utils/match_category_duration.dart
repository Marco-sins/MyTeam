/// Duración reglamentaria de **cada mitad** (minutos) según la categoría del equipo.
int matchHalfDurationMinutesForCategory(String category) {
  final cat = category.toLowerCase();

  if (cat.contains('prebenjamin') || cat.contains('prebenjamín')) {
    return 25;
  }
  if (cat.contains('benjamin') || cat.contains('benjamín')) {
    return 30;
  }
  if (cat.contains('alevin') || cat.contains('alevín')) {
    return 35;
  }
  if (cat.contains('infantil')) {
    return 40;
  }
  if (cat.contains('cadete') ||
      cat.contains('juvenil') ||
      cat.contains('senior')) {
    return 45;
  }
  return 35;
}
