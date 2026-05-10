// Generado a partir de `android/app/google-services.json` (Android).
// Android ya está enlazado para FCM; iOS/macOS/web siguen requiriendo `flutterfire configure`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Marca opciones no enlazadas para plataformas que aún no están configuradas.
const String kFirebaseProjectPlaceholder = 'YOUR_FIREBASE_PROJECT_ID';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIza-SeeFirebaseConsole',
    appId: '1:0:web:0',
    messagingSenderId: '0',
    projectId: kFirebaseProjectPlaceholder,
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
  );

  // Valores reales: Consola → Configuración del proyecto, o `google-services.json`
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBPZ4foo7CHL_IDbFDTIAJxPTexI_J85og',
    appId: '1:757366524117:android:bb51262a4b74da40a33a5c',
    messagingSenderId: '757366524117',
    projectId: 'myteam-1f0c8',
    storageBucket: 'myteam-1f0c8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIza-SeeFirebaseConsole',
    appId: '1:0:ios:0',
    messagingSenderId: '0',
    projectId: kFirebaseProjectPlaceholder,
    storageBucket: 'YOUR_FIREBASE_PROJECT_ID.appspot.com',
    iosBundleId: 'com.marco.myteam',
  );

  static const FirebaseOptions macos = ios;
}

/// FCM solo se considera listo en plataformas con opciones reales (ahora: Android).
bool get isFirebaseOptionsConfigured {
  if (kIsWeb) {
    return false;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return DefaultFirebaseOptions.android.projectId !=
              kFirebaseProjectPlaceholder &&
          DefaultFirebaseOptions.android.projectId.isNotEmpty;
    case TargetPlatform.iOS:
      return DefaultFirebaseOptions.ios.projectId !=
              kFirebaseProjectPlaceholder &&
          DefaultFirebaseOptions.ios.appId != '1:0:ios:0' &&
          DefaultFirebaseOptions.ios.appId.isNotEmpty;
    default:
      return false;
  }
}
