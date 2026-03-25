import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tfg1/presentation/home/pages/home_page.dart';
import '../bloc/auth_cubit.dart';
import '../bloc/auth_state.dart';
import '../widgets/login_form.dart';
import '../widgets/register_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isRegisterMode = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo tipo césped de campo de fútbol
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF388E3C), // Verde césped oscuro
              Color(0xFF66BB6A), // Verde césped medio
              Color(0xFFB9F6CA), // Verde césped claro
            ],
          ),
        ),
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
                    // Nombre de la app arriba
                    Text(
                      "Equipaso",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Mensaje de bienvenida según modo
                    Text(
                      _isRegisterMode ? "Nice tu meet you!" : "Welcome back!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Tarjeta con el formulario de login/registro
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
                    // Texto debajo del formulario para cambiar de modo
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isRegisterMode = !_isRegisterMode;
                        });
                      },
                      child: Text(
                        _isRegisterMode
                            ? "¿Ya tienes cuenta? Inicia sesión"
                            : "¿No tienes cuenta todavia? Creala aqui",
                        style: const TextStyle(
                          color: Color(0xFFFFF176), // Amarillo suave llamativo
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
