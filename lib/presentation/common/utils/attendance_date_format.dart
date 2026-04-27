import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Letra estrecha del día (p. ej. L, M, X en español) según el locale.
String attendanceNarrowWeekdayLetter(BuildContext context, DateTime date) {
  final loc = MaterialLocalizations.of(context);
  return loc.narrowWeekdays[date.weekday % 7];
}

/// Fecha con día de la semana abreviado: "lun. 15/01/2024".
String attendanceFormatDateWithWeekday(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat('EEE d/M/yyyy', locale).format(date);
}

/// Fecha con día de la semana completo: "lunes 15/01/2024".
String attendanceFormatDateWithFullWeekday(
  BuildContext context,
  DateTime date,
) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat('EEEE d/M/yyyy', locale).format(date);
}
