import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:football_manager/domain/entities/team_scoring_config.dart';

const _kKeyPrefix = 'team_scoring_v1_';

class TeamScoringConfigStorage {
  TeamScoringConfigStorage(this._prefs);

  final SharedPreferences _prefs;

  TeamScoringConfig? load(int teamId) {
    final raw = _prefs.getString('$_kKeyPrefix$teamId');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) {
        return null;
      }
      return TeamScoringConfig.fromJsonMap(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(int teamId, TeamScoringConfig config) async {
    await _prefs.setString(
      '$_kKeyPrefix$teamId',
      json.encode(config.toJson()),
    );
  }
}
