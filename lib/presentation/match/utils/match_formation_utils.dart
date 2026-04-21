/// Formaciones alineadas con [MatchManagerPage] (fútbol 7 vs 11).
abstract final class MatchFormationUtils {
  static const Map<String, List<int>> f7Outfield = {
    '3-2-1': [3, 2, 1],
    '3-3': [3, 3],
    '2-3-1': [2, 3, 1],
    '2-2-2': [2, 2, 2],
  };

  static const Map<String, List<int>> f11Outfield = {
    '4-4-2': [4, 4, 2],
    '4-3-3': [4, 3, 3],
    '4-2-3-1': [4, 2, 3, 1],
    '3-5-2': [3, 5, 2],
    '4-1-4-1': [4, 1, 4, 1],
    '3-4-3': [3, 4, 3],
  };

  static Map<String, List<int>> optionsForSlotCount(int slotCount) {
    return slotCount <= 7 ? f7Outfield : f11Outfield;
  }

  /// Líneas del campo si la clave existe en f7 o f11.
  static List<int>? linesFromKeyOrNull(String? key) {
    if (key == null || key.isEmpty) return null;
    final o7 = f7Outfield[key];
    if (o7 != null) return [1, ...o7];
    final o11 = f11Outfield[key];
    if (o11 != null) return [1, ...o11];
    return null;
  }

  static List<int> defaultLines(int slotCount) {
    if (slotCount <= 0) return [];
    if (slotCount == 7) return [1, 3, 2, 1];
    if (slotCount == 11) return [1, 4, 4, 2];
    return [1, slotCount - 1];
  }

  /// Huecos totales según la clave guardada (p. ej. `4-4-2` → 11).
  static int? slotCountForKey(String? key) {
    if (key == null) return null;
    final o7 = f7Outfield[key];
    if (o7 != null) return 1 + o7.fold<int>(0, (a, b) => a + b);
    final o11 = f11Outfield[key];
    if (o11 != null) return 1 + o11.fold<int>(0, (a, b) => a + b);
    return null;
  }
}
