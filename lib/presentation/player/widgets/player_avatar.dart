import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:football_manager/domain/entities/player.dart';

/// Avatar del jugador en **formato retrato** (más alto que ancho, proporción 3:4).
/// La foto se escala con [BoxFit.contain] para que **se vea entera** (puede haber bandas del tema si la proporción no coincide).
/// [radius] es la mitad de la **altura** del marco.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.player,
    this.radius = 22,
    this.previewBytes,
  });

  final Player player;
  final double radius;

  /// Vista previa local (p. ej. imagen elegida aún no subida).
  final Uint8List? previewBytes;

  static const double _aspectWidthOverHeight = 3 / 4;

  String get _label {
    final n = player.number?.toString();
    if (n != null && n.isNotEmpty && n != '0') return n;
    final f = player.firstName.trim();
    if (f.isEmpty) return '?';
    return f[0].toUpperCase();
  }

  BorderRadius get _r {
    final h = radius * 2;
    final w = h * _aspectWidthOverHeight;
    return BorderRadius.circular((w + h) * 0.12);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = player.imgUrl?.trim();
    final h = radius * 2;
    final w = h * _aspectWidthOverHeight;

    if (previewBytes != null && previewBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: _r,
        child: ColoredBox(
          color: scheme.surfaceContainerHigh,
          child: SizedBox(
            width: w,
            height: h,
            child: Image.memory(
              previewBytes!,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: _r,
        child: ColoredBox(
          color: scheme.surfaceContainerHigh,
          child: SizedBox(
            width: w,
            height: h,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _fallback(scheme),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: radius * 0.7,
                    height: radius * 0.7,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return _fallback(scheme);
  }

  Widget _fallback(ColorScheme scheme) {
    final h = radius * 2;
    final w = h * _aspectWidthOverHeight;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: _r,
      child: SizedBox(
        width: w,
        height: h,
        child: Center(
          child: Text(
            _label,
            style: TextStyle(
              fontSize: radius * 0.85,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

/// Foto del jugador en **retrato** con esquinas redondeadas; [BoxFit.contain] para no recortar.
/// Misma lógica que [PlayerAvatar]: URL, bytes o iniciales.
class PlayerPhotoRect extends StatelessWidget {
  const PlayerPhotoRect({
    super.key,
    required this.player,
    this.width = 88,
    this.height = 118,
    this.borderRadius = 14,
    this.previewBytes,
  });

  final Player player;
  final double width;
  final double height;
  final double borderRadius;
  final Uint8List? previewBytes;

  String get _label {
    final n = player.number?.toString();
    if (n != null && n.isNotEmpty && n != '0') return n;
    final f = player.firstName.trim();
    if (f.isEmpty) return '?';
    return f[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = player.imgUrl?.trim();
    final r = BorderRadius.circular(borderRadius);

    Widget content;
    if (previewBytes != null && previewBytes!.isNotEmpty) {
      content = Image.memory(
        previewBytes!,
        fit: BoxFit.contain,
      );
    } else if (url != null && url.isNotEmpty) {
      content = Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallbackBox(scheme, r),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: width * 0.28,
              height: width * 0.28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
          );
        },
      );
    } else {
      return _fallbackBox(scheme, r);
    }

    return ClipRRect(
      borderRadius: r,
      child: ColoredBox(
        color: scheme.surfaceContainerHigh,
        child: SizedBox(
          width: width,
          height: height,
          child: content,
        ),
      ),
    );
  }

  Widget _fallbackBox(ColorScheme scheme, BorderRadius r) {
    return Material(
      color: scheme.primaryContainer,
      borderRadius: r,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            _label,
            style: TextStyle(
              fontSize: height * 0.38,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
