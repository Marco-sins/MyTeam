import 'dart:ui' show Offset;

/// Formaciones alineadas con [MatchManagerPage] (fútbol 7 vs 11).
abstract final class MatchFormationUtils {
  /// F11: filas horizontales (misma Y por línea), X muy separados — como el diagrama táctico.
  static const Map<String, List<Offset>> f11NormalizedSlotCenters = {
    // [1,4,4,2]: filas 1 | 2-3-4-5 | 7-6-8-10 | 9-11
    '4-4-2': [
      Offset(0.50, 0.92),
      Offset(0.07, 0.71),
      Offset(0.35, 0.71),
      Offset(0.65, 0.71),
      Offset(0.93, 0.71),
      Offset(0.07, 0.44),
      Offset(0.35, 0.44),
      Offset(0.65, 0.44),
      Offset(0.93, 0.44),
      Offset(0.20, 0.09),
      Offset(0.80, 0.09),
    ],
    // [1,4,3,3]: def 2-3-4-5 | 10-6-8 | 7-9-11
    '4-3-3': [
      Offset(0.50, 0.92),
      Offset(0.07, 0.71),
      Offset(0.35, 0.71),
      Offset(0.65, 0.71),
      Offset(0.93, 0.71),
      Offset(0.09, 0.44),
      Offset(0.50, 0.44),
      Offset(0.91, 0.44),
      Offset(0.07, 0.09),
      Offset(0.50, 0.09),
      Offset(0.93, 0.09),
    ],
    // [1,4,2,3,1]
    '4-2-3-1': [
      Offset(0.50, 0.92),
      Offset(0.07, 0.77),
      Offset(0.35, 0.77),
      Offset(0.65, 0.77),
      Offset(0.93, 0.77),
      Offset(0.28, 0.61),
      Offset(0.72, 0.61),
      Offset(0.09, 0.40),
      Offset(0.50, 0.40),
      Offset(0.91, 0.40),
      Offset(0.50, 0.08),
    ],
    // [1,3,5,2]: def 2-4-3 | línea de 5 | 9-11
    '3-5-2': [
      Offset(0.50, 0.92),
      Offset(0.10, 0.71),
      Offset(0.50, 0.71),
      Offset(0.90, 0.71),
      Offset(0.05, 0.44),
      Offset(0.26, 0.44),
      Offset(0.50, 0.44),
      Offset(0.74, 0.44),
      Offset(0.95, 0.44),
      Offset(0.20, 0.09),
      Offset(0.80, 0.09),
    ],
    // [1,4,1,4,1]
    '4-1-4-1': [
      Offset(0.50, 0.92),
      Offset(0.07, 0.76),
      Offset(0.35, 0.76),
      Offset(0.65, 0.76),
      Offset(0.93, 0.76),
      Offset(0.50, 0.60),
      Offset(0.07, 0.37),
      Offset(0.35, 0.37),
      Offset(0.65, 0.37),
      Offset(0.93, 0.37),
      Offset(0.50, 0.08),
    ],
    // [1,3,4,3]: def 2-4-3 | 7-6-5-8 | 11-9-10
    '3-4-3': [
      Offset(0.50, 0.92),
      Offset(0.10, 0.71),
      Offset(0.50, 0.71),
      Offset(0.90, 0.71),
      Offset(0.07, 0.44),
      Offset(0.35, 0.44),
      Offset(0.65, 0.44),
      Offset(0.93, 0.44),
      Offset(0.09, 0.09),
      Offset(0.50, 0.09),
      Offset(0.91, 0.09),
    ],
  };

  /// Centro de cada hueco en coordenadas normalizadas respecto al rectángulo
  /// del campo: [0,1] en X (izquierda→derecha) e Y (**arriba** = ataque rival,
  /// **abajo** ≈ 1 = portería propia). Orden = mismo recorrido que el widget
  /// (portero + filas de izquierda a derecha).
  ///
  /// Cada línea = **misma Y** (fila horizontal); X repartidos en el ancho. y=0 arriba, y=1 portería.
  static const Map<String, List<Offset>> f7NormalizedSlotCenters = {
    // [1,3,2,1]: filas 1 | 2-3-4 | 6-5 | 7
    '3-2-1': [
      Offset(0.50, 0.93),
      Offset(0.14, 0.73),
      Offset(0.50, 0.73),
      Offset(0.86, 0.73),
      Offset(0.27, 0.44),
      Offset(0.73, 0.44),
      Offset(0.50, 0.09),
    ],
    // [1,2,3,1]: filas 1 | 3-4 | 2-6-5 | 7
    '2-3-1': [
      Offset(0.50, 0.93),
      Offset(0.29, 0.78),
      Offset(0.71, 0.78),
      Offset(0.12, 0.44),
      Offset(0.50, 0.44),
      Offset(0.88, 0.44),
      Offset(0.50, 0.08),
    ],
    // [1,2,2,2]: filas 1 | 3-4 | 2-5 | 6-7 (dos columnas)
    '2-2-2': [
      Offset(0.50, 0.93),
      Offset(0.22, 0.75),
      Offset(0.78, 0.75),
      Offset(0.22, 0.44),
      Offset(0.78, 0.44),
      Offset(0.22, 0.12),
      Offset(0.78, 0.12),
    ],
    // [1,3,3]: filas 1 | 2-3-4 | 6-7-5
    '3-3': [
      Offset(0.50, 0.93),
      Offset(0.12, 0.72),
      Offset(0.50, 0.72),
      Offset(0.88, 0.72),
      Offset(0.12, 0.14),
      Offset(0.50, 0.14),
      Offset(0.88, 0.14),
    ],
  };

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

  /// Huecos [0,1]×[0,1] para F7 si [key] está definida; si no, null (rejilla).
  static List<Offset>? f7SlotCentersOrNull(String? key) {
    if (key == null || key.isEmpty) return null;
    final list = f7NormalizedSlotCenters[key];
    if (list == null || list.length != 7) return null;
    return list;
  }

  /// F11 táctico (líneas); si no hay clave o no coincide el número de huecos → null.
  static List<Offset>? f11SlotCentersOrNull(String? key) {
    if (key == null || key.isEmpty) return null;
    final list = f11NormalizedSlotCenters[key];
    if (list == null || list.length != 11) return null;
    return list;
  }

  /// Posiciones fijas para F7 (7 huecos) o F11 (11 huecos) según [formationKey].
  static List<Offset>? tacticalSlotCentersOrNull(
    String? formationKey,
    int totalSlots,
  ) {
    if (formationKey == null || formationKey.isEmpty) return null;
    if (totalSlots == 7) {
      return f7SlotCentersOrNull(formationKey);
    }
    if (totalSlots == 11) {
      return f11SlotCentersOrNull(formationKey);
    }
    return null;
  }
}
