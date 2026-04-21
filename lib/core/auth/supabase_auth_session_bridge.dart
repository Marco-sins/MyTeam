import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/presentation/auth/cubit/auth_cubit.dart';

/// Cuando el usuario abre un enlace de correo (confirmación, OAuth…),
/// [supabase_flutter] establece la sesión; aquí sincronizamos [AuthCubit]
/// para que la UI pase a [HomePage] sin reiniciar la app.
class SupabaseAuthSessionBridge extends StatefulWidget {
  const SupabaseAuthSessionBridge({super.key, required this.child});

  final Widget child;

  @override
  State<SupabaseAuthSessionBridge> createState() =>
      _SupabaseAuthSessionBridgeState();
}

class _SupabaseAuthSessionBridgeState extends State<SupabaseAuthSessionBridge> {
  StreamSubscription<AuthState>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted) return;
    final cubit = context.read<AuthCubit>();
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        unawaited(cubit.refreshAuthenticatedUser());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
