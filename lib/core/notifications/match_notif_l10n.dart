import 'package:flutter/widgets.dart';
import 'package:football_manager/core/navigation/app_navigator_key.dart';
import 'package:football_manager/l10n/app_localizations.dart';

/// Textos de notificación con app en primer o segundo plano. Si [Navigator] no
/// está montado, usa el idioma del sistema (misma lógica que al arrancar).
AppLocalizations matchNotificationLocalizations() {
  final ctx = appNavigatorKey.currentContext;
  if (ctx != null) {
    final l = AppLocalizations.of(ctx);
    if (l != null) return l;
  }
  final raw = WidgetsBinding.instance.platformDispatcher.locale;
  final code = raw.languageCode;
  final locale = <String>['en', 'es', 'fr', 'it'].contains(code)
      ? Locale(code)
      : const Locale('es');
  return lookupAppLocalizations(locale);
}
