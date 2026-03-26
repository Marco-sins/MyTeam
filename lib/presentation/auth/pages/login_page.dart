import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/presentation/auth/widgets/aut_mode_selector.dart';
import 'package:tfg1/presentation/home/pages/home_page.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isRegisterMode = false;

  void _toggleMode() => setState(() => _isRegisterMode = !_isRegisterMode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
            if (state is Authenticated) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          },
          builder: (context, state) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AuthHeader(isRegisterMode: _isRegisterMode),
                    const SizedBox(height: 24),

                    // Contenedor del Formulario
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
                      child: _isRegisterMode
                          ? const RegisterForm()
                          : const LoginForm(),
                    ),

                    const SizedBox(height: 16),
                    AuthModeSelector(
                      isRegisterMode: _isRegisterMode,
                      onTap: _toggleMode,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
