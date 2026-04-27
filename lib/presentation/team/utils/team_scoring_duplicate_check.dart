import 'package:football_manager/domain/entities/team_scoring_config.dart';
import 'package:football_manager/l10n/app_localizations.dart';
import 'package:football_manager/presentation/team/utils/team_scoring_builtin_label.dart';

String _lineDisplayTitleForDuplicateCheck(
  TeamScoringLine line,
  AppLocalizations l10n,
) {
  if (line.isCustom) {
    return (line.name ?? '').trim();
  }
  return teamScoringBuiltinTitle(l10n, line.id).trim();
}

/// `true` si dos o más filas comparten el mismo título (sin distinguir mayúsculas),
/// p. ej. dos personalizados "Regate" o "Tiro" == "Tiro" de otro evento.
bool hasDuplicateScoringLineTitles(
  List<TeamScoringLine> lines,
  AppLocalizations l10n,
) {
  return firstDuplicateScoringLineTitleNormalized(
        lines,
        l10n,
      ) !=
      null;
}

/// Primer título (normalizado) repetido, o `null` si no hay duplicados.
String? firstDuplicateScoringLineTitleNormalized(
  List<TeamScoringLine> lines,
  AppLocalizations l10n,
) {
  final seen = <String, String>{};
  for (final line in lines) {
    final title = _lineDisplayTitleForDuplicateCheck(line, l10n);
    if (title.isEmpty) {
      continue;
    }
    final k = title.toLowerCase();
    if (seen.containsKey(k)) {
      return k;
    }
    seen[k] = title;
  }
  return null;
}
