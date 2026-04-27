import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class LocalImageSaver {
  /// Guarda una imagen [bytes] con el nombre [fileName] en el directorio local de la app.
  /// Devuelve la ruta local del archivo guardado.
  static Future<String> saveImageLocally(
    Uint8List bytes,
    String fileName,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
