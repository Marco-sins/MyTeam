import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:football_manager/core/locale/locale_cubit.dart';
import 'package:football_manager/l10n/app_localizations.dart';

/// Variante visual del chip de idioma (misma interacción que en home).
enum AppLanguageSelectorVariant {
  /// Chip pensado para AppBar con color primario (usa [ColorScheme.onPrimary]).
  appBar,

  /// Chip para fondos claros (p. ej. pie de panel lateral).
  lightSurface,
}

/// Selector ES / EN: icono, código y menú con checks (mismo patrón que la home).
class AppLanguageSelector extends StatelessWidget {
  const AppLanguageSelector({
    super.key,
    this.variant = AppLanguageSelectorVariant.appBar,
    this.menuOpensOver = false,
  });

  final AppLanguageSelectorVariant variant;
  final bool menuOpensOver;

  static const _codes = ['es', 'en', 'fr', 'it'];

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final code = locale.languageCode;
    final safeCode = _codes.contains(code) ? code : 'es';

    final Color fg;
    final Color borderColor;
    final Color fillColor;
    switch (variant) {
      case AppLanguageSelectorVariant.appBar:
        fg = scheme.onPrimary;
        borderColor = scheme.onPrimary.withValues(alpha: 0.32);
        fillColor = scheme.onPrimary.withValues(alpha: 0.12);
        break;
      case AppLanguageSelectorVariant.lightSurface:
        fg = scheme.onSurface;
        borderColor = scheme.outlineVariant.withValues(alpha: 0.75);
        fillColor = scheme.surfaceContainerHighest.withValues(alpha: 0.65);
        break;
    }

    final chip = Padding(
      padding: variant == AppLanguageSelectorVariant.appBar
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 10)
          : EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1),
          color: fillColor,
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 20, color: fg),
            const SizedBox(width: 8),
            Text(
              safeCode.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    fontSize: 13,
                  ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: fg.withValues(alpha: 0.92),
            ),
          ],
        ),
      ),
    );

    return PopupMenuButton<String>(
      tooltip: l10n.languageSelectorTooltip,
      padding: EdgeInsets.zero,
      offset: Offset(0, menuOpensOver ? -8 : 10),
      position: menuOpensOver ? PopupMenuPosition.over : PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      color: scheme.surfaceContainerHigh,
      elevation: 3,
      surfaceTintColor: scheme.surfaceTint,
      initialValue: safeCode,
      onSelected: (value) {
        context.read<LocaleCubit>().setLocale(Locale(value));
      },
      itemBuilder: (ctx) {
        final menuL10n = AppLocalizations.of(ctx)!;
        final menuScheme = Theme.of(ctx).colorScheme;
        Widget leadingCheck(bool selected) {
          return SizedBox(
            width: 28,
            child: Center(
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: 22,
                      color: menuScheme.primary,
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }

        return [
          PopupMenuItem<String>(
            value: 'es',
            child: Row(
              children: [
                leadingCheck(safeCode == 'es'),
                Expanded(child: Text(menuL10n.languageSpanish)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'en',
            child: Row(
              children: [
                leadingCheck(safeCode == 'en'),
                Expanded(child: Text(menuL10n.languageEnglish)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'fr',
            child: Row(
              children: [
                leadingCheck(safeCode == 'fr'),
                Expanded(child: Text(menuL10n.languageFrench)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'it',
            child: Row(
              children: [
                leadingCheck(safeCode == 'it'),
                Expanded(child: Text(menuL10n.languageItalian)),
              ],
            ),
          ),
        ];
      },
      child: chip,
    );
  }
}
