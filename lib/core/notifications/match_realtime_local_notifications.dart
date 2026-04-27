import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:football_manager/core/utils/supabase_dynamic.dart';
import 'package:football_manager/domain/entities/match_event_realtime_snapshot.dart';
import 'package:football_manager/domain/services/match_live_timeline_filter.dart';
import 'package:football_manager/l10n/app_localizations.dart';

/// v3: antes usábamos `AudioAttributesUsage.notificationRingtone` (volumen del
/// *tono de llamada*); al estar a 0 no se oía. `notification` = volumen de notificaciones.
const String _androidChannelId = 'match_live_app_v3';
const String _androidChannelName = 'Partido en vivo';

/// Debe coincidir con `com.google.firebase.messaging.default_notification_channel_id` (AndroidManifest).
const String kAndroidFcmDefaultNotificationChannelId = 'fcm_default_channel';
const String _fcmDefaultChannelName = 'Avisos de la app';

/// Inicializa el plugin (desde [main]).
class MatchRealtimeLocalNotifications {
  MatchRealtimeLocalNotifications._();

  static final MatchRealtimeLocalNotifications instance =
      MatchRealtimeLocalNotifications._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> ensureInitialized() async {
    if (kIsWeb) {
      return;
    }
    if (_ready) {
      return;
    }

    final initSettings = InitializationSettings(
      android: defaultTargetPlatform == TargetPlatform.android
          ? const AndroidInitializationSettings('@mipmap/ic_launcher')
          : null,
      iOS: (defaultTargetPlatform == TargetPlatform.iOS)
          ? const DarwinInitializationSettings()
          : null,
      macOS: (defaultTargetPlatform == TargetPlatform.macOS)
          ? const DarwinInitializationSettings()
          : null,
      linux: (defaultTargetPlatform == TargetPlatform.linux)
          ? const LinuxInitializationSettings(defaultActionName: 'Open')
          : null,
      windows: (defaultTargetPlatform == TargetPlatform.windows)
          ? const WindowsInitializationSettings(
              appName: 'MyTeam',
              appUserModelId: 'com.myteam.football_manager',
              guid: 'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
            )
          : null,
    );

    await _plugin.initialize(
      settings: initSettings,
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      const channel = AndroidNotificationChannel(
        _androidChannelId,
        _androidChannelName,
        description: 'Goles, periodos, tarjetas y fin de partido',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        // USAGE_NOTIFICATION (5) — el usuario suele subir "Notificaciones" en
        // ajustes; el tono de llamada (ringtone) puede estar en 0.
        audioAttributesUsage: AudioAttributesUsage.notification,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const fcmChannel = AndroidNotificationChannel(
        kAndroidFcmDefaultNotificationChannelId,
        _fcmDefaultChannelName,
        description: 'Mensajes push (FCM) en segundo plano o sin UI',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        audioAttributesUsage: AudioAttributesUsage.notification,
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(fcmChannel);

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _ready = true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    /// Usa el canal de FCM (no mezclar con eventos de partido en ajustes del sistema).
    bool forFcmPush = false,
  }) async {
    if (kIsWeb || !_ready) {
      return;
    }

    final android = AndroidNotificationDetails(
      forFcmPush ? kAndroidFcmDefaultNotificationChannelId : _androidChannelId,
      forFcmPush ? _fcmDefaultChannelName : _androidChannelName,
      channelDescription: forFcmPush
          ? 'Mensajes push (FCM) en primer plano'
          : 'Goles, periodos, tarjetas y fin de partido',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      category: forFcmPush
          ? AndroidNotificationCategory.status
          : AndroidNotificationCategory.event,
      audioAttributesUsage: AudioAttributesUsage.notification,
    );
    // `sound: ''` fuerza el sonido por defecto del sistema en 1er plano/segundo
    // plano (doc flutter_local_notifications). `active` = puede sonar en iOS 15+.
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      sound: '',
      interruptionLevel: InterruptionLevel.active,
    );
    const linux = LinuxNotificationDetails();
    const win = WindowsNotificationDetails();

    final details = NotificationDetails(
      android: android,
      iOS: ios,
      macOS: ios,
      linux: linux,
      windows: win,
    );

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('Local notification failed: $e');
    }
  }
}

bool _isFinishedMatchNote(String? note) {
  final n = note?.toLowerCase().trim() ?? '';
  return n == 'final del partido' || (n.contains('final') && n.contains('partido'));
}

/// [playerNameFor] debe devolver el nombre mostrable; si no hay convocatoria,
/// puede devolver [AppLocalizations.matchNotifPlayerUnknown].
void handleMatchEventRealtimeForLocalNotification(
  MatchEventRealtimeSnapshot snap, {
  required AppLocalizations l10n,
  required String ourTeamName,
  required String opponentName,
  required String Function(int? playerId) playerNameFor,
}) {
  if (kIsWeb) {
    return;
  }
  if (!snap.isInsert) {
    return;
  }
  if (!MatchRealtimeLocalNotifications.instance.isReady) {
    return;
  }

  final map = Map<String, dynamic>.from(snap.row);
  final typeKey = canonicalMatchEventTypeKey(map['type']);
  final p1 = supabaseInt(map['player_id1']);

  String? body;

  if (typeKey == 'statuschange') {
    final note = (map['note'] as String?)?.trim() ?? '';
    if (MatchLiveTimelineFilter.isFirstHalfKickoffStatusNote(note)) {
      body = l10n.matchNotifTimeFirst;
    } else if (note.toLowerCase() == 'descanso') {
      body = l10n.matchNotifTimeHalf;
    } else if (MatchLiveTimelineFilter.noteIndicatesSecondHalfKickoff(note)) {
      body = l10n.matchNotifTimeSecond;
    } else if (_isFinishedMatchNote(note)) {
      body = l10n.matchNotifTimeEnd;
    }
  } else if (typeKey == 'scoregoal') {
    body = l10n.matchNotifGoalByPlayer(
      playerNameFor(p1),
      ourTeamName,
    );
  } else if (typeKey == 'penalty') {
    body = l10n.matchNotifGoalByPlayer(
      playerNameFor(p1),
      ourTeamName,
    );
  } else if (typeKey == 'concedegoal') {
    body = l10n.matchNotifGoalRivalOnly(opponentName);
  } else if (typeKey == 'owngoal') {
    body = l10n.matchNotifOwnGoalByPlayer(
      playerNameFor(p1),
      ourTeamName,
    );
  } else if (typeKey == 'yellowcard') {
    body = l10n.matchNotifCardYellowForTeam(
      playerNameFor(p1),
      ourTeamName,
    );
  } else if (typeKey == 'redcard') {
    body = l10n.matchNotifCardRedForTeam(
      playerNameFor(p1),
      ourTeamName,
    );
  } else if (typeKey == 'rivalyellowcard') {
    body = p1 != null
        ? l10n.matchNotifCardYellowRivalWithPlayer(
            playerNameFor(p1),
            opponentName,
          )
        : l10n.matchNotifCardYellowRivalOnly(opponentName);
  } else if (typeKey == 'rivalredcard') {
    body = p1 != null
        ? l10n.matchNotifCardRedRivalWithPlayer(
            playerNameFor(p1),
            opponentName,
          )
        : l10n.matchNotifCardRedRivalOnly(opponentName);
  }

  if (body == null) {
    return;
  }

  final dynamic rawId = map['id'];
  int nid = (map['created_at']?.toString().hashCode ?? 0) & 0x3fffffff;
  if (rawId is int) {
    nid = rawId;
  } else if (rawId is num) {
    nid = rawId.toInt();
  }

  unawaited(
    MatchRealtimeLocalNotifications.instance.show(
      id: nid,
      title: l10n.appTitle,
      body: body,
    ),
  );
}
