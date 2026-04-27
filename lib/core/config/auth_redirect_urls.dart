import 'package:flutter_dotenv/flutter_dotenv.dart';

/// URLs de retorno para Supabase Auth (correo de confirmación, recuperación, etc.).
/// Deben coincidir con **Authentication → URL Configuration → Redirect URLs**
/// en el panel de Supabase y con el `intent-filter` / `CFBundleURLSchemes` de la app.
///
/// Formato: `{scheme}://{host}` — el [scheme] debe ser el mismo en Android e iOS.
class AuthRedirectUrls {
  AuthRedirectUrls._();

  static String get _scheme =>
      dotenv.env['AUTH_DEEP_LINK_SCHEME'] ?? 'com.marco.myteam';

  /// Tras confirmar el correo; `supabase_flutter` intercambia el `code` del enlace por sesión.
  static String get emailConfirmation =>
      dotenv.env['AUTH_REDIRECT_LOGIN'] ?? '$_scheme://login';

  /// Recuperación de contraseña (misma base que [forgot_password_page]).
  static String get passwordReset =>
      dotenv.env['AUTH_REDIRECT_RESET_PASSWORD'] ?? '$_scheme://reset-password';
}
