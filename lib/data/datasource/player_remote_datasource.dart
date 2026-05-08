/// Datasource remoto para operaciones sobre `players`, `player_stats` y
/// datos relacionados. Implementa las llamadas HTTP/SQL vía Supabase/PostgREST
/// y encapsula detalles de manejo de errores y compatibilidad de esquema.
library;

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/core/errors/exception/server_exception.dart';
import 'package:football_manager/core/errors/exception/unknow_exception.dart';
import 'package:football_manager/data/models/player_model.dart';
import 'package:football_manager/data/models/player_participation_totals.dart';
import 'package:football_manager/data/models/player_stats_model.dart';
import 'package:football_manager/domain/entities/enum/player_position.dart';

String _matchEventTypeTail(dynamic raw) {
  if (raw == null) return '';
  final s = raw.toString();
  final parts = s.split('.');
  return parts.isNotEmpty ? parts.last : s;
}

/// Mensajes tipo: Could not find the 'minutes_played' column of 'player_stats'...
final _unknownColumnInPayload = RegExp(
  r"the '([^']+)' column",
  caseSensitive: false,
);

Map<String, dynamic>? _removeColumnFromPayloadIfSchemaError(
  PostgrestException e,
  Map<String, dynamic> payload,
) {
  final match = _unknownColumnInPayload.firstMatch(e.message);
  if (match == null) return null;
  final col = match.group(1);
  if (col == null || !payload.containsKey(col)) return null;
  return Map<String, dynamic>.from(payload)..remove(col);
}

Future<void> _updatePlayerStatsWithSchemaFallback(
  SupabaseClient supabase,
  int playerId,
  Map<String, dynamic> payload,
) async {
  var data = Map<String, dynamic>.from(payload)..remove('id');
  const maxAttempts = 16;
  for (var i = 0; i < maxAttempts; i++) {
    if (data.isEmpty) {
      throw ServerException(
        message:
            'No se pudo actualizar player_stats: el esquema no coincide. '
            'Ejecuta en Supabase SQL: database/add_player_stats_minutes_times_started.sql',
        code: '500',
      );
    }
    try {
      await supabase
          .from('player_stats')
          .update(data)
          .eq('player_id', playerId);
      return;
    } on PostgrestException catch (e) {
      final next = _removeColumnFromPayloadIfSchemaError(e, data);
      if (next == null) {
        throw ServerException(message: e.message, code: e.code);
      }
      data = next;
    }
  }
  throw ServerException(
    message: 'player_stats: demasiados reintentos por columnas desconocidas',
    code: '500',
  );
}

Future<void> _insertPlayerStatsWithSchemaFallback(
  SupabaseClient supabase,
  Map<String, dynamic> payload,
) async {
  var data = Map<String, dynamic>.from(payload)..remove('id');
  const maxAttempts = 16;
  for (var i = 0; i < maxAttempts; i++) {
    if (data.isEmpty) {
      throw ServerException(
        message:
            'No se pudo crear player_stats: el esquema no coincide. '
            'Ejecuta en Supabase SQL: database/add_player_stats_minutes_times_started.sql',
        code: '500',
      );
    }
    try {
      final statsResponse = await supabase
          .from('player_stats')
          .insert(data)
          .select();
      if (statsResponse.isEmpty) {
        throw ServerException(
          message: 'Failed to create player stats',
          code: '500',
        );
      }
      return;
    } on PostgrestException catch (e) {
      final next = _removeColumnFromPayloadIfSchemaError(e, data);
      if (next == null) {
        throw ServerException(message: e.message, code: e.code);
      }
      data = next;
    }
  }
  throw ServerException(
    message: 'player_stats insert: demasiados reintentos',
    code: '500',
  );
}

class PlayerRemoteDatasource {
  final SupabaseClient _supabase;

  PlayerRemoteDatasource(this._supabase);

  static const String _photoBucket = 'player-photos';

  String? _extractPathFromPlayerPhotoUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final i = segments.indexOf(_photoBucket);
      if (i == -1 || i == segments.length - 1) return null;
      return segments.sublist(i + 1).join('/');
    } catch (_) {
      return null;
    }
  }

  Future<void> removePlayerPhotoIfInBucket(String? publicUrl) async {
    if (publicUrl == null || publicUrl.trim().isEmpty) return;
    final path = _extractPathFromPlayerPhotoUrl(publicUrl);
    if (path == null) return;
    try {
      await _supabase.storage.from(_photoBucket).remove([path]);
    } catch (_) {
      // No bloquear el flujo si el objeto ya no existe.
    }
  }

  Future<String> uploadPlayerPhoto({
    required Uint8List bytes,
    required String fileName,
    required int teamId,
    int? playerId,
  }) async {
    try {
      final sanitized = fileName.replaceAll(' ', '_');
      final segment = playerId != null ? 'p$playerId' : 'new';
      final path =
          '$teamId/${segment}_${DateTime.now().millisecondsSinceEpoch}_$sanitized';

      await _supabase.storage
          .from(_photoBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );

      return _supabase.storage.from(_photoBucket).getPublicUrl(path);
    } on StorageException catch (e) {
      throw ServerException(message: e.message, code: e.statusCode.toString());
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<PlayerModel> createPlayer(
    PlayerModel playerData,
    PlayerStatsModel playerStatsData,
  ) async {
    try {
      final response = await _supabase
          .from('players')
          .insert(playerData.toJson())
          .select();
      if (response.isEmpty) {
        throw ServerException(message: 'Failed to create player', code: '500');
      }
      final first = (response as List).first;
      final map = first is Map<String, dynamic>
          ? first
          : Map<String, dynamic>.from(first as Map);
      final int playerId = supabaseInt(map['id']) ?? 0;
      await _insertPlayerStatsWithSchemaFallback(
        _supabase,
        playerStatsData.copyWith(playerId: playerId).toJson(),
      );
      return PlayerModel.fromJson(map);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> deletePlayer(int id) async {
    try {
      // Borramos primero el jugador; si no existe, Supabase lanzará
      // PostgrestException y la propagaremos como ServerException.
      await _supabase.from('players').delete().eq('id', id);

      // Borramos sus estadísticas si existen, pero no consideramos error
      // el hecho de que no haya fila en player_stats (puede ser opcional).
      await _supabase.from('player_stats').delete().eq('player_id', id);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<PlayerModel> getPlayerById(int id) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('id', id)
          .single();
      final playerModel = PlayerModel.fromJson(result);
      final statsResult = await _supabase
          .from('player_stats')
          .select()
          .eq('player_id', id)
          .single();
      final playerStatsModel = PlayerStatsModel.fromJson(statsResult);
      return playerModel.copyWith(stats: playerStatsModel);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayerByMatchId(int matchId) async {
    try {
      final result = await _supabase
          .from('match_lineup')
          .select('player:players(*)')
          .eq('match_id', matchId);
      final List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e['player']))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayerByName(String name) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .ilike('firstname', '%$name%');
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayers() async {
    try {
      final result = await _supabase.from('players').select();
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayersByNumber(int teamId, int number) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId)
          .eq('number', number);
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<List<PlayerModel>> getPlayersByPosition(
    int teamId,
    PlayerPosition position,
  ) async {
    try {
      final result = await _supabase
          .from('players')
          .select()
          .eq('team_id', teamId)
          .ilike('positions', '%${position.name}%');
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(e))
          .toList();
      return players;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<Map<int, PlayerParticipationTotals>> computeParticipationTotalsForTeam(
    int teamId,
  ) async {
    try {
      final finished = await _supabase
          .from('matches')
          .select('id')
          .eq('team_id', teamId)
          .eq('status', 'finished');

      final List<int> matchIds = (finished as List<dynamic>)
          .map((e) => (e as Map)['id'] as int)
          .toList();

      if (matchIds.isEmpty) {
        return {};
      }

      final playedSets = <int, Set<int>>{};
      final startedSets = <int, Set<int>>{};
      final minutesSum = <int, int>{};

      void markPlayed(int playerId, int matchId) {
        playedSets.putIfAbsent(playerId, () => {}).add(matchId);
      }

      void markStarted(int playerId, int matchId) {
        startedSets.putIfAbsent(playerId, () => {}).add(matchId);
      }

      void addMinutes(int playerId, int mins) {
        minutesSum[playerId] = (minutesSum[playerId] ?? 0) + mins;
      }

      final lineups = await _supabase
          .from('match_lineup')
          .select('player_id, match_id, minutes_played, is_start')
          .inFilter('match_id', matchIds);

      for (final row in lineups as List<dynamic>) {
        final map = Map<String, dynamic>.from(row as Map);
        final pid = map['player_id'] as int;
        final mid = map['match_id'] as int;
        final mins = (map['minutes_played'] as num?)?.toInt() ?? 0;
        final isStart = (map['is_start'] as bool?) ?? false;

        addMinutes(pid, mins);
        if (mins > 0 || isStart) {
          markPlayed(pid, mid);
        }
        if (isStart) {
          markStarted(pid, mid);
        }
      }

      final events = await _supabase
          .from('match_events')
          .select('match_id, type, player_id1, player_id2')
          .inFilter('match_id', matchIds);

      for (final row in events as List<dynamic>) {
        final map = Map<String, dynamic>.from(row as Map);
        final mid = map['match_id'] as int;
        if (_matchEventTypeTail(map['type']) == 'statusChange') {
          continue;
        }
        final p1 = map['player_id1'] as int?;
        final p2 = map['player_id2'] as int?;
        if (p1 != null) {
          markPlayed(p1, mid);
        }
        if (p2 != null) {
          markPlayed(p2, mid);
        }
      }

      final allIds = <int>{
        ...playedSets.keys,
        ...startedSets.keys,
        ...minutesSum.keys,
      };

      final result = <int, PlayerParticipationTotals>{};
      for (final id in allIds) {
        result[id] = PlayerParticipationTotals(
          matchesPlayed: playedSets[id]?.length ?? 0,
          timesStarted: startedSets[id]?.length ?? 0,
          minutesPlayedSum: minutesSum[id] ?? 0,
        );
      }
      return result;
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> syncParticipationStatsForTeam(int teamId) async {
    try {
      final totals = await computeParticipationTotalsForTeam(teamId);
      final playersRes = await _supabase
          .from('players')
          .select('id')
          .eq('team_id', teamId);

      await Future.wait(
        (playersRes as List<dynamic>).map((row) async {
          final id = (row as Map)['id'] as int;
          final t = totals[id] ?? PlayerParticipationTotals.zero;
          await _updatePlayerStatsWithSchemaFallback(_supabase, id, {
            'matches_played': t.matchesPlayed,
            'times_started': t.timesStarted,
            'minutes_played': t.minutesPlayedSum,
          });
        }),
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  /// Goles, asistencias y tarjetas solo de partidos finalizados (misma regla
  /// que al cerrar un partido), útil tras borrar un partido o para corregir drift.
  Future<void> recomputeScoringAndDisciplineForTeam(int teamId) async {
    try {
      final finished = await _supabase
          .from('matches')
          .select('id')
          .eq('team_id', teamId)
          .eq('status', 'finished');

      final List<int> matchIds = (finished as List<dynamic>)
          .map((e) => (e as Map)['id'] as int)
          .toList();

      final goals = <int, int>{};
      final assists = <int, int>{};
      final yellows = <int, int>{};
      final reds = <int, int>{};

      if (matchIds.isNotEmpty) {
        final events = await _supabase
            .from('match_events')
            .select('type, player_id1, player_id2')
            .inFilter('match_id', matchIds);

        for (final row in events as List<dynamic>) {
          final map = Map<String, dynamic>.from(row as Map);
          final tail = _matchEventTypeTail(map['type']);
          final p1 = map['player_id1'] as int?;
          final p2 = map['player_id2'] as int?;

          if (tail == 'scoreGoal') {
            if (p1 != null) {
              goals[p1] = (goals[p1] ?? 0) + 1;
            }
            if (p2 != null) {
              assists[p2] = (assists[p2] ?? 0) + 1;
            }
          } else if (tail == 'yellowCard') {
            if (p1 != null) {
              yellows[p1] = (yellows[p1] ?? 0) + 1;
            }
          } else if (tail == 'redCard') {
            if (p1 != null) {
              reds[p1] = (reds[p1] ?? 0) + 1;
            }
          }
        }
      }

      final playersRes = await _supabase
          .from('players')
          .select('id')
          .eq('team_id', teamId);

      await Future.wait(
        (playersRes as List<dynamic>).map((row) async {
          final id = (row as Map)['id'] as int;
          await _supabase
              .from('player_stats')
              .update({
                'goals': goals[id] ?? 0,
                'assistences': assists[id] ?? 0,
                'yellow_cards': yellows[id] ?? 0,
                'red_cards': reds[id] ?? 0,
              })
              .eq('player_id', id);
        }),
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> recalculateAllAggregatedStatsForTeam(int teamId) async {
    await syncParticipationStatsForTeam(teamId);
    await recomputeScoringAndDisciplineForTeam(teamId);
  }

  Future<List<PlayerModel>> getPlayersByTeam(int teamId) async {
    try {
      final result = await _supabase
          .from('players')
          .select('*, player_stats(*)')
          .eq('team_id', teamId);
      List<PlayerModel> players = result
          .map((e) => PlayerModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      final totals = await computeParticipationTotalsForTeam(teamId);
      return players.map((p) {
        final t = totals[p.id] ?? PlayerParticipationTotals.zero;
        final st = p.stats;
        if (st == null) {
          return p.copyWith(
            stats: PlayerStatsModel(
              matchesPlayed: t.matchesPlayed,
              timesStarted: t.timesStarted,
              minutesPlayed: t.minutesPlayedSum,
            ),
          );
        }
        final model = st is PlayerStatsModel
            ? st
            : PlayerStatsModel(
                id: st.id,
                playerId: st.playerId,
                goals: st.goals,
                assists: st.assists,
                yellowCards: st.yellowCards,
                redCards: st.redCards,
                matchesPlayed: st.matchesPlayed,
                minutesPlayed: st.minutesPlayed,
                timesStarted: st.timesStarted,
              );
        return p.copyWith(
          stats: model.copyWith(
            matchesPlayed: t.matchesPlayed,
            timesStarted: t.timesStarted,
            minutesPlayed: t.minutesPlayedSum,
          ),
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updatePlayer(PlayerModel player) async {
    try {
      await _supabase
          .from('players')
          .update(player.toJson())
          .eq('id', player.id);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }

  Future<void> updatePlayerStats(
    int playerId,
    PlayerStatsModel playerStats,
  ) async {
    try {
      await _updatePlayerStatsWithSchemaFallback(
        _supabase,
        playerId,
        playerStats.toJson(),
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message, code: e.code);
    } catch (e) {
      throw UnknowException('Unexpected error: $e');
    }
  }
}
