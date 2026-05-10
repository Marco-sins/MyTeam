import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:football_manager/core/notifications/match_realtime_local_notifications.dart';
import 'package:football_manager/core/push/firebase_messaging_background.dart';
import 'package:football_manager/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM = solo transporte al sistema. Los tokens suelen guardarse en Supabase (`fcm_tokens`)
/// y el envío puede hacerse desde un backend/Edge Function que llame a la API de FCM.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  bool _tokenRefreshListenerAttached = false;
  String? _lastSyncedToken;

  /// Llama al iniciar app (main) y tras login exitoso.
  Future<void> initializePluginBinding() async {
    if (kIsWeb) return;
    final targetPlatform = defaultTargetPlatform;
    final isSupportedPlatform =
        targetPlatform == TargetPlatform.android ||
        targetPlatform == TargetPlatform.iOS ||
        targetPlatform == TargetPlatform.macOS;
    if (!isSupportedPlatform) {
      debugPrint(
        'Push: FCM no está disponible en ${targetPlatform.name}; esta plataforma seguirá sin notificaciones push.',
      );
      return;
    }
    if (!isFirebaseOptionsConfigured) {
      debugPrint(
        'Push: Firebase no está configurado para ${targetPlatform.name}; ejecuta flutterfire configure y reemplaza lib/firebase_options.dart',
      );
      return;
    }
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Push: Firebase.initializeApp falló: $e');
      return;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (Platform.isIOS || Platform.isMacOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      await FirebaseMessaging.instance.requestPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    if (!_tokenRefreshListenerAttached) {
      _tokenRefreshListenerAttached = true;
      FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) async {
        if (newToken == _lastSyncedToken) return;
        _lastSyncedToken = null;
        if (Supabase.instance.client.auth.currentUser != null) {
          await registerTokenForCurrentUser();
        }
      });
    }

    _initialized = true;
  }

  /// En primer plano, Android e iOS no muestran solos el aviso de FCM: lo reflejamos con notificación local.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      debugPrint('FCM foreground: ${message.notification?.title}');
    }
    if (!MatchRealtimeLocalNotifications.instance.isReady) {
      await MatchRealtimeLocalNotifications.instance.ensureInitialized();
    }
    if (!MatchRealtimeLocalNotifications.instance.isReady) {
      return;
    }

    final n = message.notification;
    if (n != null) {
      final hasTitle = n.title != null && n.title!.trim().isNotEmpty;
      final hasBody = n.body != null && n.body!.trim().isNotEmpty;
      if (hasTitle || hasBody) {
        // iOS: el banner en primer plano lo pinta FCM (setForegroundNotificationPresentationOptions).
        if (Platform.isIOS) {
          return;
        }
        final id =
            (message.messageId?.hashCode ?? message.hashCode).abs() %
            0x7fffffff;
        await MatchRealtimeLocalNotifications.instance.show(
          id: id,
          title: hasTitle ? n.title!.trim() : 'Aviso',
          body: hasBody ? n.body!.trim() : '',
          forFcmPush: true,
        );
        return;
      }
    }

    final data = message.data;
    if (data.isEmpty) {
      return;
    }
    var title = (data['title'] as String?)?.trim();
    var body = (data['body'] as String?)?.trim();
    title ??= (data['gcm_title'] as String?)?.trim();
    body ??= (data['gcm_body'] as String?)?.trim();
    if (title == null && body == null) {
      return;
    }
    final id =
        (message.messageId?.hashCode ?? message.hashCode).abs() % 0x7fffffff;
    await MatchRealtimeLocalNotifications.instance.show(
      id: id,
      title: (title != null && title.isNotEmpty) ? title : 'Aviso',
      body: body ?? '',
      forFcmPush: true,
    );
  }

  /// Guarda/actualiza el token del usuario autenticado (tabla [fcm_tokens]).
  Future<void> registerTokenForCurrentUser() async {
    if (kIsWeb) return;
    if (!isFirebaseOptionsConfigured) return;
    if (!_initialized) {
      await initializePluginBinding();
    }
    if (!_initialized) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    if (token == _lastSyncedToken) return;

    String platform;
    if (Platform.isAndroid) {
      platform = 'android';
    } else if (Platform.isIOS) {
      platform = 'ios';
    } else {
      platform = 'other';
    }

    try {
      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,token');
      _lastSyncedToken = token;
    } catch (e) {
      debugPrint(
        'Push: no se pudo guardar fcm token (¿migración aplicada en Supabase?): $e',
      );
    }
  }

  Future<void> deleteTokenForCurrentUser() async {
    if (kIsWeb) return;
    if (!isFirebaseOptionsConfigured) return;
    if (!_initialized) {
      await initializePluginBinding();
    }
    if (!_initialized) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Push: getToken al borrar: $e');
    }
    if (token != null) {
      try {
        await Supabase.instance.client
            .from('fcm_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('token', token);
      } catch (e) {
        debugPrint('Push: error borrando token en Supabase: $e');
      }
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('Push: error deleteToken FCM: $e');
    }
    _lastSyncedToken = null;
  }
}
