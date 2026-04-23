import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:football_manager/app/football_app.dart';
import 'package:football_manager/core/di/injection_container.dart';
import 'package:football_manager/core/notifications/match_realtime_local_notifications.dart';
import 'package:football_manager/core/push/push_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  final hasValidSupabaseConfig =
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('your-project-id') &&
      !supabaseAnonKey.contains('your-anon-key-here');

  if (!hasValidSupabaseConfig) {
    runApp(const SupabaseConfigErrorApp());
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await configureDependencies();

  await MatchRealtimeLocalNotifications.instance.ensureInitialized();
  await PushNotificationService.instance.initializePluginBinding();

  final prefs = await SharedPreferences.getInstance();
  runApp(FootballApp(sharedPreferences: prefs));
}
