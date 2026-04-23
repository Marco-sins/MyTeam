import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:football_manager/core/notifications/match_realtime_local_notifications.dart';
import 'package:football_manager/firebase_options.dart';

/// Handler de FCM en isolate de fondo (requerido en Android).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) {
    return;
  }
  if (!isFirebaseOptionsConfigured) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint('FCM background: ${message.messageId} ${message.notification?.title}');
  }

  // Con payload `notification`, Android ya saca la bandeja. Solo `data` → no hay UI: notificación local.
  if (defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  if (message.notification != null) {
    return;
  }
  if (message.data.isEmpty) {
    return;
  }
  var title = (message.data['title'] as String?)?.trim();
  var body = (message.data['body'] as String?)?.trim();
  title ??= (message.data['gcm_title'] as String?)?.trim();
  body ??= (message.data['gcm_body'] as String?)?.trim();
  if (title == null && body == null) {
    return;
  }

  await MatchRealtimeLocalNotifications.instance.ensureInitialized();
  if (!MatchRealtimeLocalNotifications.instance.isReady) {
    return;
  }
  final id = (message.messageId?.hashCode ?? message.hashCode).abs() % 0x7fffffff;
  await MatchRealtimeLocalNotifications.instance.show(
    id: id,
    title: (title != null && title.isNotEmpty) ? title : 'Aviso',
    body: body ?? '',
    forFcmPush: true,
  );
}
