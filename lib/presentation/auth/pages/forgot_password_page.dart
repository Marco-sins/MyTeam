import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:football_manager/presentation/auth/widgets/auth_background.dart';
import 'package:football_manager/presentation/auth/widgets/auth_header.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  bool _hasValidSupabaseConfig() {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('your-project-id') &&
        !supabaseAnonKey.contains('your-anon-key-here');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasValidSupabaseConfig()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configura .env con SUPABASE_URL y SUPABASE_ANON_KEY reales para poder recuperar contrasena.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'com.example.tfg1://reset-password',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Te hemos enviado un correo para restablecer tu contraseña.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      Navigator.of(context).pop();
    } on SocketException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede conectar con Supabase. Configura SUPABASE_URL y SUPABASE_ANON_KEY reales en .env (no uses your-project-id).',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar el correo de recuperación.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthHeader(isRegisterMode: false),
                  const SizedBox(height: 24),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'Recuperar contraseña',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) {
                                return 'Introduce tu email';
                              }
                              if (!email.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendResetEmail,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Enviar correo de recuperación'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Volver al login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
