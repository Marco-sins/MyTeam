import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma de la app (persistido). Por defecto español.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(_readInitial(_prefs));

  final SharedPreferences _prefs;
  static const _key = 'app_locale_code';

  static const _supported = {'es', 'en', 'fr', 'it'};

  static Locale _readInitial(SharedPreferences prefs) {
    final code = prefs.getString(_key);
    if (code != null && _supported.contains(code)) {
      return Locale(code);
    }
    return const Locale('es');
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (!_supported.contains(code)) return;
    emit(Locale(code));
    await _prefs.setString(_key, code);
  }
}
