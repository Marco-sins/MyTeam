/// Eventos de sesión relevantes para la capa de presentación (p. ej. flujo de
/// recuperación de contraseña), independientes del proveedor de identidad.
enum AuthSessionSideEffect {
  /// El usuario abrió el enlace de recuperación y hay sesión de solo cambio de contraseña.
  passwordRecoverySessionStarted,
}
